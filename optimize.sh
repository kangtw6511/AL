#!/bin/bash

# Update system and install required packages
sudo pacman -Syu
sudo pacman -S --noconfirm ibus ibus-hangul noto-fonts-cjk

# Configure Korean input method
gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'hangul')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['korean:ralt_hangul', 'korean:rctrl_hanja']"

# Configure font preferences
gsettings set org.gnome.desktop.interface font-name "Noto Sans CJK KR 10"
gsettings set org.gnome.desktop.interface document-font-name "Noto Sans CJK KR 10"
gsettings set org.gnome.desktop.interface monospace-font-name "Noto Sans Mono CJK KR 10"

# Configure swap space
sudo pacman -S --noconfirm systemd-swap
sudo systemctl enable --now systemd-swap.service
sudo sed -i "s/^#size = /size = $(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 2))M/" /etc/systemd/swap.conf

# Optimize system performance
sudo pacman -S --noconfirm intel-gpu-tools
sudo tee /etc/sysctl.d/99-sysctl.conf >/dev/null <<EOF
# TCP SYN Flood Attack Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_fin_timeout = 20

# Increase the maximum size of the receive and send buffers
net.core.rmem_max = 56623104
net.core.wmem_max = 56623104

# Optimize disk I/O performance
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Increase the maximum number of open files and processes
fs.file-max = 2097152
kernel.pid_max = 4194304

# Increase the maximum number of memory map areas per process
vm.max_map_count = 262144

# Enable transparent huge pages
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# Reduce kernel message log level
kernel.printk = 3 3 3 3

# Disable kernel modules not needed for your hardware
sudo tee /etc/modprobe.d/blacklist.conf >/dev/null <<EOF
blacklist floppy
blacklist pcspkr
EOF

# Set GPU performance profile to high
gpu_freq="$(sudo intel_gpu_top -o - | head -n 1 | awk '{print $1}')"
if [[ "$gpu_freq" == "3D/Media" ]]; then
    sudo intel_gpu_frequency --set-max=$(sudo intel_gpu_frequency_info | awk '/max/{print $4}')
    echo "GPU performance profile set to high."
else
    echo "GPU performance profile not set."
fi

echo "System optimization complete."

