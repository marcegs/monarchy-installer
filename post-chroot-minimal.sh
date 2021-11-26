#!/bin/bash

function set_timesone() {
    ln -sf $1 /etc/localtime
    hwclock --systohc
}
function set_localization() {
    sed -i "s/#$1/$1/g" /etc/locale.gen
    locale-gen
    echo "LANG=$1" >/etc/locale.conf
    echo "KEYMAP=$2" >/etc/vconsole.conf
}
function configure_network() {
    pacman -S networkmanager --noconfirm --needed

    echo "$1" >/etc/hostname
    echo "127.0.0.1        localhost
::1              localhost
127.0.1.1        $1" >/etc/hosts
    systemctl enable NetworkManager
}
function create_initramfs() {
    if [ $7 = "True" ]; then
        sed -i "s/block filesystems/block encrypt btrfs filesystems/g" /etc/mkinitcpio.conf
    else
        sed -i "s/block filesystems/block btrfs filesystems/g" /etc/mkinitcpio.conf
    fi
    mkinitcpio -p linux
}
function set_root_password() {
    echo root:$1 | chpasswd # change root password

    useradd -m -G wheel $2 # wheel group for sudo
    echo $2:$1 | chpasswd  # change user password

    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers # make so users of the wheel group can run sudo
}
function configure_bootloader() {
    if [ $1 = "True" ]; then
        if [ $3 = "True" ]; then
            uuid=$(blkid | grep /dev/$2'3' | awk '{print $2}')
        else
            uuid=$(blkid | grep /dev/$2'2' | awk '{print $2}')
        fi
        uuid=${uuid//'"'/''}
        sed -i "s/loglevel=3 quiet/loglevel=3 quiet cryptdevice=$uuid:cryptroot root=/dev/mapper/cryptroot/g" /etc/default/grub
    fi

    pacman --needed -S grub efibootmgr --noconfirm --needed
    grub-install
    grub-mkconfig -o /boot/grub/grub.cfg
}

function configure_snapper() {
    pacman -S snapper grub-btrfs --noconfirm --needed
    snapper --no-dbus -c root create-config /
    btrfs sub del /.snapshots/
    mkdir /.snapshots

    # this could probably be a lot better ;-;
    uuid_no_spli=$(cat /etc/fstab | grep /home | awk '{print $1}')
    uuid_split=(${uuid_no_spli//=/ })
    uuid=${uuid_split[1]}

    echo "UUID=$uuid    /.snapshots    btrfs    rw,relatime,compress=lzo,ssd,space_cache=v2,subvol=@snapshots 0 0" >>/etc/fstab
    mount /.snapshots

    systemctl enable grub-btrfs.path

    sed -i 's/GRUB_DISABLE_RECOVERY=true/GRUB_DISABLE_RECOVERY=false/g' /etc/default/grub

    pacman -S snap-pac --noconfirm --needed
    pacman -S cronie --noconfirm --needed

    systemctl enable snapper-boot.timer
    systemctl enable snapper-cleanup.timer
    systemctl enable cronie.service

    grub-mkconfig -o /boot/grub/grub.cfg
}

# 1 - timesone
# 2 - locale_select
# 3 - pc_name
# 4 - password
# 5 - username
# 6 - keymap_select
# 7 - should_encrypt
# 8 - install_disk
# 9 - should_swap

set_timesone $1
set_localization $2 $6
configure_network $3
create_initramfs $7
set_root_password $4 $5
configure_bootloader $7 $8 $9
configure_snapper
