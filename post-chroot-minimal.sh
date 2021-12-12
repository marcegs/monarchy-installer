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
    if [ "$1" = "True" ]; then
        sed -i "s/block filesystems/block encrypt filesystems/g" /etc/mkinitcpio.conf
        mkinitcpio -p linux
    fi
}

function set_root_password() {
    echo root:"$1" | chpasswd # change root password

    useradd -m -G wheel "$2"  # wheel group for sudo
    echo "$2":"$1" | chpasswd # change user password

    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers # make so users of the wheel group can run sudo
}

function configure_bootloader() {
    pacman --needed -S grub efibootmgr --noconfirm --needed
    sdx="2"
    if [ "$3" = "True" ]; then
        sdx="3"
    fi

    uuid=$(blkid -s UUID -o value /dev/"$2"$sdx)

    if [ "$1" = "True" ]; then
        sed 's/#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g' -i /etc/default/grub
        sed "s/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=\/dev\/disk\/by-uuid\/$uuid:cryptroot\"/g" -i /etc/default/grub
    fi

    grub-install --target=x86_64-efi --efi-directory=/boot --recheck --bootloader-id=GRUB "$2"
    grub-mkconfig -o /boot/grub/grub.cfg
}

function configure_snapper() {
    pacman -S snapper grub-btrfs --noconfirm --needed
    snapper --no-dbus -c root create-config /
    btrfs sub del /.snapshots/
    mkdir /.snapshots

    # this could probably be a lot better ;-;
    uuid_no_spli=$(grep /home /etc/fstab | awk '{print $1}')
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

function encrypt_swap() {
    swapoff "/dev/$1"2
    echo "y" | mkfs.ext2 -L cryptswap "/dev/$1"2 1M

    swap_line=$(grep swap /etc/crypttab)
    sed -i -e "s|$swap_line|LABEL=cryptswap    /dev/urandom    swap,offset=2048,cipher=aes-xts-plain68,size=512|g"

    swap_uuid=$(grep swap /etc/fstab | awk '{print $1}')
    sed -i -e "s|$swap_uuid|LABEL=/dev/mapper/swap|g"
    mount -a
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

set_timesone "$1"
set_localization "$2" "$6"
configure_network "$3"
create_initramfs "$7"
set_root_password "$4" "$5"
configure_bootloader "$7" "$8" "$9"
configure_snapper
if [ "$7" = "True" ] && [ "$9" = "True" ]; then
    encrypt_swap $7
fi