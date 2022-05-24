# PVE Lightweight Automatic installation tool(PLAit)

>English version: [README](https://github.com/mylovesaber/PLAit/blob/dev/README_EN.md)
There is a little difference between English and Chinese version.

PLAit 是一个基于 PVE 虚拟化平台，面向家用网络环境条件的一键部署工具。目的是帮助新手在基于 PVE 虚拟化平台搭建家用软路由系统或 NAS 系统时节省大量时间精力，同时对于熟悉配置的用户而言也相对省心。

由于是基于本人日用需求，所以不会出现各种奇怪玩法。此处仅提供一键部署的全部选项，具体用法放 WIKI 教程中。

# 功能简介

- [x] 一键本地化调整（换源、命令行观感调整、常用软件安装）
- [x] 一键切换国内各家主流 DNS 服务
- [x] 一键去除订阅提示（理论上非大版本更新不会反弹）
- [x] 一键直通CPU、网卡、核显
- [ ] 一键扩容
- [x] 一键检测 PVE 管理口，以遍后续直通网卡时自动避开，防止失去远程控制（可以考虑把他改成首次使用此项目就自动检测？）
- [x] 一键修复错误直通管理口导致的 WEBUI 和 ssh 无法连接的问题(这功能好像可以做成定时自动检测，但首次启动的话需要人工启动，以后就自动启动，遇到问题就自动修复，但只能是基于此项目搭建的环境，与上一行的功能有关)
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
- [ ] 一键安装黑 qnap（不确定能不能成，优先级应该是最靠后的，和黑群晖一样都是个人用于测试未来开发的项目的兼容性用途，只是确认能开机能用命令行，不保证任何稳定性）
- [ ] 一键安装 truenas
- [ ] 一键安装 windows
- [ ] 一键安装 MacOS
- [ ] 一键配置家庭影音环境
- [ ] 把 WIKI 写好（这个没法一键...）

看能挤出多少时间了

![](https://img.wxcha.com/file/202006/02/d30107da13.jpg)

# 安装工具

2022年5月18日，码云（gitee）启动了代码审查机制，但凡不合规矩都可能被删除或阻止其他用户访问，且默认阻断匿名访问功能，鉴于本工具骨骼清奇，为了未来安全稳定所考虑，码云平台只作为该项目代码的备选平台。
经过测试，中国大陆大部分地区没有特殊手段无法打开 Github 网站，但基本都能打开 Gitlab，于是我设置成中国大陆用户默认从 Gitlab 获取工具源码。
不要有非 Github 不用的思想，我代码都是首先同步到 Gitlab，然后再由 Gitlab 自动同步到 Github上。

如果未来不小心删掉或修改了工具中的一些功能或代码，可以通过运行安装工具命令来强制重置。重装工具的操作不会影响到工具已经应用到系统中的任何功能。
以下四条命令根据注释内容介绍，四选一即可。

```bash
# 基于 gitlab （中国大陆用户最优先用这个）
# 隐藏详细输出信息（默认）
bash<(curl -Ls https://gitlab.com/api/v4/projects/36366519/repository/files/install.sh/raw?ref=main)

# 显示详细输出信息
bash<(curl -Ls https://gitlab.com/api/v4/projects/36366519/repository/files/install.sh/raw?ref=main) -l

#####################################################################################################
# 基于 github
# 隐藏详细输出信息（默认）
bash<(curl -Ls https://raw.githubusercontent.com/mylovesaber/PLAit/main/install.sh) -s github

# 显示详细输出信息
bash<(curl -Ls https://raw.githubusercontent.com/mylovesaber/PLAit/main/install.sh) -s github -l

```

安装完成后，在命令行直接输入命令： `plait` 或 `pla` 均可正常运行该工具。

# 运行工具

选项：

```bash
等写好再发
```

---

# 测试版

所有最新版本代码均推送到 dev 分支并直接运行以检查在线部署是否存在错误，所以事先没有在本地做除了语法正确性以外的任何测试，随时可能更新出一堆 bug 来，仅供我个人调试用，如果你不是开发者千万别用以下的选项。

```bash
# 基于 gitlab
# 隐藏详细输出信息（默认）
bash <(curl -Ls https://gitlab.com/api/v4/projects/36366519/repository/files/install.sh/raw?ref=dev) -d

# 显示详细输出信息
bash <(curl -Ls https://gitlab.com/api/v4/projects/36366519/repository/files/install.sh/raw?ref=dev) -dl

#####################################################################################################
# 基于 github
# 隐藏详细输出信息（默认）
bash <(curl -Ls https://raw.githubusercontent.com/mylovesaber/PLAit/dev/install.sh) -s github -d

# 显示详细输出信息
bash <(curl -Ls https://raw.githubusercontent.com/mylovesaber/PLAit/dev/install.sh) -s github -dl

```
