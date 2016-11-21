#!/bin/sh

old=""
while true;
do
  if [ "$(sha1sum /tmp/bgp)" = "${old}" ]; then
    continue
  fi
  old="$(sha1sum /tmp/bgp)"
  cat /tmp/bgp
  sleep 1
done
