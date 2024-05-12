#!/bin/bash

tty=$1

if [ -z "$tty" ]; then
  exit 1
fi

TMUX_YANK_NOT_CANCEL_PAT=${TMUX_YANK_NOT_CANCEL_PAT:-"gdb"}

# shellcheck disable=SC2009
ps -o state= -o comm= -t "$tty" |
  grep -iqE "^[^TXZ]+ +$TMUX_YANK_NOT_CANCEL_PAT"
