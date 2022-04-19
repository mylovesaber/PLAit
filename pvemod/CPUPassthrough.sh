#!/bin/bash
function _cpu_passthrough(){
if [ -f /root/.pveinstall/info/CPU_PASSTHROUGH_NOT_SUPPORT ]; then
    _warning "This CPU model doesn't support passthrough! Pass..."
elif [ -f /root/.pveinstall/info/CPU_PASSTHROUGH_FINISHED ]; then
    _warning "CPU passthrough finished! Pass..."
else
    if ! grep -E '(vmx|svm)' /proc/cpuinfo > /dev/null 2>&1; then
        _error "This CPU does not support virtualization. Exiting..."
        touch /root/.pveinstall/info/CPU_PASSTHROUGH_NOT_SUPPORT
        return 1
    else
        if dmesg | grep "IOMMU enabled" > /dev/null 2>&1; then
            _success "IOMMU enabled. Setting skipped..."
        else
            if [ -z "$(grep "iommu=on" /etc/default/grub)" ];then
                cp -af /etc/default/grub /etc/default/grub.bak
                if [[ "$(grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub)" =~ "quiet" ]]; then
                    case "$(grep -E '(vmx|svm)' /proc/cpuinfo)" in
                        "vmx")
                            sed -i "$(grep -n "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | cut -d':' -f1) s/\"$/ intel_iommu=on iommu=pt\"/g" /etc/default/grub
                            ;;
                        "svm")
                            sed -i "$(grep -n "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | cut -d':' -f1) s/\"$/ amd_iommu=on iommu=pt\"/g" /etc/default/grub
                            ;;
                        *)
                            _error "CPU type not recognized!"
                            return 1
                            ;;
                    esac
                elif [[ ! "$(grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub)" =~ "quiet" ]]; then
                    case "$(grep -E '(vmx|svm)' /proc/cpuinfo)" in
                        "vmx")
                            sed -i "$(grep -n "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | cut -d':' -f1) s/\"$/ quiet intel_iommu=on iommu=pt\"/g" /etc/default/grub
                            ;;
                        "svm")
                            sed -i "$(grep -n "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | cut -d':' -f1) s/\"$/ quiet amd_iommu=on iommu=pt\"/g" /etc/default/grub
                            ;;
                        *)
                            _error "CPU type not recognized!"
                            return 1
                            ;;
                    esac
                else
                    _error "Unexpected behavior in grub when configuring"
                    return 1
                fi
                update-grub
            fi
        fi
        if ! grep "vfio" /etc/modules > /dev/null 2>&1; then
            cp -a /etc/modules /etc/modules.bak
            {
                echo "vfio"
                echo "vfio_iommu_type1"
                echo "vfio_pci"
                echo "vfio_virqfd"
            } >> /etc/modules
            [ -f /etc/kernel/postinst.d/zz-update-grub ] && mv /etc/kernel/postinst.d/zz-update-grub /etc/kernel/postinst.d/zz-update-grub.bak
            update-initramfs -k all -u
        fi
        touch /root/.pveinstall/info/CPU_PASSTHROUGH_FINISHED
        _success "CPU passthrough configuration finished!"
    fi
fi
}

function _checkcpu(){
if [ ! -f /root/.pveinstall/info/CPU_PASSTHROUGH_NOT_SUPPORT ] && [ ! -f /root/.pveinstall/info/CPU_PASSTHROUGH_FINISHED ]; then
    _warning "This CPU is not configured for passthrough, start configuring..."
    _warning "After the configuration is complete, please restart the host, and then run the check"
    _cpu_passthrough
    return 0
elif [ -f /root/.pveinstall/info/CPU_PASSTHROUGH_NOT_SUPPORT ]; then
    _warning "This CPU does not support virtualization and will skip passthrough in the future"
    return 1
elif [ -f /root/.pveinstall/info/CPU_PASSTHROUGH_FINISHED ]; then
    if [[ "$(dmesg | grep 'remapping')" =~ "AMD-Vi: Interrupt remapping enabled"|"DMAR-IR: Enabled IRQ remapping in x2apic mode" ]]; then
        if [[ "$(find /sys/kernel/iommu_groups/ -type l)" =~ "/sys/kernel/iommu_groups" ]]; then
            _success "CPU passthrough success!"
            touch /root/.pveinstall/info/CPU_PASSTHROUGH_yes
        elif [ -z "$(find /sys/kernel/iommu_groups/ -type l)" ]; then
            _error "CPU passthrough failed!"
            touch /root/.pveinstall/info/CPU_PASSTHROUGH_no
        else
            _warning "An unexpected situation occurs, please check"
            find /sys/kernel/iommu_groups/ -type l
            return 1
        fi
    else
        _error "CPU passthrough failed!"
        touch /root/.pveinstall/info/CPU_PASSTHROUGH_no
    fi
    if [ -f /root/.pveinstall/info/CPU_PASSTHROUGH_no ]; then
        _error "All passthrough related configurations will be removed..."
        if [ -f /etc/modules.bak ]; then
            rm -rf /etc/modules
            mv /etc/modules.bak /etc/modules
        else
            sed -i '/vfio/d' /etc/modules
        fi
        update-initramfs -k all -u
        [ -f /etc/default/grub.bak ] && mv /etc/default/grub.bak /etc/default/grub
        update-grub
        touch /root/.pveinstall/info/CPU_PASSTHROUGH_NOT_SUPPORT
    fi
fi
}
