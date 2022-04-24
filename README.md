# PVE Lightweight Automatic installation tool(PLAit)

>English version: [README](https://github.com/mylovesaber/PLAit/blob/dev/README_EN.md)
There is a little difference between English and Chinese version.

PLAit 是一个基于 PVE 虚拟化平台，面向家用网络环境条件的一键部署工具。目的是帮助新手在基于 PVE 虚拟化平台搭建家用软路由系统或 NAS 系统时节省大量时间精力，同时对于熟悉配置的用户而言也相对省心。

由于是基于本人日用需求，所以不会出现各种奇怪玩法。此处仅提供一键部署的全部选项，具体用法放 WIKI 教程中。

# 功能

- [x] 一键本地化调整（换源、命令行观感调整、常用软件安装）
- [x] 一键切换国内各家主流 DNS 服务
- [x] 一键去除订阅提示（理论上非大版本更新不会反弹）
- [x] 一键直通CPU、网卡、核显
- [ ] 一键扩容
- [ ] 一键直通网卡时自动避开 PVE 管理口防止失去远程控制
- [ ] 一键修改 WEBUI 管理口的 IP 和 设备连接屏幕显示的 WEBUI 网页地址（PLAit 检测网卡的功能依赖这个文件）
- [ ] 一键增加 PVE 界面可显示的硬盘、CPU的温度，CPU频率
- [ ] 一键独显直通（暂时没显卡测试。。。）
- [ ] 一键更新系统但不丢配置的工具（部分基于 PVE 图形界面的魔改在更新后一般会丢去订阅丢显示功能之类的配置）
- [ ] 一键切换黑暗和默认明亮模式(待测)
- [ ] 一键安装 SSL 证书
- [ ] 一键安装 openwrt（估计会做单网口主机非直通和多网口主机直通两个版本吧，系统个人倾向用 iStoreOS，已发布了，基于 openwrt 有 root 有新手一键方案，有搞头）
- [ ] 一键配好爱快预安装环境（闭源系统只能创建好非直通网卡的虚拟机配置，安装系统和增减网卡教程到时候放 WIKI 吧）
- [ ] 一键配好 IPV4 公网全反代(暂时没这个环境。。。)
- [ ] 一键配好 IPV6 公网全反代
- [ ] 一键配好纯 IPV4 访问纯 IPV6 公网 NAS、软路由等系统功能
- [ ] 一键安装黑群晖
- [ ] 一键安装黑 qnap（不确定能不能成，优先级应该是最靠后的）
- [ ] 一键安装 truenas
- [ ] 一键安装 windows
- [ ] 一键安装 MacOS
- [ ] 一键配置家庭影音环境
- [ ] 把 WIKI 写好（这个没法一键...）

看能挤出多少时间了

![](https://img.wxcha.com/file/202006/02/d30107da13.jpg)

# 准备工作

假设用户打不开 Github 网站，所以以下所有配置基于 Gitee(与 Github 同步，不用纠结用哪个)。由于本项目一律使用 source 运行，所以防止出现意外情况时终端被关闭，后续再运行本项目前请一律先进入 screen 后台（`screen -S pve`）并进入该项目的根目录下，下面的命令请一行行运行。

```bash
source /etc/os-release && echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve $VERSION_CODENAME pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
cp -a /etc/apt/sources.list /etc/apt/sources.list.default
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak
sed -i 's|http://ftp.debian.org|https://mirrors.ustc.edu.cn|;s|http://security.debian.org|https://mirrors.ustc.edu.cn/debian-security|' /etc/apt/sources.list
apt update && apt install -y screen git net-tools sysfsutils
# git clone --depth=1 -b dev https://gitee.com/mylovesaber/PLAit.git && cd PLAit; screen -S pve
git clone -b dev --depth=1 https://gitee.com/mylovesaber/PLAit.git && cd PLAit; screen -S pve
```

# 运行项目

选项：

```bash
等写好再发
```