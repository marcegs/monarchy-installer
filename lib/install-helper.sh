#!/bin/bash

function update_system_clock() {
    timedatectl set-ntp true
}
# $install_disk, $should_swap
function disk_partition() {
    # UEFI GPT ONLY FOR NOW!

    if [ $should_swap = "True" ]; then
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
        ) | fdisk "/dev/$install_disk"
    else
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
            echo       # all available space
            echo w     # write changes to disk
        ) | fdisk "/dev/$install_disk"
    fi
}
# $install_disk, $should_swap, #should_encrypt
function format_partition() {
    mkfs.fat -F 32 "/dev/$install_disk"1

    if [ $should_swap = "True" ]; then

        mkswap "/dev/$install_disk"2
        swapon "/dev/$install_disk"2

        mkfs.btrfs -L root "/dev/$install_disk"3 -f

    else
        mkfs.btrfs -L root "/dev/$install_disk"2 -f
    fi
}
# $install_disk, $should_swap
function mount_partition() {
    sdx=""
    if [ $should_swap = "True" ]; then
        sdx=3
    else
        sdx=2
    fi

    mount -o compress=lzo "/dev/$install_disk$sdx" /mnt
    cd /mnt
    btrfs su cr @
    btrfs su cr @tmp
    btrfs su cr @home
    btrfs su cr @log
    btrfs su cr @pkg
    btrfs sub cr @snapshots

    cd /
    umount /mnt
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@ "/dev/$install_disk$sdx" /mnt
    mkdir -p /mnt/{boot/efi,home,var/log,var/cache/pacman/pkg,btrfs,tmp}
    mount "/dev/$install_disk"1 /mnt/boot/efi
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@home "/dev/$install_disk$sdx" /mnt/home
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@log "/dev/$install_disk$sdx" /mnt/var/log
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@pkg "/dev/$install_disk$sdx" /mnt/var/cache/pacman/pkg/
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@tmp "/dev/$install_disk$sdx" /mnt/tmp
}

# $keymap_select
function install_base() {
    pacstrap /mnt base linux linux-firmware linux-headers base-devel git nano sudo man-db man-pages btrfs-progs bash-completion
}

function gen_fstab() {
    genfstab -U /mnt >>/mnt/etc/fstab
}
