#!/bin/bash
# == 1 ==
function update_system_clock() {
    timedatectl set-ntp true
}
# $install_disk, $should_swap
function disk_partition() {
    # UEFI GPT ONLY FOR NOW!
    (
        echo g     # new GPT partition table
        echo n     # new partition
        echo       # default number
        echo       # default start
        echo +500M # 500m
        echo t     # set type
        echo 1     # EFI file system
        echo n     # new partition
        echo       # default number
        echo       # default start
        echo +2G   # 2g
        echo t     # set type
        echo 2     # partition number 2
        echo 19    # linux swap
        echo n     # new partition
        echo       # default number
        echo       # default start
        echo       # all available space
        echo w     # write changes to disk
    ) | fdisk "/dev/$1"
}
# $install_disk, $should_swap, #should_encrypt
function format_partition() {
    mkfs.fat -F 32 "/dev/$1"1

    mkswap "/dev/$1"2
    swapon "/dev/$1"2

    mkfs.btrfs -L root "/dev/$1"3 -f
}
# $install_disk
function mount_partition() {
    mount -o compress=lzo "/dev/$1"3 /mnt
    cd /mnt
    btrfs su cr @
    btrfs su cr @tmp
    btrfs su cr @home
    btrfs su cr @log
    btrfs su cr @pkg
    btrfs sub cr @snapshots

    cd /
    umount /mnt
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@ "/dev/$1"3 /mnt
    mkdir -p /mnt/{boot/efi,home,var/log,var/cache/pacman/pkg,btrfs,tmp}
    mount "/dev/$1"1 /mnt/boot/efi
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@home "/dev/$1"3 /mnt/home
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@log "/dev/$1"3 /mnt/var/log
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@pkg "/dev/$1"3 /mnt/var/cache/pacman/pkg/
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@tmp "/dev/$1"3 /mnt/tmp
}

# == 2 ==
# $keymap_select
function install_base() {
    pacstrap /mnt base linux linux-firmware linux-headers base-devel git nano sudo man-db man-pages btrfs-progs bash-completion
}

# == 3 ==
function gen_fstab() {
    genfstab -U /mnt >>/mnt/etc/fstab
}
