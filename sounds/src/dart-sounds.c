/*
 *  dart-sounds
 *
 *
 *  Copyright (C) 2011 Christian Pointner <equinox@realraum.at>
 *                         
 *  This file is part of dart-sounds.
 *
 *  dart-sounds is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  dart-sounds is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with dart-sounds. If not, see <http://www.gnu.org/licenses/>.
 */

#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <gst/gst.h>
#include <glib.h>

struct bus_call_param
{
  GMainLoop *loop;
  gint* sval;
  GCond* cond;
  GMutex* mutex;
};

static gboolean bus_call(GstBus *bus, GstMessage *msg, gpointer data)
{
  struct bus_call_param* p = (struct bus_call_param *)data;

  switch(GST_MESSAGE_TYPE(msg)) 
  {
     case GST_MESSAGE_EOS:
      g_mutex_lock(p->mutex);
      *(p->sval) = 1;
      g_mutex_unlock(p->mutex);
      g_cond_signal(p->cond);
      break;

    case GST_MESSAGE_ERROR: {
      GError *error;
      gst_message_parse_error(msg, &error, NULL);
      g_printerr("Error: %s\n", error->message);
      if(error->domain == GST_RESOURCE_ERROR || error->domain == GST_STREAM_ERROR) {
        g_mutex_lock(p->mutex);
        *(p->sval) = 1;
        g_mutex_unlock(p->mutex);
        g_cond_signal(p->cond);
      } else g_main_loop_quit(p->loop);

      g_error_free(error);
      break;
    }
    default:
      break;
  }

  return TRUE;
}

static void on_pad_added(GstElement *element, GstPad *pad, gpointer data)
{
  GstPad *sinkpad;
  GstElement *decoder = (GstElement *) data;
  
  sinkpad = gst_element_get_static_pad(decoder, "sink");
  gst_pad_link(pad, sinkpad);
  gst_object_unref(sinkpad);
}

struct play_file_param
{
  GstElement *pipeline;
  GstElement *source;
  gint* sval;
  GCond* cond;
  GMutex* mutex;
  GAsyncQueue* queue;
  const char* media_d;
};

static gpointer player(gpointer data)
{
  struct play_file_param *p = (struct play_file_param*)data;
  GstElement* pipeline = p->pipeline;
  GstElement* source = p->source;
  gint* sval = p->sval;
  GCond* cond = p->cond;
  GMutex* mutex = p->mutex;
  GAsyncQueue* queue = p->queue;
  const char* media_d = p->media_d;
  free(p);

  g_printf("Player thread started\n");

  for(;;) {
    g_mutex_lock(mutex);
    while((*sval) < 1)
      g_cond_wait(cond, mutex);
    *sval = 0;
    g_mutex_unlock(mutex);

    char* name = (char*)g_async_queue_pop(queue);
    if(!name)
      return NULL;

    gst_element_set_state(pipeline, GST_STATE_READY);
   
    char* path;
    asprintf(&path, "%s/%s.ogg", media_d, name);
    free(name);
    if(!path)
      return NULL;

    g_print("playing '%s'\n", path);
    g_object_set(G_OBJECT(source), "location", path, NULL);
    free(path);
    gst_element_set_state(pipeline, GST_STATE_PLAYING);
  }

  return NULL;
}

GstElement* init_pipeline(GMainLoop *loop, const char* media_d, GAsyncQueue* queue, gint* sval)
{
  GCond* cond = g_cond_new();
  if(!cond) {
    g_printerr("Condition could not be created.\n");
    return NULL;
  }
  GMutex* mutex = g_mutex_new();
  if(!cond) {
    g_printerr("Mutex could not be created.\n");
    return NULL;
  }

  GstElement *pipeline = gst_pipeline_new("dart-sounds");
  GstElement *source = gst_element_factory_make("filesrc", "source");
  GstElement *demuxer = gst_element_factory_make("oggdemux", "demuxer");
  GstElement *decoder = gst_element_factory_make("vorbisdec", "decoder");
  GstElement *conv = gst_element_factory_make("audioconvert", "converter");
  GstElement *filter = gst_element_factory_make("capsfilter", "filter");
  GstElement *sink = gst_element_factory_make("autoaudiosink", "sink");

  if (!pipeline || !source || !demuxer || !decoder || !conv || !filter || !sink) {
    g_printerr("One element could not be created. Exiting.\n");
    return NULL;
  }

  GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE (pipeline));
  struct bus_call_param* datab = malloc(sizeof(struct bus_call_param));
  if(!datab) {
    g_printerr("Memory error\n");
    return NULL;
  }
  datab->loop = loop;
  datab->sval = sval;
  datab->cond = cond;
  datab->mutex = mutex;
  gst_bus_add_watch(bus, bus_call, datab);
  gst_object_unref(bus);


  GstCaps* caps = gst_caps_new_simple("audio/x-raw-int", "channels", G_TYPE_INT, 2, NULL);
  g_object_set(G_OBJECT(filter), "caps", caps, NULL);

  gst_bin_add_many(GST_BIN(pipeline), source, demuxer, decoder, conv, filter, sink, NULL);
  gst_element_link(source, demuxer);
  gst_element_link_many(decoder, conv, filter, sink, NULL);
  g_signal_connect(demuxer, "pad-added", G_CALLBACK(on_pad_added), decoder);

  struct play_file_param* datap = malloc(sizeof(struct play_file_param));
  if(datap) {
    datap->pipeline = pipeline;
    datap->source = source;
    datap->sval = sval;
    datap->cond = cond;
    datap->mutex = mutex;
    datap->queue = queue;
    datap->media_d = media_d;
    g_thread_create(player, datap, 0, NULL);
  } else {
    g_printerr("Memory Error\n");
    return NULL;
  }

  return pipeline;
}

struct stdin_read_param
{
  GMainLoop *loop;
  GAsyncQueue *queue;
};

static gboolean stdin_read(GIOChannel* src, GIOCondition cond, gpointer data)
{
  struct stdin_read_param *p = (struct stdin_read_param*)data;
  static size_t offset = 0;
  static u_int8_t buf[100];

  int len = read(0, &(buf[offset]), sizeof(buf) - offset);
  if(len <= 0) {
    if(len) g_printerr("Error on STDIN\n");
    else g_print("EOF on STDIN\n");
    g_main_loop_quit(p->loop);
  }

  offset+=len;
  if(offset > sizeof(buf)) offset = sizeof(buf);
  
  size_t i = 0;
  for(;i < offset;) {
    if(buf[i] == '\n') {
      buf[i] = 0;

      char* tmp = strdup(buf);
      if(tmp) g_async_queue_push(p->queue, tmp);

      if(i < offset) {
        memmove(buf, &(buf[i+1]), offset - (i+1));
        offset -= i+1;
        i = 0;
      } else {
        offset = 0;
        break;
      }
    }
    else i++;
  }

  return 1;
}

int main(int argc, char *argv[])
{
  if(argc < 2) {
    fprintf(stderr, "Please specify the path to the media directory");
    return 2;
  }
  char* media_d = argv[1];

  gst_init(NULL, NULL);

  GMainLoop *loop = g_main_loop_new(NULL, FALSE);
  if(!loop) {
    g_printerr("MainLoop could not be created.\n");
    return 1;
  }

  GAsyncQueue *queue = g_async_queue_new();
  if(!queue) {
    g_printerr("Async queue could not be created.\n");
    return 1;
  }

  gint sval = 1;
  GstElement *pipeline = init_pipeline(loop, media_d, queue, &sval);
  if(!pipeline) return 1;


  GIOChannel* chan = g_io_channel_unix_new(0);
  if(!chan) {
    g_printerr("IO Channel could not be created.\n");
    return 1;
  }
  struct stdin_read_param p;
  p.loop = loop;
  p.queue = queue;
  if(!g_io_add_watch(chan, G_IO_IN | G_IO_ERR | G_IO_HUP, (GIOFunc)stdin_read, &p)) {
    g_printerr("watch for IO Channel could not be added.\n");
    return 1;
  }

  g_print("Running...\n");
  g_main_loop_run(loop);

  g_print("finished, stopping playback\n");
  gst_element_set_state(pipeline, GST_STATE_NULL);

  return 0;
}
