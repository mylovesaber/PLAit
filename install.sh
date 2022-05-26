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
LOG_FILE="/var/log/plait/log/install_plait.log"
INFO_SIGNAL="/var/log/plait/info/PLAIT_INSTALLED"
locationInfo=""
SOURCE_NAME="gitlab"
SOURCE_LINK=""
DEV=""
LOG=0
source /etc/os-release

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
    [ ! -d /var/log/plait/log ] && mkdir -p /var/log/plait/log
    [ ! -d /var/log/plait/info ] && mkdir -p /var/log/plait/info
    [ -f /var/log/plait/log/install_plait.log ] && rm -rf /var/log/plait/log/install_plait.log
    [ -f /var/log/plait/info/PLAIT_INSTALLED ] && rm -rf /var/log/plait/info/PLAIT_INSTALLED
    _success "Finished."
}

function _backup_source_mirror_file(){
    _info "Backing up source mirror files..."
    cat << EOF > /etc/apt/sources.list.bak
deb http://ftp.debian.org/debian $VERSION_CODENAME main contrib

deb http://ftp.debian.org/debian $VERSION_CODENAME-updates main contrib

# security updates
deb http://security.debian.org $VERSION_CODENAME-security main contrib
EOF

    cat << EOF > /etc/apt/sources.list.d/pve-enterprise.list.bak
deb https://enterprise.proxmox.com/debian/pve $VERSION_CODENAME pve-enterprise
EOF

    [ -f /etc/apt/sources.list.d/pve-enterprise.list ] && rm -rf /etc/apt/sources.list.d/pve-enterprise.list
    [ -f /etc/apt/sources.list ] && rm -rf /etc/apt/sources.list
    _success "Finished."
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

function _CN_setting(){
    sed -i 's|http://ftp.debian.org|https://mirrors.ustc.edu.cn|;s|http://security.debian.org|https://mirrors.ustc.edu.cn/debian-security|;s|http://download.proxmox.com|https://mirrors.ustc.edu.cn/proxmox|' /etc/apt/sources.list
    [ ! -f /usr/share/perl5/PVE/APLInfo.pm_back ] && cp -a /usr/share/perl5/PVE/APLInfo.pm /usr/share/perl5/PVE/APLInfo.pm_back
    sed -i 's|http://download.proxmox.com|https://mirrors.ustc.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
    systemctl restart pvedaemon.service
}

function _mod_source_mirror_files(){
    _info "Adding all official source mirrors (e.g. ceph function)..."
    cat << EOF > /etc/apt/sources.list
deb http://ftp.debian.org/debian $VERSION_CODENAME main contrib
deb http://ftp.debian.org/debian $VERSION_CODENAME-updates main contrib
deb http://security.debian.org $VERSION_CODENAME-security main contrib
deb http://download.proxmox.com/debian/ceph-pacific $VERSION_CODENAME main
deb http://download.proxmox.com/debian/ceph-octopus $VERSION_CODENAME main
deb http://download.proxmox.com/debian/pve $VERSION_CODENAME pve-no-subscription
EOF
    _success "Finished."
    _info "Testing country name. Up to 20 seconds..."
    if locationInfo=$(curl -s -m 10 ipinfo.io/country 2>/dev/null); then
        _success "Country/Region name: ${locationInfo}"
    elif locationInfo=$(curl -s -m 10 ifconfig.co/country 2>/dev/null); then
        _success "Country/Region name: ${locationInfo}"
    else
        _error "Please contact and assist developers to add detection methods that can obtain the name of your country or region. Exiting..."
        exit 1
    fi
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
        _error "Some errors occurred while updating the system or installing necessary dependencies!"
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
_mod_source_mirror_files

_info "Updating source mirror and install dependencies..."
if [ ${LOG} == 1 ]; then
    _upgrade_sys_and_ins_deps | tee -ai "${LOG_FILE}" 2>&1
else
    _warning "Since you haven't turned on the function of displaying the detailed installation process,"
    _warning "it may take a long time here, please do not continue other operations, the system does not crash..."
    _upgrade_sys_and_ins_deps >> "${LOG_FILE}" 2>&1
fi
_success "Finished"

_info "Installing PLAit..."
if [ ${LOG} == 1 ]; then
    _install_plait | tee -ai "${LOG_FILE}" 2>&1
else
    _install_plait >> "${LOG_FILE}" 2>&1
fi
_success "PLAit installation finished!"

touch ${INFO_SIGNAL}