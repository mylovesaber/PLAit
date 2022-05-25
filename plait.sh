#!/bin/bash
ARGS=
update_source="default"
fix_update_problem=0
extand_root_partition=0
DNS_PROVIDER=
CPU_PASSTHROUGH=0
CPU_CHECK=0
GET_NIC_INFO=
REBOOT=0
MAIN_PATH="/var/log/plait"
LOG_PATH="/var/log/plait/log"
INFO_PATH="/var/log/plait/info"

# function _test_screen_when_exiting(){
# if ! dpkg -l | grep "screen" | grep -v "dtach"; then
#     exit
# fi
# testScreenResult=$(echo $STY >/tmp/testScreenResult 2>&1)
# if [ -z ${testScreenResult} ]; then
#     echo zero
# else
#     echo other
# fi
# }

#####################################################

# 此处文件夹名的检测指定为项目名称，不可更改
if [ ! -d /usr/local/PLAit ]; then
    tput setaf 1
    echo -e "PLAit unavailable! Please install it first! You can find the help information here:\n
    https://gitlab.com/mylovesaber/PLAit.git"
    tput sgr0
    exit 1
else
    export SOURCE_PATH="/usr/local/PLAit"
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

function _get_nic_info_start(){
    source "${SOURCE_PATH}"/pvemod/NetworkCheck.sh
    if [ ! -f "${INFO_PATH}"/NETWORK_CARD_INFO ]; then
        _warning "No saved NIC information file! Start collecting..."
        GET_NIC_INFO="update"
    fi
        _get_passthrough_network_card_info
}

function _modify_sysctl_start(){
    # 暂时不启用
    source "${SOURCE_PATH}"/pvemod/ModSysctl.sh
    _modify_sysctl
}

function _help_display(){
source "${SOURCE_PATH}"/help.sh
_help
}

if ! ARGS=$(getopt -a -o s:,f,d:,c,C,n:,r,h -l update_source:,fix_update_problem,extand,setdns:,cpu_passthrough,checkcpu,get_nic_info:,reboot,help -- "$@")
then
    _error "Invalid option, please read the usage:"
    _help_display
    exit 1
elif [ -z "$1" ]; then
    _warning "Please enter options to run the project function!"
    _warning "Here is the help information:"
    _help_display
    exit 1
elif [ "$1" == "-" ]; then
    _warning "Please enter correct options to run the project function!"
    _warning "Here is the help information:"
    _help_display
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
    -C | --checkcpu)
        CPU_CHECK=1
        ;;
    -n | --get_nic_info)
        if [[ "$2" =~ "update"|"display" ]]; then
            GET_NIC_INFO="$2"
        else
            _error "Wrong parameter!"
            _error "Available parameter: <update> or <display>"
            exit 1
        fi
        shift
        ;;
    -r | --reboot)
        REBOOT=1
        ;;
    -h | --help)
        _help_display
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