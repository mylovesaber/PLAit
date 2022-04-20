#!/bin/bash
function _cpu_passthrough(){
_info "Starting CPU passthrough..."
if [ -f "${INFO_PATH}"/CPU_PASSTHROUGH_NOT_SUPPORT ]; then
    _warning "This CPU model doesn't support passthrough! Pass..."
    echo "===================================="
elif [ -f "${INFO_PATH}"/CPU_PASSTHROUGH_FINISHED ]; then
    _success "CPU passthrough finished! Pass..."
    echo "===================================="
else
    if ! grep -E '(vmx|svm)' /proc/cpuinfo > /dev/null 2>&1; then
        _error "This CPU does not support virtualization. Exiting..."
        touch "${INFO_PATH}"/CPU_PASSTHROUGH_NOT_SUPPORT
        echo "===================================="
        return 1
    else
        if dmesg | grep "IOMMU enabled" > /dev/null 2>&1; then
            _success "IOMMU enabled. Setting skipped..."
            echo "===================================="
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
                            echo "===================================="
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
                            echo "===================================="
                            return 1
                            ;;
                    esac
                else
                    _error "Unexpected behavior in grub when configuring"
                    echo "===================================="
                    return 1
                fi
                _info "Updating grub..."
                update-grub >>"${LOG_PATH}"/update_grub.log 2>&1
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
            _info "Updating kernel modules..."
            update-initramfs -k all -u >>"${LOG_PATH}"/update_initramfs.log 2>&1
        fi
        touch "${INFO_PATH}"/CPU_PASSTHROUGH_FINISHED
        _success "CPU passthrough configuration finished!"
        echo "===================================="
    fi
fi
}

function _checkcpu(){
_info "Checking CPU passthrough..."
if [ ! -f "${INFO_PATH}"/CPU_PASSTHROUGH_NOT_SUPPORT ] && [ ! -f "${INFO_PATH}"/CPU_PASSTHROUGH_FINISHED ]; then
    _warning "This CPU is not configured for passthrough, start configuring..."
    _warning "After the configuration is complete, please restart the host, and then run the check"
    _cpu_passthrough
    return 0
elif [ -f "${INFO_PATH}"/CPU_PASSTHROUGH_NOT_SUPPORT ]; then
    _warning "This CPU does not support virtualization and will skip passthrough in the future"
    echo "===================================="
    return 1
elif [ -f "${INFO_PATH}"/CPU_PASSTHROUGH_FINISHED ]; then
    if [[ "$(dmesg | grep 'remapping')" =~ "AMD-Vi: Interrupt remapping enabled"|"DMAR-IR: Enabled IRQ remapping in x2apic mode" ]]; then
        if [[ "$(find /sys/kernel/iommu_groups/ -type l)" =~ "/sys/kernel/iommu_groups" ]]; then
            _success "CPU passthrough success!"
            echo "===================================="
            touch "${INFO_PATH}"/CPU_PASSTHROUGH_yes
        elif [ -z "$(find /sys/kernel/iommu_groups/ -type l)" ]; then
            _error "CPU passthrough failed!"
            touch "${INFO_PATH}"/CPU_PASSTHROUGH_no
        else
            _error "An unexpected situation occurs, please check"
            find /sys/kernel/iommu_groups/ -type l
            echo "===================================="
            return 1
        fi
    else
        _error "CPU passthrough failed!"
        touch "${INFO_PATH}"/CPU_PASSTHROUGH_no
    fi
    if [ -f "${INFO_PATH}"/CPU_PASSTHROUGH_no ]; then
        _warning "All passthrough related configurations will be removed..."
        if [ -f /etc/modules.bak ]; then
            rm -rf /etc/modules
            mv /etc/modules.bak /etc/modules
        else
            sed -i '/vfio/d' /etc/modules
        fi
        _info "Updating kernel modules..."
        update-initramfs -k all -u >>"${LOG_PATH}"/update_initramfs.log 2>&1
        [ -f /etc/default/grub.bak ] && mv /etc/default/grub.bak /etc/default/grub
        _info "Updating grub..."
        update-grub >>"${LOG_PATH}"/update_grub.log 2>&1
        touch "${INFO_PATH}"/CPU_PASSTHROUGH_NOT_SUPPORT
        _success "All passthrough related configurations removed!"
        echo "===================================="
    fi
fi
}
