function _modify_conf(){
if [[ -f /pveinstall/info/SYSCTL_MODIFIED ]]; then
    _warning "sysctl.conf 文件已修改！跳过..."
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
    _success "sysctl.conf 已修改"
    systemctl stop rpcbind
    systemctl disable rpcbind
    systemctl mask rpcbind
    systemctl stop rpcbind.socket
    systemctl disable rpcbind.socket
    _success "rpcbind 已禁用"
    touch /pveinstall/info/SYSCTL_MODIFIED
fi
}

if ! ARGS=$(getopt -a -o s:,f,i,d,n,c,r,h -l update_source:,fix_update_problem,info,dns,net_interfaces,cpu_passthrough,reboot,help,checkcpu -- "$@")
then
    _error "无效的选项，请输入: bash $0 -h 查看用法"
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
    _error "--checkcpu 不能和 --pve / --net_interfaces / --cpu_passthrough 选项组合使用，请删除这些选项再运行！"
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
[[ "${PRINT_INFO}" == 0 ]] && [[ "${INSTALL_PVE}" == 0 ]] && [[ "${MOD_NET_INTERFACES}" == 0 ]] && [[ "${CPU_CHECK}" == 0 ]] && [[ "${CPU_PASSTHROUGH}" == 0 ]] && [[ "${REBOOT}" == 0 ]] && [[ "${HELP}" == 0 ]] && _warning "请输入选项以实际运行功能"
