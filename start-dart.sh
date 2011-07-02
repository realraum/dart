#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage $0 <mode>"
  exit 1
fi

mode=$1
shift

ssh dart stty -F /dev/ttyDart 57600
ssh dart cat /dev/ttyDart | ./dart-$mode.pl $* | ./dart-soundonly.pl | ../dart-sounds/src/dart-sounds ../dart-sounds/media > /dev/null
