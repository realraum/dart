#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage $0 <mode>"
  exit 1
fi

mode=$1
shift

FIFO=/tmp/dart.fifo
rm -f $FIFO
mkfifo $FIFO
stty -echo

ssh dart stty -F /dev/ttyDart 57600
ssh dart cat /dev/ttyDart  >$FIFO &
./eet $FIFO | ./dart-$mode.pl $* | ./dart-soundonly.pl | ../dart-sounds/src/dart-sounds ../dart-sounds/media > /dev/null
rm -f $FIFO

exit 0
