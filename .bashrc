# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific XDG environment
# Note XDG_RUNTIME_DIR is set by default through pam_systemd
# See also https://wiki.archlinux.org/title/XDG_Base_Directory
# 
# TODO: consider using canonical glob matches, see https://www.shellcheck.net/wiki/SC2076
mkdir -p "$HOME/.local/bin"
if ! [[ "$PATH" =~ "$HOME/.local/bin:" ]]
then
	export PATH="$HOME/.local/bin:$PATH"
fi
if [ -z "$XDG_DATA_HOME" ];
then
	export XDG_DATA_HOME="$HOME/.local/share"
fi
mkdir -p "$XDG_DATA_HOME"
if [ -z "$XDG_CONFIG_HOME" ]; 
then
	export XDG_CONFIG_HOME="$HOME/.config"
fi
mkdir -p "$XDG_CONFIG_HOME"
if [ -z "$XDG_CACHE_HOME" ];
then
	export XDG_CACHE_HOME="$HOME/.cache"
fi
mkdir -p "$XDG_CACHE_HOME"
if [ -z "$XDG_STATE_HOME" ];
then
	export XDG_STATE_HOME="$HOME/.local/state"
fi
mkdir -p "$XDG_STATE_HOME"
if [ -z "$XDG_DATA_DIRS" ];
then
	export XDG_DATA_DIRS="/usr/local/share:/usr/share"
fi
IFS=':'
for DATA_DIR in $XDG_DATA_DIRS; do
	mkdir -p "$DATA_DIR" > /dev/null 2>&1
done
if [ -z "$XDG_CONFIG_DIRS" ];
then
	export XDG_CONFIG_DIRS="/etc/xdg"
fi
IFS=':'
for CONFIG_DIR in $XDG_CONFIG_DIRS; do
	mkdir -p "$CONFIG_DIR"
done

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi
unset rc
