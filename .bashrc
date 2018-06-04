#!/bin/bash
# ~/.bashrc - bash interactive session config

# is this an interactive session?
[[ -z "${PS1}" ]] && return

# prevent bashrc from loading twice
[[ -n "${BASHRC}" ]] && return
export BASHRC="${BASH_SOURCE[0]}"

# .bashrc.prepend
[[ -r "${HOME}/.bashrc.prepend" ]] && source "${HOME}/.bashrc.prepend"

# the prompt string
prompt_command() {
  # last command exit status
  [[ ${?} -eq 0 ]] && local exc='\$' || local exc='\[\033[01;31m\]\$\[\033[0m\]'

  # colors
  local reset='\[\033[0m\]'
  local grey='\[\033[1;30m\]'
  local red='\[\033[1;31m\]'
  local green='\[\033[1;32m\]'
  local yellow='\[\033[1;33m\]'
  local blue='\[\033[1;34m\]'
  local cyan='\[\033[0;36m\]'

  # hostname & user
  local host="${blue}${HOSTNAME%%.*}${reset}"
  [[ ${UID} -eq 0 ]] && local user="${red}${USER}${reset}" || local user="${green}${USER}${reset}"

  # current directory
  local pwd="${PWD}"
  [[ "${pwd}" = ${HOME} || "${pwd}" = ${HOME}/* ]]  && pwd='~'"${PWD#${HOME}}"
  [[ "${pwd}" = /home/* ]]                          && pwd='~'"${pwd#/home/}"
  [[ "${pwd}" = /Users/* ]]                         && pwd='~'"${pwd#/Users/}"
  pwd="${yellow}${pwd}${reset}"

  # scm statuses, programming language environments
  local scm=

  # avoid tree scans on home directory & add an option to disable them (mainly for slow disks &| large repos)
    if [[ -z ${BASHRC_DISABLE_SCM} && "${dir}" != "${HOME}" ]]; then
      # search for first .git/.svn/.hg in the tree
      local dir="${PWD}" git_dir= svn_dir= hg_dir=
      while [[ "${dir}" != '/' && -n "${dir}" ]]; do
        [[ -z ${BASHRC_DISABLE_SCM_GIT} && -z ${git_dir} && -e "${dir}/.git" ]] && git_dir="${dir}/.git" && break
        [[ -z ${BASHRC_DISABLE_SCM_SVN} && -z ${svn_dir} && -e "${dir}/.svn" ]] && svn_dir="${dir}/.svn" && break
        [[ -z ${BASHRC_DISABLE_SCM_HG}  && -z ${hg_dir}  && -e "${dir}/.hg"  ]] && hg_dir="${dir}/.hg"   && break
        dir="${dir%/*}"
      done

      # git
      if [[ -n ${git_dir} ]]; then
        local branch= extra=

        if [[ -d "${git_dir}/rebase-apply" ]]; then
          if [[ -f "${git_dir}/rebase-apply/rebasing" ]]; then
            extra="|${yellow}rebase${reset}"
          elif [[ -f "${git_dir}/rebase-apply/applying" ]]; then
            extra="|${yellow}am${reset}"
          else
            extra="|${yellow}am/rebase${reset}"
          fi
          branch="$(< "${git_dir}/rebase-apply/head-name")"
        elif [[ -f "${git_dir}/rebase-merge/interactive" ]]; then
          extra="|${yellow}rebase-i${reset}"
          branch="$(< "${git_dir}/rebase-merge/head-name")"
        elif [[ -d "${git_dir}/rebase-merge" ]]; then
          extra="|${yellow}rebase-m${reset}"
          branch="$(< "${git_dir}/rebase-merge/head-name")"
        elif [[ -f "${git_dir}/MERGE_HEAD" ]]; then
          extra="|${yellow}merge${reset}"
          branch=`git --git-dir="${git_dir}" symbolic-ref HEAD 2>/dev/null`
        else
          if ! branch=`git --git-dir="${git_dir}" symbolic-ref HEAD 2>/dev/null`; then
            if branch=`git --git-dir="${git_dir}" describe --exact-match HEAD 2>/dev/null`; then
              branch="${blue}${branch}"
            elif branch=`git --git-dir="${git_dir}" describe --tags HEAD 2>/dev/null`; then
              branch="${blue}${branch}"
            else
              branch="${blue}`cut -c1-8 "${git_dir}/HEAD"`"
            fi
          fi
        fi

        branch="${branch#refs/heads/}"
        if [[ -n ${branch} ]]; then
          local status=`git status --porcelain 2>/dev/null | head -1`
          if [[ -n ${status} ]]; then
            scm="${scm}${reset}(${grey}git:${red}${branch}${reset}${extra})"
          else
            scm="${scm}${reset}(${grey}git:${green}${branch}${reset}${extra})"
          fi
        fi
      fi
    fi
  fi

  # finally, set the variable
  PS1="${reset}[${user}@${host}(${pwd}${scm})]${exc} "
}

PS1='\u@\h:\w\$ '
PROMPT_COMMAND=prompt_command

# git prompt string
GIT_PS1_SHOWDIRTYSTATE=true

export PS1='[\u@mbp \w$(__git_ps1)]\$ '

# .bashrc.aliases
[[ -r "${HOME}/.bashrc.aliases" ]] && source "${HOME}/.bashrc.aliases"

# remove /usr/local/sbin & /usr/local/bin from path
PATH="${PATH/\/usr\/local\/sbin:}"
PATH="${PATH/:\/usr\/local\/sbin}"
PATH="${PATH/\/usr\/local\/bin:}"
PATH="${PATH/:\/usr\/local\/bin}"

# prepend /usr/local/sbin, /usr/local/bin, ~/bin, ~/.bin, ~/local/bin, ~/.local/bin to path
[[ ! "${PATH}" = */usr/local/sbin* ]] && PATH="/usr/local/sbin:${PATH}"
[[ ! "${PATH}" = */usr/local/bin* ]]  && PATH="/usr/local/bin:${PATH}"
[[ -d "${HOME}/bin" ]]                && PATH="${HOME}/bin:${PATH}"
[[ -d "${HOME}/.bin" ]]               && PATH="${HOME}/.bin:${PATH}"
[[ -d "${HOME}/local/bin" ]]          && PATH="${HOME}/local/bin:${PATH}"
[[ -d "${HOME}/.local/bin" ]]         && PATH="${HOME}/.local/bin:${PATH}"
export PATH

# disable history expansion
set +H

# set default editor
export EDITOR=vim

# nicer python repl
export PYTHONSTARTUP="${HOME}/.pythonrc"

# bash completion
if [[ -f /usr/local/etc/bash_completion ]]; then
  source /usr/local/etc/bash_completion
elif [[ -f /usr/local/share/bash-completion/bash_completion ]]; then
  source /usr/local/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
  source /etc/bash_completion
fi

# rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# nvm
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

# bashrc.d
if [[ -d "${HOME}/.bashrc.d" ]]; then
  shopt -s nullglob
  for file in "${HOME}/.bashrc.d"/*; do
    source "${file}"
  done
  shopt -u nullglob
fi

# .bashrc.append
[[ -r "${HOME}/.bashrc.append" ]] && source "${HOME}/.bashrc.append"
