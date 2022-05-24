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
	printf "${_cyan}➜ %s${_norm}\n" "$@"
}
function _success() {
	printf "${_green}✓ %s${_norm}\n" "$@"
}
function _warning() {
	printf "${_tan}⚠ %s${_norm}\n" "$@"
}
function _error() {
	printf "${_red}✗ %s${_norm}\n" "$@"
}

##########################################################
# Variables
LOG_FILE="/root/.pveinstall/log/install_plait.log"
INFO_SIGNAL="/root/.pveinstall/info/PLAIT_INSTALLED"
locationInfo=""
SOURCE_NAME="gitlab"
SOURCE_LINK=""
DEV=""
LOG=0

##########################################################
# function

function _checkroot() {
	if [[ $EUID != 0 ]]; then
        _error "Do not have root previlage, Please run \"sudo su -\" and try again!"
		exit 1
	fi
}
_checkroot

function _reset_plait(){
    _info "Resetting PLAit..."
    [ -d /usr/local/PLAit ] && rm -rf /usr/local/PLAit
    [ ! -d /root/.pveinstall/log ] && mkdir -p /root/.pveinstall/log
    [ ! -d /root/.pveinstall/info ] && mkdir -p /root/.pveinstall/info
    [ -f /root/.pveinstall/log/install_plait.log ] && rm -rf /root/.pveinstall/log/install_plait.log
    [ -f /root/.pveinstall/info/PLAIT_INSTALLED ] && rm -rf /root/.pveinstall/info/PLAIT_INSTALLED
    _success "Reset finished."
}

function _backup_source_mirror_file(){
    _info "Backing up source mirror files..."
    source /etc/os-release
    cat << EOF > /etc/apt/sources.list.default
deb http://ftp.debian.org/debian $VERSION_CODENAME main contrib

deb http://ftp.debian.org/debian $VERSION_CODENAME-updates main contrib

# security updates
deb http://security.debian.org $VERSION_CODENAME-security main contrib
EOF

    cat << EOF > /etc/apt/sources.list.d/pve-enterprise.list.default
deb https://enterprise.proxmox.com/debian/pve $VERSION_CODENAME pve-enterprise
EOF

    [ -f /etc/apt/sources.list.d/pve-enterprise.list ] && rm -rf /etc/apt/sources.list.d/pve-enterprise.list
    _success "Backup finished."
}

function _test_network(){
    _info "Testing network connection. Up to 10 seconds..."
    if ! ping -c 5 -w 5 www.baidu.com >/dev/null 2>&1;then
        _success "Network available."
    elif ! ping -c 5 -w 5 www.google.com >/dev/null 2>&1;then
        _success "Network available."
    else
        _error "Network unavailable! Please check it first!"
        exit 1
    fi
}

function _test_country_name(){
    _info "Testing country name. Up to 20 seconds..."
    if locationInfo=$(curl -s -m 10 ipinfo.io/country 2>/dev/null); then
        _success "Country name: ${locationInfo}"
    elif locationInfo=$(curl -s -m 10 ifconfig.co/country 2>/dev/null); then
        _success "Country name: ${locationInfo}"
    else
        _error "Please contact and assist developers to add detection methods that can obtain the name of your country. Exiting..."
        exit 1
    fi
}

function _CN_setting(){
    source /etc/os-release && echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve $VERSION_CODENAME pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
    sed -i 's|http://ftp.debian.org|https://mirrors.ustc.edu.cn|;s|http://security.debian.org|https://mirrors.ustc.edu.cn/debian-security|' /etc/apt/sources.list
}

function _mod_source_mirror_files(){
    builtInCountry=("mainland China")
    case ${locationInfo} in
        "CN"|"China")
            _CN_setting
            ;;
        *)
            _warning "This operation is to replace the source mirrors of debian and pve to achieve the fastest download experience."
            _warning "If the default software source mirror of Proxmox cannot meet the normal software download requirements, "
            _warning "please provide the developer with the source mirror for the best experience in your country or region."
            _warning "The replace operation will now be skipped."
            _warning "Already built in for the following country or region:"
            for i in "${builtInCountry[@]}"; do
                _print "$i"
            done
    esac
}

function _upgrade_sys_and_ins_deps(){
    if ! apt update && apt install -y screen git net-tools sysfsutils ethtool dos2unix; then
        _error "Some errors occurred while upgrading the system or installing necessary dependencies!"
        _error "These error messages have been saved in this log:"
        _error "${LOG_FILE}"
        exit 1
    fi
}

function _install_plait(){
    case ${SOURCE_NAME} in
        "gitlab")
            SOURCE_LINK="https://gitlab.com/mylovesaber/PLAit.git"
            ;;
        "github")
            SOURCE_LINK="https://github.com/mylovesaber/PLAit.git"
            ;;
        *)
        :
    esac

    if ! git clone ${DEV} --depth=1 "${SOURCE_LINK}" /usr/local/PLAit; then
        _error "Some errors occurred while downloading PLAit!"
        _error "These error messages have been saved in this log:"
        _error "${LOG_FILE}"
        exit 1
    else
        _info "Converting file format..."
        dos2unix /usr/local/PLAit/plait.sh >>"${LOG_FILE}" 2>&1
        chmod +x /usr/local/PLAit/plait.sh
        _info "Adding PLAit as a system tool..."
        [ -f /usr/bin/plait ] && rm -rf /usr/bin/plait
        ln -s /usr/local/PLAit/plait.sh /usr/bin/plait
        [ -f /usr/bin/pla ] && rm -rf /usr/bin/pla
        ln -s /usr/local/PLAit/plait.sh /usr/bin/pla
    fi
}
##########################################################

if ! ARGS=$(getopt -a -o s:,d,l -l source_name:,dev,display_log -- "$@")
then
    _error "Invalid option"
    exit 1
elif [ "$1" == "-" ]; then
    _warning "Please enter correct options to run the project function!"
    exit 1
fi
eval set -- "${ARGS}"
while true; do
    case "$1" in
    -s | --source_name)
        if [[ "$2" =~ "github"|"gitlab" ]]; then
            SOURCE_NAME="$2"
        else
            _error "Wrong parameter!"
            _error "Available parameter: <github> or <gitlab>"
            exit 1
        fi
        shift
        ;;
    -d | --dev)
        DEV="--branch dev"
        ;;
    -l | --display_log)
        LOG=1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

_reset_plait
_backup_source_mirror_file
_test_network
_test_country_name | tee -ai "${LOG_FILE}" 2>&1
_mod_source_mirror_files

_info "Upgrading system and install dependencies..."
if [ ${LOG} == 1 ]; then
    _upgrade_sys_and_ins_deps | tee -ai "${LOG_FILE}" 2>&1
else
    _warning "Since you haven't turned on the function of displaying the detailed installation process,"
    _warning "it may take a long time here, please do not continue other operations, the system does not crash..."
    _upgrade_sys_and_ins_deps >> "${LOG_FILE}" 2>&1
fi
_success "Upgrading system and install dependencies finished"

_info "Installing PLAit..."
if [ ${LOG} == 1 ]; then
    _install_plait | tee -ai "${LOG_FILE}" 2>&1
else
    _install_plait >> "${LOG_FILE}" 2>&1
fi
_success "PLAit installation finished!"

touch ${INFO_SIGNAL}