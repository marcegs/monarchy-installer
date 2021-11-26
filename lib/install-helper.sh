#!/bin/bash

function update_system_clock() {
    timedatectl set-ntp true
}

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

function format_partition() {
    mkfs.fat -F 32 "/dev/$install_disk"1

    if [ $should_swap = "True" ]; then

        mkswap "/dev/$install_disk"2
        swapon "/dev/$install_disk"2

        mkfs_btrfs 3

    else
        mkfs_btrfs 2
    fi
}

function mkfs_btrfs() {
    if [ $should_encrypt = "True" ]; then
        (
            echo "YES"
            echo "$encrypt_password"
            echo "$encrypt_password"
        ) | cryptsetup luksFormat "/dev/$install_disk$1"
        
        (
            echo "$encrypt_password"
        ) | cryptsetup luksOpen "/dev/$install_disk$1" cryptroot

        mkfs.btrfs -L root "/dev/mapper/cryptroot" -f
    else
        mkfs.btrfs -L root "/dev/$install_disk$1" -f
    fi
}

function mount_partition() {
    sdx=""
    if [ $should_swap = "True" ]; then
        sdx="/dev/$install_disk''3"
    else
        sdx="/dev/$install_disk''2"
    fi

    if [ $should_encrypt = "True" ]; then
        sdx="/dev/mapper/cryptroot"
    fi

    mount -o compress=lzo $sdx /mnt
    cd /mnt
    btrfs su cr @
    btrfs su cr @tmp
    btrfs su cr @home
    btrfs su cr @log
    btrfs su cr @pkg
    btrfs su cr @snapshots

    cd /
    umount /mnt
    mount -o noatime,space_cache=v2,discard=async,compress=lzo,subvol=@ $sdx /mnt
    mkdir -p /mnt/{boot/efi,home,var/log,var/cache/pacman/pkg,btrfs,tmp}
    mount "/dev/$install_disk"1 /mnt/boot/efi
    mount -o noatime,space_cache=v2,discard=async,compress=lzo,subvol=@home $sdx /mnt/home
    mount -o noatime,space_cache=v2,discard=async,compress=lzo,subvol=@log $sdx /mnt/var/log
    mount -o noatime,space_cache=v2,discard=async,compress=lzo,subvol=@pkg $sdx /mnt/var/cache/pacman/pkg/
    mount -o noatime,space_cache=v2,discard=async,compress=lzo,subvol=@tmp $sdx /mnt/tmp
}

function install_base() {
    pacstrap /mnt base linux linux-firmware linux-headers base-devel git nano sudo man-db man-pages btrfs-progs bash-completion
}

function gen_fstab() {
    genfstab -U /mnt >>/mnt/etc/fstab
}
