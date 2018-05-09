#!/bin/bash

#
# files to symlink @ ~/
#

HOME_SYMLINKS=(\
  .bash_profile     \
  .bashrc           \
  .bashrc.aliases   \
  .pythonrc         \
)

#
# colors
#

COLOR_RED="\033[01;31m"
COLOR_GREEN="\033[01;32m"
COLOR_YELLOW="\033[01;33m"
COLOR_BLUE="\033[01;34m"
COLOR_WHITE="\033[00;00m"

#
# this script's path
#

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#
# force flag
#

if [[ "${1}" = '-f' || "${1}" = '--force' ]]; then
  FORCE='true'
else
  FORCE='false'
fi

#
# question? [y/N]
#

QUESTION() {
  echo -ne "${COLOR_YELLOW}${*} ${COLOR_BLUE}[y/N]${COLOR_WHITE} "
  read -n 1 -r
  echo
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

#
# symlink files @ ~/
#

create_home_symlinks() {
  for symlink in "${HOME_SYMLINKS[@]}"; do
    if [[ -e "${HOME}/${symlink}" ]]; then
      if ${FORCE} || QUESTION "File ${COLOR_WHITE}${HOME}/${symlink}${COLOR_YELLOW} already exists. Overwrite?"; then
        rm -rf -- "${HOME}/${symlink}"
      else
        echo -e "${COLOR_RED}skip${COLOR_WHITE} ${HOME}/${symlink}"
        continue
      fi
    fi

    echo -e "${COLOR_GREEN}install${COLOR_WHITE} ${HOME}/${symlink}"
    ln -s "${ROOT}/${symlink}" "${HOME}/${symlink}"
  done
}

#
# create ~/.gitconfig
#

create_home_gitconfig() {
  if [[ -e "${HOME}/.gitconfig" ]]; then
    if ! ${FORCE} && ! QUESTION "File ${COLOR_WHITE}${HOME}/.gitconfig${COLOR_YELLOW} already exists. Overwrite?"; then
      echo -e "${COLOR_RED}skip${COLOR_WHITE} ${HOME}/.gitconfig"
      return 0
    fi
  fi

  git config --global user.name 'Zdravko Iliev'
  git config --global user.email 'zdravko.iliev61'$'\100''gmail'$'\056''com'
  git config --global color.ui 'true'
  git config --global alias.st 'status'
  git config --global alias.ci 'commit'
  git config --global alias.co 'checkout'
  git config --global alias.dt 'difftool'
  git config --global alias.mt 'mergetool'
  git config --global alias.df 'diff --ignore-all-space'
  git config --global alias.lg 'log --color --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
  echo -e "${COLOR_GREEN}create${COLOR_WHITE} ${HOME}/.gitconfig"
}

#
# do the actual job
#

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  create_home_symlinks
  create_home_gitconfig
fi
