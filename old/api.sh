#!/usr/bin/env bash

TOKEN=$(<./token.txt)
if [ -n "$1" ]; then
    xhs -b slumbot.com/api/act token="$TOKEN" incr="$1"
else
    xhs -b slumbot.com/api/new_hand token="$TOKEN"
fi
