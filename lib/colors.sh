#!/bin/sh

###
# @author Fernando Moreira
###

##################
#     Colors     #
##################
ESC_SEQ="\x1b["
COLOR_RESET=$ESC_SEQ"39;49;00m"
COLOR_RED=$ESC_SEQ"31;01m"
COLOR_GREEN=$ESC_SEQ"32;01m"
COLOR_YELLOW=$ESC_SEQ"33;01m"
COLOR_BLUE=$ESC_SEQ"34;01m"
COLOR_MAGENTA=$ESC_SEQ"35;01m"
COLOR_CYAN=$ESC_SEQ"36;01m"

function ok() {
  echo -e "$COLOR_GREEN[ok]$COLOR_RESET "$1
}

function bot() {
  echo -e "\n$COLOR_GREEN\[._.]/ Uhulll!! $COLOR_RESET "$1
}

function running() {
  echo -en "\n$COLOR_YELLOW ⇒ $COLOR_RESET"$1": "
}

function action() {
  echo -e "\n$COLOR_YELLOW[action]:$COLOR_RESET\n ⇒ $1..."
}

function warn() {
  echo -e "$COLOR_YELLOW[warning]$COLOR_RESET "$1
}

function error() {
  echo -e "$COLOR_RED[error]$COLOR_RESET "$1
}
