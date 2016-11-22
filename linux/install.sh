#!/bin/bash
#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh" \
    && . "utils.sh"

update
upgrade

# Install all packages listed in the packages file
echo $(cat packages|grep -v "#")

update
