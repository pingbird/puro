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
curl -f --retry 3 --output "$PURO_EXE" "$DOWNLOAD_URL" || {
  >&2 echo "Error downloading $DOWNLOAD_URL"
  $ret $?
}
chmod +x "$PURO_EXE" || $ret $?

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

PROFILE="$(detect_profile)"

PATH_EXPORT_STR="export PATH=\"\$PATH:$PURO_ROOT/bin\""

if [ -n "${PROFILE-}" ] ; then
  if ! grep -F -qc "$PATH_EXPORT_STR" "$PROFILE"; then
    print_string "Adding $PURO_ROOT/bin to $PROFILE"
    printf "\\n%s\\n # Added by puro" "$PATH_EXPORT_STR" >> "$PROFILE"
  else
    print_string "Found $PURO_ROOT/bin in $PROFILE"
  fi
fi

if [[ "$PATH" != *":$PURO_ROOT/bin"* ]] && is_sourced; then
  eval "$PATH_EXPORT_STR"
  print_string "Updated PATH of current shell"
fi

print_string "Puro installed to $PURO_ROOT successfully"

"$PURO_ROOT/bin/puro" version