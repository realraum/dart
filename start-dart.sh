#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage $0 <mode>"
  exit 1
fi

mode=$1

ssh dart stty -F /dev/ttyDart 57600
ssh dart cat /dev/ttyDart | ./dart-$mode.pl | ../dart-sounds/src/dart-sounds ../dart-sounds/media
