#!/bin/bash
function _modify_dns(){
_info "Modifying DNS..."
if [ ! -f /etc/resolv.conf.default ]; then
    cp -a /etc/resolv.conf /etc/resolv.conf.default
fi
cp -a /etc/resolv.conf /etc/resolv.conf.userbak
case "${DNS_PROVIDER}" in
    "ali")
        cat > /etc/resolv.conf << EOF
search lan
nameserver 223.5.5.5
nameserver 223.6.6.6
nameserver 2400:3200::1
nameserver 2400:3200:baba::1
EOF
    ;;
    "tencent")
        cat > /etc/resolv.conf << EOF
search lan
nameserver 119.29.29.29
nameserver 2402:4e00::
EOF
    ;;
    "baidu")
        cat > /etc/resolv.conf << EOF
search lan
nameserver 180.76.76.76
nameserver 2400:da00::6666
EOF
    ;;
    "114")
        cat > /etc/resolv.conf << EOF
search lan
nameserver 114.114.114.114
nameserver 114.114.115.115
EOF
    ;;
    "cloudflare")
        cat > /etc/resolv.conf << EOF
search lan
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
nameserver 2606:4700:4700::1001
EOF
    ;;
    "opendns")
        cat > /etc/resolv.conf << EOF
search lan
nameserver 208.67.222.222
nameserver 208.67.220.220
nameserver 2620:119:35::35
nameserver 2620:119:53::53
EOF
    ;;
    "google")
        cat > /etc/resolv.conf << EOF
search lan
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
EOF
    ;;
    "-h"|"--help")
        echo -e "\
        Optional parameters:\
        ali/tencent/baidu/114/cloudflare/opendns/google
        e.g.: source ./pve-install.sh -d google
        "
    ;;
    *)
        _error "Input wrong! Optional parameters:"
        _error "ali/tencent/baidu/114/cloudflare/opendns/google"
        exit 1
    ;;
esac

if [[ ! $(systemctl is-enabled systemd-resolved.service) == "enabled" ]]; then
    _warning "DNS service isn't set to auto-start. Setting to auto-start..."
    systemctl enable systemd-resolved.service >>/root/.pveinstall/log/enable_systemd-resolved.log 2>&1
    _success "DNS service has been set to start automatically"
fi
if [[ ! $(systemctl is-active systemd-resolved.service) == "active" ]]; then
    _warning "DNS service isn't started, starting..."
    systemctl start systemd-resolved.service
    _success "DNS service started"
fi
systemd-resolve --flush-caches
_success "DNS setup finished"
echo "===================================="
}