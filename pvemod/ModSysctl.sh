#!/bin/bash
function _modify_sysctl(){
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
    touch /pveinstall/info/SYSCTL_MODIFIED
fi
}