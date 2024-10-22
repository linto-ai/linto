#!/bin/bash
set -uea
SUDO=''
. .envdefault # Source all default env
if [ -f ".build" ]; then
  . .build
else
  . .envdefault
fi

if [ -f ./running/.dockerenv ]; then
  . ./running/.dockerenv # Local overrides
fi

# docker stack deploy every file in ./running in $LINTO_STACK_NAME stack
for f in ./running/*.yaml; do
  if [ -f "$f" ]; then
    echo "Deploying $f"
    docker stack deploy --with-registry-auth --resolve-image always -c $f $LINTO_STACK_NAME
  fi
done
