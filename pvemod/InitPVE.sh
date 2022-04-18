#!/bin/bash
function _fix_system_upgrade(){
## auto solve lock
_info "Checking and performing updates to system... "
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update >/root/.pveinstall/log/upgrade_system.log 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade >>/root/.pveinstall/log/upgrade_system.log 2>&1
if [ "$?" -eq 2 ]; then
    _warning "dpkg database is locked."
    _info "fixing dpkg lock..."
    rm -f /var/lib/dpkg/updates/0*
    locks=$(find /var/lib/dpkg/lock* && find /var/cache/apt/archives/lock*)
    if [[ ${locks} == $(find /var/lib/dpkg/lock* && find /var/cache/apt/archives/lock*) ]]; then
        for l in ${locks}; do
            rm -rf "${l}"
        done
        dpkg --configure -a
        DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update >/root/.pveinstall/log/upgrade_system.log 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade >>/root/.pveinstall/log/upgrade_system.log 2>&1
    fi
    if ! (apt-get check >/dev/null); then
        apt-get install -f
        if ! (apt-get check >/dev/null); then
            exit 1
        fi
    fi
fi
}

function _init_pve(){
# 命令行可读性调整
if [ ! -f /root/.bashrc.default ]; then
    cp -a /root/.bashrc /root/.bashrc.default
else
    sed -i '/LS_OPTIONS/d' /root/.bashrc
    sed -i '/dircolors/d' /root/.bashrc
    sed -i '/PS1/d' /root/.bashrc
fi
cat >> /root/.bashrc << EOF
export LS_OPTIONS='--color=auto'
eval "\$(dircolors)"
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -l'
alias l='ls \$LS_OPTIONS -lA'
PS1='\${debian_chroot:+(\$debian_chroot)}\[\e[1;31m\]\u\[\e[1;33m\]@\[\e[1;36m\]\h \[\e[1;33m\]\w \[\e[1;35m\]\\$ \[\e[0m\]'
EOF
source /root/.bashrc

# 换源/清除 pve 的无订阅警告/更新版本
dpkg -i "${SOURCE_PATH}"/pvemod/deb/pve-fake-subscription_0.0.7_all.deb
sed -i '/maurer/d' /etc/hosts
echo "127.0.0.1 shop.maurer-it.com" >> /etc/hosts
# #以下方法每次版本更新的时候就会失效，暂时屏蔽
# if [[ $(pveversion -v | grep "proxmox-ve" | awk '{print $2}' | cut -d'-' -f1) == "7.1" ]]; then
#     sed -i.backup -z "s/res === null || res === undefined || \!res || res\n\t\t\t.data.status.toLowerCase() \!== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
#     systemctl daemon-reload
#     systemctl restart pveproxy.service
# fi

source /etc/os-release
if [ "${update_source}" == "default" ]; then
    echo "deb http://download.proxmox.com/debian/pve $VERSION_CODENAME pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
elif [ "${update_source}" == "china" ]; then
    echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve $VERSION_CODENAME pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
    if [ ! -f /usr/share/perl5/PVE/APLInfo.pm.default ]; then
        cp -a /usr/share/perl5/PVE/APLInfo.pm /usr/share/perl5/PVE/APLInfo.pm.default
    fi
    sed -i 's|http://download.proxmox.com|https://mirrors.ustc.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
    if [ ! -f /etc/apt/sources.list.default ]; then
        cp -a /etc/apt/sources.list /etc/apt/sources.list.default
    fi
    sed -i 's|^deb http://ftp.debian.org|deb https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list
    sed -i 's|^deb http://security.debian.org|deb https://mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list
else
    _error "Input wrong! Optional parameters: default/china. Default parameters: \"default\""
    exit 1    
fi
rm -f /etc/apt/sources.list.d/pve-enterprise.list

_info "Checking and performing updates to system... "
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update >/root/.pveinstall/log/upgrade_system.log 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade >>/root/.pveinstall/log/upgrade_system.log 2>&1
apt install -y net-tools qemu-guest-agent jq

if [ $? == 0 ]; then
    touch /root/.pveinstall/info/INITIALIZE_FINISHED
    _success "PVE initialized. If you want to re-initialize,"
    _success "run this command and re-run the project:"
    _print "rm -rf /root/.pveinstall/info/INITIALIZE_FINISHED"
fi
}