#!/usr/bin/env bash

# (As the name implies) Based on the visual style of vim-powerline.
# Original prompt based on falconindy's, but that's been mostly replaced.

# Generates a prompt that looks roughly like
# >>> ~/path/to/src
# Where the first > (blue) represents a local tty, the second > (green)
# 	represents a non-su'd non-root tty, while the third > (magenta)
#	represents a git repo, branch "master", untouched.
# These > expand and change color as desrcribed by the conditionals below.
# The xterm/rxvt window title is set as if it were a colorless console.

prompt_powerline() {
	local _none="\[\e[0m\]"

	local _k="\[\e[0;30;40m\]" _r="\[\e[0;31;40m\]" _g="\[\e[0;32;40m\]" _y="\[\e[0;33;40m\]" \
		  _b="\[\e[0;34;40m\]" _m="\[\e[0;35;40m\]" _c="\[\e[0;36;40m\]" _w="\[\e[0;37;40m\]"

# Switches the fancy powerline symbols for simple > and a flat cap for the console
	if [[ $TERM == 'linux' ]]; then
		_div='>' _cap="";
	else
		_div='⮁' _cap="\[\e[0;30m\]⮀"
	fi

# Switches the default blue ">" for a yellow " hostname >" if remote
	if [[ $SSH_TTY ]]; then
		local _host="$_y \h $_div" _title_host="\h>";
	else
		local _host="$_b$_div" _title_host=">";
	fi

# Replaces the default green ">" for a green " username >" if other non-root or
#	a red " root >" if root
	if (( UID == 1000 )); then # I can generalize this later ...
		local _user="$_g$_div" _title_user=">"
	elif (( UID == 0 )); then
		local _user="$_r root $_div" _title_user="root>";
	else
		local _user="$_g \u $_div" _title_user="\u";
	fi

# Inserts a bold red " 1 >" between the username and git segments if $? != 0
	local _ret='$((( _ret_value )) && printf " \[\e[1;31;40m\]$_ret_value $_div")'
	
# If not in a git repo, removes the magenta ">".  If in a git repo but not in an
#	unmodified "master" branch, prints magenta " branch *+ >".
# This is so ugly and I DON'T CARE IT WORKS
	local _git='$(if [[ "$_git_branch_ps1" == "master" ]]; then printf "\[\e[0;35;40m\]$_div"; elif [[ "$_git_branch_ps1" ]]; then printf "\[\e[0;35;40m\] $_git_branch_ps1 $_div"; fi)'
	
	local _title_git='$(if [[ "$_git_branch_ps1" == "master" ]]; then printf ">"; elif [[ "$_git_branch_ps1" ]]; then printf "${_git_branch_ps1}>"; fi)'

# Ugly Hack of the Day: determines if PWD is a subdir in ~/src via array.  If so, displays the top
#	subdir in white, then checks if PWD is in a subdir of that topdir.  If so, it then prints the
#	rest like a normal directory.  If none of this is true, print the regular pwd.
	local _cwd='$(IFS=/; read -a _pwdparts <<< "$PWD"; if [[ ${_pwdparts[3]} == "src" ]] && [[ ${_pwdparts[4]} ]]; then printf " \[\e[0;37;40m\]${_pwdparts[4]}\[\e[0;36;40m\]" && [[ ${_pwdparts[5]} ]] && printf "/${_pwdparts[*]:5}"; else printf "\[\e[0;36;40m\] \w"; fi)'

# Assembles and implements the xterm/rxvt title
	case $TERM in
		xterm*|rxvt*)
			local _title="\[\e]2;$_title_host$_title_user$_title_git \w\007\]" ;;
		*)
			local _title="" ;;
	esac

# The part we've all been waiting for!
	PS1="$_title$_host$_user$_ret$_git$_cwd$_cap$_none "
	export PS2='cont >'
	export PS4='+$BASH_SOURCE[$LINENO]: '
}

# Told you it was ugly.
get_git_branch() { _git_branch_ps1="$()"; } # sobad

PROMPT_COMMAND='_ret_value=$?; _git_branch_ps1="$()"'
GIT_PS1_SHOWDIRTYSTATE=yes
prompt_powerline
unset prompt_powerline
unset _git_branch_ps1

fortune -n short
date +%H:%M | toilet -f mono9
