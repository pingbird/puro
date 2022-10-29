#!/usr/bin/env bash

if [ -n "$PURO_ROOT" ]; then
  PURO_ROOT=${HOME}/.puro
fi

if [ -n "$PURO_VERSION" ]; then
  PURO_VERSION="master"
fi

mkdir -p "$PURO_ROOT"

print_string() {
  command printf %s\\n "$*" 2>/dev/null
}

try_profile() {
  if [ -z "${1-}" ] || [ ! -f "${1}" ]; then
    return 1
  fi
  print_string "${1}"
}

detect_profile() {
  local DETECTED_PROFILE
  DETECTED_PROFILE=''

  if [ "${SHELL#*bash}" != "$SHELL" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ "${SHELL#*zsh}" != "$SHELL" ]; then
    if [ -f "$HOME/.zshrc" ]; then
      DETECTED_PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.zprofile" ]; then
      DETECTED_PROFILE="$HOME/.zprofile"
    fi
  fi

  if [ -z "$DETECTED_PROFILE" ]; then
    for EACH_PROFILE in ".profile" ".bashrc" ".bash_profile" ".zprofile" ".zshrc"
    do
      if DETECTED_PROFILE="$(try_profile "${HOME}/${EACH_PROFILE}")"; then
        break
      fi
    done
  fi

  if [ -n "$DETECTED_PROFILE" ]; then
    print_string "$DETECTED_PROFILE"
  fi
}

PROFILE="$(nvm_detect_profile)"

PATH_EXPORT_STR="\nexport PATH=\"\$PATH:$PURO_ROOT/bin\""

if which wget >/dev/null ; then
    wget
elif which curl >/dev/null ; then
    curl --option argument
else
    echo "Cannot download, neither wget nor curl is available."
fi