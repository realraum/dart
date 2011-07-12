/*
 *  ttyread
 *
 *
 *  Copyright (C) 2011 Christian Pointner <equinox@realraum.at>
 *
 *  This file is part of ttyread.
 *
 *  ttyread is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  ttyread is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with ttyread. If not, see <http://www.gnu.org/licenses/>.
 */

#include <sys/select.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <stdio.h>

int setup_tty(int fd)
{
  struct termios tmio;

  int ret = tcgetattr(fd, &tmio);
  if(ret) {
    perror("tcgetattr()");
    return ret;
  }

  ret = cfsetospeed(&tmio, B57600);
  if(ret) {
    perror("cfsetospeed()");
    return ret;
  }

  ret = cfsetispeed(&tmio, B57600);
  if(ret) {
    perror("cfsetispeed()");
    return ret;
  }

  tmio.c_lflag &= ~ECHO;
  tmio.c_lflag |= CLOCAL;

  tmio.c_iflag &= ~ICRNL;
  tmio.c_iflag &= ~IGNCR;
  tmio.c_iflag |= IGNBRK | BRKINT;

  tmio.c_cflag |= CLOCAL;

  ret = tcsetattr(fd, TCSANOW, &tmio);
  if(ret) {
    perror("tcsetattr()");
    return ret;
  }

  ret = tcflush(fd, TCIFLUSH);
  if(ret) {
    perror("tcflush()");
    return ret;
  }

  fd_set fds;
  struct timeval tv;
  FD_ZERO(&fds);
  FD_SET(fd, &fds);
  tv.tv_sec = 0;
  tv.tv_usec = 50000;
  for(;;) {
    ret = select(fd+1, &fds, NULL, NULL, &tv);
    if(ret > 0) {
      char buffer[100];
      ret = read(fd, buffer, sizeof(buffer));
    }
    else
      break;
  }

  return 0;
}

int main(int argc, char* argv[])
{
  if(argc < 2) {
    fprintf(stderr, "Please specify a path to the tty\n");
    return 1;
  }

  int fd = open(argv[1], O_RDONLY);
  if(fd < 0) {
    perror("open()");
    return 2;
  }

  if(setup_tty(fd)) return 3;

  char buf[100];
  for(;;) {
    ssize_t r = read(fd, buf, sizeof(buf));
    if(r <= 0) {
      perror("read()");
      return r;
    }

    ssize_t i;
    for(i=0; i < r;) {
      ssize_t w = write(1, &(buf[i]), r - i);
      if(w < 0) {
        perror("write()");
        return w;
      }
      i+=w;
    }
  }

  return 0;
}
