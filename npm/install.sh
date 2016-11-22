#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

debugging "Installing npm packages..."

npm install -g $(cat globals|grep -v "#")