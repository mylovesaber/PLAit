# PVE Lightweight Automatic installation tool(PLAit)

PLAit is a one-click deployment tool for system construction in home network environment based on PVE virtualization platform. 
It can help anyone to complete the construction process of home soft router or home NAS with almost no time and effort.


# preparation

Since this project always run by source command, in order to prevents the terminal from being closed in case of unexpected situations. Before running this project, please enter the background using screen or other tools (`screen -S pve`) and enter the root directory of this project. Please run the following commands line by line.

```bash
source /etc/os-release && echo "deb http://download.proxmox.com/debian/pve $VERSION_CODENAME pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak
apt update && apt install -y screen git net-tools
# git clone --depth=1 -b dev https://github.com/mylovesaber/PLAit.git && cd PLAit; screen -S pve
git clone --depth=1 https://github.com/mylovesaber/PLAit.git && cd PLAit; screen -S pve
```

# Options

```bash
****
```