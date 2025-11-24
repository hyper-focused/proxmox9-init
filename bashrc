# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=2000
HISTFILESIZE=3000

# Use Xterm
export TERM=xterm-256color

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Colorize ls and other gnu utilities
export LS_COLORS="$(vivid generate molokai)"
alias ls='ls --color=auto --group-directories-first'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Colorize less with LS_COLORS-inspired colors
export LESS="-R"
export LESS_TERMCAP_mb=$'\e[1;38;2;249;38;114m'  # Bold magenta (start blinking)
export LESS_TERMCAP_md=$'\e[0;38;2;102;217;239m'  # Cyan (start bold)
export LESS_TERMCAP_me=$'\e[0m'                   # Reset
export LESS_TERMCAP_se=$'\e[0m'                   # Reset (end standout)
export LESS_TERMCAP_so=$'\e[0;38;2;226;209;57m'   # Yellow (start standout)
export LESS_TERMCAP_ue=$'\e[0m'                   # Reset (end underline)
export LESS_TERMCAP_us=$'\e[0;38;2;0;255;135m'    # Green (start underline)

export EDITOR=nano
export VISUAL=nano

# Bat aliases
alias cat="batcat --color=auto"

# Starship custom prompt
eval "$(starship init bash)"
