function _modify_conf(){
if [[ -f /pveinstall/info/SYSCTL_MODIFIED ]]; then
    _warning "sysctl.conf �ļ����޸ģ�����..."
else
    cp -a /etc/sysctl.conf /etc/sysctl.conf.bak
    cat <<EOF >> /etc/sysctl.conf
net.ipv6.conf.all.accept_dad = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.all.accept_redirects = 1
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.all.autoconf = 1
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 0
EOF
    sysctl -p >/dev/null 2>&1
    _success "sysctl.conf ���޸�"
    systemctl stop rpcbind
    systemctl disable rpcbind
    systemctl mask rpcbind
    systemctl stop rpcbind.socket
    systemctl disable rpcbind.socket
    _success "rpcbind �ѽ���"
    touch /pveinstall/info/SYSCTL_MODIFIED
fi
}

if ! ARGS=$(getopt -a -o s:,f,i,d,n,c,r,h -l update_source:,fix_update_problem,info,dns,net_interfaces,cpu_passthrough,reboot,help,checkcpu -- "$@")
then
    _error "��Ч��ѡ�������: bash $0 -h �鿴�÷�"
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
	-i | --info)
		PRINT_INFO=1
		;;
	-d | --dns)
		DNS_PROVIDER="$2"
        shift
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

_prepare
_collect_info

if [[ "${CPU_CHECK}" == 1 ]] && { [[ "${INSTALL_PVE}" == 1 ]] || [[ "${MOD_NET_INTERFACES}" == 1 ]] || [[ "${CPU_PASSTHROUGH}" == 1 ]]; }; then
    _error "--checkcpu ���ܺ� --pve / --net_interfaces / --cpu_passthrough ѡ�����ʹ�ã���ɾ����Щѡ�������У�"
    exit 1
elif [[ "${CPU_CHECK}" == 1 ]]; then
    _checkcpu
fi

if [[ "${PRINT_INFO}" == 1 ]]; then
    _print_info
    exit 0
fi

if [[ "${INSTALL_PVE=}" == 1 ]]; then
    _install_pve
    _modify_conf
fi

[[ "${MOD_NET_INTERFACES}" == 1 ]] && _modify_interfaces
[[ "${CPU_PASSTHROUGH}" == 1 ]] && _cpu_passthrough

[[ "${REBOOT}" == 1 ]] && reboot
[[ "${PRINT_INFO}" == 0 ]] && [[ "${INSTALL_PVE}" == 0 ]] && [[ "${MOD_NET_INTERFACES}" == 0 ]] && [[ "${CPU_CHECK}" == 0 ]] && [[ "${CPU_PASSTHROUGH}" == 0 ]] && [[ "${REBOOT}" == 0 ]] && [[ "${HELP}" == 0 ]] && _warning "������ѡ����ʵ�����й���"
