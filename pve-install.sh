#!/bin/bash
ARGS=
update_source="default"
fix_update_problem=0
extand_root_partition=0
DNS_PROVIDER=
CPU_PASSTHROUGH=0
CPU_CHECK=0
REBOOT=0

if [ ! -d /root/.pveinstall/info ]; then
    mkdir -p /root/.pveinstall/info
fi
if [ ! -d /root/.pveinstall/log ]; then
    mkdir -p /root/.pveinstall/log
fi

LOG_PATH="/root/.pveinstall/log"
INFO_PATH="/root/.pveinstall/info"

#####################################################

# 此处文件夹名的检测指定为项目名称，不可更改
if [ "$(basename "$PWD")" != "pve-home-autoinstall" ]; then
    tput setaf 1
    echo -e "Wrong path! Please run it from the root path of this project. E.g.:\n
    cd /root/pve-home-autoinstall"
    tput sgr0
    exit 1
else
    export SOURCE_PATH="$PWD"
    source "${SOURCE_PATH}"/color.sh
fi

if [[ $EUID -ne 0 ]]; then
    _error "Root privileges are required to perform this operation"
    exit 1
fi

#####################################################

function _init_pve_start(){
    source "${SOURCE_PATH}"/pvemod/InitPVE.sh
    if [ ! -f "${INFO_PATH}"/INITIALIZE_FINISHED ]; then
        if _init_pve; then
            _success "PVE initialized. If you want to re-initialize,"
            _success "run this command and re-run the project:"
            _print "rm -rf ${INFO_PATH}/INITIALIZE_FINISHED"
            touch "${INFO_PATH}"/INITIALIZE_FINISHED
            echo "===================================="
        else
            _error "PVE initializing failed! The log files were saved in:"
            _error "${LOG_PATH}/upgrade_system.log"
            _error "${LOG_PATH}/install_fake-subscription.log"
            _error "${LOG_PATH}/install_necessary_packages.log"
            exit 1
        fi
    else
        _success "PVE initialized. Skipping..."
        echo "===================================="
    fi

    if [ "${fix_update_problem}" == 1 ]; then
        if _fix_system_upgrade; then
            _success "Update problem fixed!"
            echo "===================================="
        else
            _error "Fixing update problem failed! The log file was saved in ${LOG_PATH}/upgrade_system.log"
            exit 1
        fi
    fi

    if [ "${extand_root_partition}" == 1 ]; then
        if [ ! -f "${INFO_PATH}"/EXPAND_FINISHED ]; then
            if _expand_root_partition; then
                _success "Root partition expanded!"
                touch "${INFO_PATH}"/EXPAND_FINISHED
                echo "===================================="
            else
                _error "Root partition expand failed! The log file was saved in ${LOG_PATH}/expand_root_partition.log"
                exit 1
            fi
        else
            _success "Root partition expanded. Skipping..."
            echo "===================================="
        fi
    fi
}

function _modify_dns_start(){
    source "${SOURCE_PATH}"/pvemod/DNSSwitch.sh
    _modify_dns
}

function _cpu_passthrough_start(){
    source "${SOURCE_PATH}"/pvemod/CPUPassthrough.sh
    if [ "${CPU_PASSTHROUGH}" == 1 ]; then
        _cpu_passthrough
    elif [ "${CPU_CHECK}" == 1 ]; then
        _checkcpu
    fi
}

function _help(){
    echo "This is a pending help message..."
}

if ! ARGS=$(getopt -a -o s:,f,d:,c,r,h -l update_source:,fix_update_problem,extand,setdns:,cpu_passthrough,checkcpu,reboot,help -- "$@")
then
    _error "Invalid option, please run the following command to check usage:"
    _error "source $0 -h"
    _help
    exit 1
elif [ -z "$1" ]; then
    _warning "Please enter options to run the project function!"
    _warning "Here is the help information:"
    _help
    exit 1
elif [ "$1" == "-" ]; then
    _warning "Please enter correct options to run the project function!"
    _warning "Here is the help information:"
    _help
    exit 1
fi
eval set -- "${ARGS}"
while true; do
    case "$1" in
    -s | --update_source)
        update_source="$2"
        shift
        ;;
    -f | --fix_update_problem)
        fix_update_problem=1
        ;;
    --extand)
        extand_root_partition=1
        ;;
    -d | --setdns)
        DNS_PROVIDER="$2"
        shift
        ;;
    -c | --cpu_passthrough)
        CPU_PASSTHROUGH=1
        ;;
    --checkcpu)
        CPU_CHECK=1
        ;;
    -r | --reboot)
        REBOOT=1
        ;;
    -h | --help)
        HELP=1
        _help
        exit 0
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

# Main
_init_pve_start

if [ "${CPU_CHECK}" == 1 ] && [ "${CPU_PASSTHROUGH}" == 1 ]; then
    _error "<--checkcpu> cannot be combined with <--cpu_passthrough> option!"
    _error "Please remove one of these options and run this project!"
    _error "Exit..."
    sleep 3
    exit 1
fi

[ -n "${DNS_PROVIDER}" ] && _modify_dns_start

{ [ "${CPU_PASSTHROUGH}" == 1 ] || [ "${CPU_CHECK}" == 1 ]; } && _cpu_passthrough_start

[ "${REBOOT}" == 1 ] && reboot