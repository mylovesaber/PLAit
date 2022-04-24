#!/bin/bash

function _get_passthrough_network_card_info(){
if ! "$(dpkg -l | grep -q sysfsutils)"; then apt install -y sysfsutils; fi

if [ "${GET_NIC_INFO}" == "update" ]; then
    systool -c net | awk '/Class\ Device/{getline a;print $0,a}' | sed -e 's/Class Device/net_name/g' -e 's/Device/\|net_id/g' -e 's/[ ][ ]*//g' -e 's/\"//g' -e 's/$/\|/g' | grep "net_id" > "${INFO_PATH}"/NETWORK_CARD_INFO
    net_name=$(< "${INFO_PATH}"/NETWORK_CARD_INFO awk -F '\|' '{print $1}' | cut -d'=' -f2)
    for name in ${net_name}; do
        ether_to_add=$(ifconfig "${name}" | grep ether | awk '{print $2}')
        sed -i "/${name}/s/$/ether=${ether_to_add}/g" "${INFO_PATH}"/NETWORK_CARD_INFO
    done
    management_nic_ip=$(< /etc/issue grep "https" | awk -F '/' '{print $3}' | cut -d':' -f1)
    management_nic_name=$(brctl show | grep "vmbr0" | awk '{print $4}')
    management_nic_name_check=$(grep "bridge-ports" /etc/network/interfaces | awk '{print $2}')
    if [[ ${management_nic_name} == ${management_nic_name_check} ]]; then
        sed -i "/${management_nic_name}/s/$/management_nic/g" "${INFO_PATH}"/NETWORK_CARD_INFO
        echo "management_nic_ip=${management_nic_ip}" >> "${INFO_PATH}"/NETWORK_CARD_INFO
        cat "${INFO_PATH}/NETWORK_CARD_INFO"
    else
        _error "Unable to identify management NIC. Please see the log file by running this command:"
        _error "cat ${LOG_PATH}/get_nic_info.log"
        {
            echo "bridge info"
            brctl show
            echo -e "\n\ninterfaces info"
            cat /etc/network/interfaces
        } > "${LOG_PATH}/get_nic_info.log" 2>&1
        return 1
    fi
elif [ "${GET_NIC_INFO}" == "display" ]; then
    cat "${INFO_PATH}/NETWORK_CARD_INFO"
else
    _error "Wrong parameter!"
    _error "Available parameter: <update> or <display>"
    return 1
fi
}

