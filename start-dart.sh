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
FIFO_IN=$FIFO_D/dart-in.fifo
FIFO_SHOUT=$FIFO_D/dart-out.fifo
mkfifo $FIFO_IN
mkfifo $FIFO_SHOUT

trap signal_handler INT TERM

signal_handler()
{
  rm -rf $FIFO_D
}

stty -echo
ssh dart killall ttyread 2>&1
ssh dart ttyread /dev/ttyDart  >$FIFO_IN &
cd $MYPATH
$MYPATH/../dart-sounds/src/dart-sounds $MYPATH/../dart-sounds/media > /dev/null <$FIFO_SHOUT &
$MYPATH/eet $FIFO_IN | perl -I $MYPATH $MYPATH/dart-$mode.pl $FIFO_SHOUT $*
rm -rf $FIFO_D

exit 0
