#
# ~/.bashrc
#

# fix gpg
export GPG_TTY=$(tty)
if [[ -n "$SSH_CONNECTION" ]]; then
  export PINENTRY_USER_DATA="USE_CURSES=1"
fi

# set vim as editor
export VISUAL=vim

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# enable docker buildkit
export DOCKER_BUILDKIT=1

# prompt
PS1='\[\033[32m\]\u@\h \[\033[33m\]\W\[\033[0m\] \$ '

# compressing/decompressing
alias   compresstar='tar -cf'
alias decompresstar='tar -xf'
alias   compressgz='tar -czf'
alias decompressgz='tar -xzf'

# git
alias ga='git add'
alias gaa='git add -A'
alias gb='git branch'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gd='git diff'
alias gf='git fetch --all'
alias gl='git lg'
alias gmv='git mv'
alias gpull='git pull'
alias gpush='git push'
alias gpushfwl='git push --force-with-lease'
alias grm='git rm'
alias gs='git status'

# internet
alias pingtest='ping -c 4 google.com'
alias wifi='sudo wifi-menu'

# misc
alias cl='clear;'
alias cl2='clear;clear;'
alias cls='clear;ls'
alias df='df -h'
alias du='du -cah --apparent-size'
alias emptytrash='rm -r ~/.local/share/Trash/*/*'
alias l='ls'
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'
alias l1='ls -1'
alias vim='vim -o' #always open multiple files in split mode

