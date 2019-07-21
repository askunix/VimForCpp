# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias rm="rm -i"
alias mv="mv -i"
alias grephc="grep --include *.cc --include *.h --color"
alias grepcc="grep --include *.cc --color"
# alias gcc="/usr/local/gcc6/bin/gcc"
# alias g++="/usr/local/gcc6/bin/g++"
alias cl="clear"
# 需要安装 gdbgui
# pip install gdbgui
alias gdbgui="gdbgui --host 0.0.0.0 --port 9090"

# 需要安装 neovim
# yum -y install epel-release
# yum install neovim
# yum install python2-neovim.noarch
alias vi="nvim"
alias vim="nvim"

#ulimit -c unlimited

export SVN_EDITOR=vim

export TERM="screen-256color"

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
