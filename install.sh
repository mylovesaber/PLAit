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
# function

function _checkroot() {
	if [[ $EUID != 0 ]]; then
        _error "Do not have root previlage, Please run \"sudo su -\" and try again!"
		exit 1
	fi
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
echo "Testing country name. Up to 20 seconds..."
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

##########################################################
_checkroot

[ -d /usr/local/PLAit ] && rm -rf /usr/local/PLAit
[ -f /root/.pveinstall/log/install_plait.log ] && rm -rf /root/.pveinstall/log/install_plait.log
[ ! -d /root/.pveinstall/log ] && mkdir -p /root/.pveinstall/log

LOG_PATH="/root/.pveinstall/log"
SOURCE_NAME="gitlab"
SOURCE_LINK=""
DEV=""
LOG=0

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
        DEV="-b dev"
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

_test_network
_test_country_name | tee -ai "${LOG_PATH}"/install_plait.log

builtInCountry=("mainland China")
[ ! -f /etc/apt/sources.list.default ] && cp -a /etc/apt/sources.list /etc/apt/sources.list.default
[ ! -f /etc/apt/sources.list.d/pve-enterprise.list.default ] && mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.default
case ${locationInfo} in
    "CN"|"China")_CN_setting;;
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

_info "Upgrading system and install dependencies..." | tee -ai "${LOG_PATH}"/install_plait.log
if [ ${LOG} == 1 ]; then
    apt update | tee -ai "${LOG_PATH}"/install_plait.log
    apt install -y screen git net-tools sysfsutils ethtool dos2unix | tee -ai "${LOG_PATH}"/install_plait.log
else
    _warning "Since you have not turned on the function of displaying the detailed installation process,"
    _warning "it may take a long time here, please do not continue other operations, the system does not crash..."
    apt update >> "${LOG_PATH}"/install_plait.log
    apt install -y screen git net-tools sysfsutils ethtool dos2unix >> "${LOG_PATH}"/install_plait.log
fi

if [ $? != 0 ]; then
    _error "Some errors occurred while upgrading the system or installing necessary dependencies!"
    _error "These error messages have been saved in this log:"
    _error "${LOG_PATH}/install_plait.log"
else
    _success "Finished"
fi

if [ "${SOURCE_NAME}" == "gitlab" ]; then
    SOURCE_LINK="https://gitlab.com/mylovesaber/PLAit.git"
elif [ "${SOURCE_NAME}" == "gitlab" ]; then
    SOURCE_LINK="https://github.com/mylovesaber/PLAit.git"
fi

_info "Downloading PLAit..."
if [ ${LOG} == 1 ]; then
    git clone "${DEV}" --depth=1 "${SOURCE_LINK}" /usr/local | tee -ai "${LOG_PATH}"/install_plait.log
else
    git clone "${DEV}" --depth=1 "${SOURCE_LINK}" /usr/local >> "${LOG_PATH}"/install_plait.log 2>&1
fi

if [ $? != 0 ]; then
    _error "Some errors occurred while downloading PLAit!"
    _error "These error messages have been saved in this log:"
    _error "${LOG_PATH}/install_plait.log"
else
    _info "Converting file format..."
    dos2unix /usr/local/PLAit/plait.sh 1>/dev/null 2>"${LOG_PATH}"/install_plait.log
    _info "Adding PLAit as a system tool..."
    [ -f /usr/bin/plait ] && rm -rf /usr/bin/plait
    ln -s /usr/local/PLAit/plait.sh /usr/bin/plait
    [ -f /usr/bin/pla ] && rm -rf /usr/bin/pla
    ln -s /usr/local/PLAit/plait.sh /usr/bin/pla
    _success "PLAit installation finished!"
fi