#!/bin/bash
# Color
_norm=$(tput sgr0)
_red=$(tput setaf 1)
_green=$(tput setaf 2)
_tan=$(tput setaf 3)
_cyan=$(tput setaf 6)

function _print() {
	printf "${_norm}%s${_norm}\n" "$@"
}
function _info() {
	printf "${_cyan}? %s${_norm}\n" "$@"
}
function _success() {
	printf "${_green}? %s${_norm}\n" "$@"
}
function _warning() {
	printf "${_tan}? %s${_norm}\n" "$@"
}
function _error() {
	printf "${_red}? %s${_norm}\n" "$@"
}
