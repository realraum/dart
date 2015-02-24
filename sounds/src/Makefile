##
##  dart-sounds
##
##
##  Copyright (C) 2011 Christian Pointner <equinox@spreadspace.org>
##                         
##  This file is part of dart-sounds.
##
##  dart-sounds is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  any later version.
##
##  dart-sounds is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with dart-sounds. If not, see <http://www.gnu.org/licenses/>.
##

ifneq ($(MAKECMDGOALS),distclean)
include include.mk
endif

EXECUTABLE := dart-sounds

C_OBJS := dart-sounds.o

C_SRCS := $(C_OBJS:%.o=%.c)

.PHONY: clean cleanall distclean install install-bin uninstall remove

all: $(EXECUTABLE)

%.d: %.c
	@set -e; rm -f $@; \
  $(CC) -MM $(CFLAGS) $< > $@.$$$$; \
  sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
  rm -f $@.$$$$; echo '(re)building $@'

ifneq ($(MAKECMDGOALS),distclean)
-include $(C_SRCS:%.c=%.d)
endif

$(EXECUTABLE): $(C_OBJS)
	$(CC) $(C_OBJS) -o $@ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $<

strip: $(EXECUTABLE)
	$(STRIP) -s $(EXECUTABLE)


distclean: cleanall
	find . -name *.o -exec rm -f {} \;
	find . -name "*.\~*" -exec rm -rf {} \;
	rm -f include.mk
	rm -f config.h

clean:
	rm -f *.o
	rm -f *.d
	rm -f *.d.*
	rm -f $(EXECUTABLE)

INSTALL_TARGETS := install-bin
REMOVE_TARGETS := remove-bin

install: all $(INSTALL_TARGETS)

install-bin: $(EXECUTABLE)
	$(INSTALL) -d $(DESTDIR)$(BINDIR)
	$(INSTALL) -m 755 $(EXECUTABLE) $(DESTDIR)$(BINDIR)

install-man: manpage
	$(INSTALL) -d $(DESTDIR)$(MANDIR)/man8/
	$(INSTALL) -m 644 ../doc/$(EXECUTABLE).8 $(DESTDIR)$(MANDIR)/man8/$(EXECUTABLE).8

uninstall: remove

remove: $(REMOVE_TARGETS)

remove-bin:
	rm -f $(DESTDIR)$(BINDIR)/$(EXECUTABLE)
