#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

debugging "Installing npm packages..."

# Node.js
if test $(which npm)
then
  npm install -g $(cat globals|grep -v "#")
fi
