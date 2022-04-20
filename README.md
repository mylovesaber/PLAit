# PVE Lightweight Automatic installation tool(PLAit)

>English version: [README](https://github.com/mylovesaber/PLAit/blob/main/README_EN.md)

PLAit ��һ������ PVE ���⻯ƽ̨������������绷��������һ�����𹤾ߡ�Ŀ���ǰ��������ڻ��� PVE ���⻯ƽ̨�������·��ϵͳ�� NAS ϵͳʱ��ʡ����ʱ�侫����ͬʱ������Ϥ���õ��û�����Ҳ���ʡ�ġ�

�����ǻ��ڱ��������������Բ�����ָ�������淨���˴����ṩһ�������ȫ��ѡ������÷��� WIKI �̳��С�

# ����

- [*] CPU������������ֱͨ
- [*] ���ػ���������Դ�������й۸е��������������װ��
- [*] һ���л����ڸ������� DNS ����
- [*] ȥ��������ʾ�������ϷǴ�汾���²��ᷴ������
- [] ���� PVE �������ʾ��Ӳ�̡�CPU���¶ȣ�CPUƵ��
- [] ����ֱͨ����ʱû�Կ����ԡ�������
- [] һ������ϵͳ���������õĹ��ߣ����ֻ��� PVE ͼ�ν����ħ���ڸ��º�һ��ᶪȥ���Ķ���ʾ����֮������ã�
- [] һ���л��ڰ���Ĭ������ģʽ(����)
- [] һ����װ SSL ֤��
- [] һ����װ openwrt�����ƻ���������������ֱͨ�Ͷ���������ֱͨ�����汾�ɣ�ϵͳ���������� iStoreOS���ѷ����ˣ����� openwrt �� root ������һ���������и�ͷ��
- [] һ����ð���Ԥ��װ��������Դϵͳֻ�ܴ����÷�ֱͨ��������������ã���װϵͳ�����������̵̳�ʱ��� WIKI �ɣ�
- [] һ����� IPV4 ����ȫ����(��ʱû�������������)
- [] һ����� IPV6 ����ȫ����
- [] һ����ô� IPV4 ���ʴ� IPV6 ���� NAS����·�ɵ�ϵͳ����
- [] һ����װ��Ⱥ��
- [] һ����װ�� qnap����ȷ���ܲ��ܳɣ����ȼ�Ӧ�������ģ�
- [] һ����װ truenas
- [] һ����װ windows
- [] һ����װ MacOS
- [] һ�����ü�ͥӰ������
- [] �� WIKI д��

���ܼ�������ʱ����

![](https://img.wxcha.com/file/202006/02/d30107da13.jpg)

# ׼������

�����û��򲻿� Github ��վ�����������������û��� Gitee(�� Github ͬ�������þ������ĸ�)�����ڱ���Ŀһ��ʹ�� source ���У����Է�ֹ�����������ʱ�ն˱��رգ����������б���Ŀǰ��һ���Ƚ��� screen ��̨��`screen -S pve`�����������Ŀ�ĸ�Ŀ¼�£������������һ�������С�

```bash
source /etc/os-release && echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve $VERSION_CODENAME pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
cp -a /etc/apt/sources.list /etc/apt/sources.list.default
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak
sed -i 's|http://ftp.debian.org|https://mirrors.ustc.edu.cn|;s|http://security.debian.org|https://mirrors.ustc.edu.cn/debian-security|' /etc/apt/sources.list
apt update && apt install -y screen git net-tools
# git clone --depth=1 -b dev https://gitee.com/mylovesaber/PLAit.git && cd PLAit; screen -S pve
git clone --depth=1 https://gitee.com/mylovesaber/PLAit.git && cd PLAit; screen -S pve
```

# ������Ŀ

ѡ�

```bash
��д���ٷ�
```