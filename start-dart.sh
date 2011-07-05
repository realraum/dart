#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage $0 <mode> [<param1> [<param2> ...]]"
  exit 1
fi

mode=$1
shift

FIFO_D=`mktemp -d`
FIFO=$FIFO_D/dart.fifo
mkfifo $FIFO

trap signal_handler INT TERM

signal_handler()
{
  rm -rf $FIFO_D
}

stty -echo
ssh dart stty -F /dev/ttyDart 57600
ssh dart cat /dev/ttyDart  >$FIFO &
./eet $FIFO | ./dart-$mode.pl $* | ./dart-soundonly.pl | ../dart-sounds/src/dart-sounds ../dart-sounds/media > /dev/null
rm -rf $FIFO_D

exit 0
