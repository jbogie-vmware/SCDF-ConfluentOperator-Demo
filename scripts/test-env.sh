#!/bin/bash

for i in helm kubectl k9s java mvn; do
  if which $i >/dev/null; then
    echo "$i is ready"
  else
    echo "$i is not ready"
  fi
done
