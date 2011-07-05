/*
 *  eet
 *
 *
 *  Copyright (C) 2011 Christian Pointner <equinox@realraum.at>
 *
 *  This file is part of eet.
 *
 *  eet is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  eet is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with eet. If not, see <http://www.gnu.org/licenses/>.
 */

#include <sys/select.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int write_buf(char* buf, int len)
{
  int i;
  for(i=0; i < len;) {
    int w = write(1, &(buf[i]), len - i);
    if(w < 0)
      return w;

    i+=w;
  }
  return 0;
}

int main(int argc, char* argv[])
{
  if(argc < 2) {
    fprintf(stderr, "Please specify a path to the fifo\n");
    return 1;
  }
  int fd = open(argv[1], O_RDONLY);
  if(fd < 0) {
    perror("open()");
    return 2;
  }

  char buf[1024];
  fd_set rfds;

  for(;;) {
    FD_ZERO(&rfds);
    FD_SET(0, &rfds);
    FD_SET(fd, &rfds);
    int ret = select(fd+1, &rfds, NULL, NULL, NULL);

    if (ret == -1) {
      perror("select()");
      return 3;
    }
    else {
      int i;
      for(i = 0; i < 2; i++) {
        if(FD_ISSET((i ? fd : 0), &rfds)) {
          int r = read((i ? fd : 0), buf, sizeof(buf));
          if(r <=0 ) {
            return r;
          }

          ret = write_buf(buf, r);
          if(ret) return ret;
        }
      }
    }
  }

  return 0;
}
