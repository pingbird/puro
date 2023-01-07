#!/usr/bin/env bash

if [ -z "${PURO_ROOT-}" ]; then
  PURO_ROOT=${HOME}/.puro
fi

if [ -z "${PURO_VERSION-}" ]; then
  PURO_VERSION="master"
fi

PURO_BIN="$PURO_ROOT/bin"
PURO_EXE="$PURO_BIN/puro"

is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
    case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
    case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

if is_sourced; then
    # shellcheck disable=SC2209
    ret=return
else
    # shellcheck disable=SC2209
    # shellcheck disable=SC2034
    ret=exit
fi

OS="$(uname -s)"
if [ "$OS" = 'Darwin' ]; then
  DOWNLOAD_URL="https://puro.dev/builds/${PURO_VERSION}/darwin-x64/puro"
elif [ "$OS" = 'Linux' ]; then
  DOWNLOAD_URL="https://puro.dev/builds/${PURO_VERSION}/linux-x64/puro"
else
  >&2 echo "Error: Unknown OS: $OS"
  ret 1
fi

command -v curl > /dev/null 2>&1 || {
  >&2 echo 'Error: could not find curl command'
  case "$OS" in
    Darwin)
      >&2 echo 'Consider running "brew install curl".'
      ;;
    Linux)
      >&2 echo 'Consider running "sudo apt-get install curl".'
      ;;
  esac
  $ret 1
}

mkdir -p "$PURO_BIN"
curl -f --retry 3 --output "$PURO_EXE.new" "$DOWNLOAD_URL" || {
  >&2 echo "Error downloading $DOWNLOAD_URL"
  $ret $?
}
chmod +x "$PURO_EXE.new" || $ret $?

"$PURO_ROOT/bin/puro.new" install-puro --promote