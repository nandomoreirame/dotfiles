#!/bin/bash
#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh" \
    && . "utils.sh"

update
upgrade

# Install all packages listed in the packages file
sudo apt-get install $(cat packages|grep -v "#")

update
sudo apt-get autoclean