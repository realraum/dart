#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage $0 <mode> [<param1> [<param2> ...]]"
  exit 1
fi

MYSELF=`readlink -f "$0"`
MYPATH=`dirname "$MYSELF"`
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
ssh dart killall ttyread 2>&1
ssh dart ttyread /dev/ttyDart  >$FIFO &
cd $MYPATH
$MYPATH/eet $FIFO | perl -I $MYPATH $MYPATH/dart-$mode.pl $* | $MYPATH/../dart-sounds/src/dart-sounds $MYPATH/../dart-sounds/media > /dev/null
rm -rf $FIFO_D

exit 0
