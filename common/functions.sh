#!/bin/sh

##################
# Code # Color   #
##################
#  00  # Off     #
#  30  # Black   #
#  31  # Red     #
#  32  # Green   #
#  33  # Yellow  #
#  34  # Blue    #
#  35  # Magenta #
#  36  # Cyan    #
#  37  # White   #
##################

print() { echo -e "\n\033[1;32m==> $1 \033[0m\n"; }
msg_checking() { echo -e "\n\033[1;32m==> $1 ✔ \033[0m\n"; }
msg_installing() { echo -e "\n\033[1;33m==> Installing $1 \033[0m\n"; }
msg_installed() { echo -e "\n\033[1;32m==> $1 successfully installed ✔ \033[0m\n"; }
msg_updating() { echo -e "\n\033[1;33m==> $1 [updating] ✔ \033[0m\n"; }
msg_ok() { echo -e "\n\033[1;32m==> $1 ✔ \033[0m\n"; }
msg() { echo -e "\n\033[0;32m$1 \033[0m\n"; }
msg_alert() { echo -e "\n\033[1;31m✖ $1 ✖ \033[0m\n"; }
