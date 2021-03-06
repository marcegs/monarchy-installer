#!/bin/bash

function update_system_clock() {
    timedatectl set-ntp true
}

function disk_partition() {
    # UEFI GPT ONLY FOR NOW!

    sgdisk --zap-all "/dev/$install_disk"
    wipefs -a "/dev/$install_disk"

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
}

function format_partition() {
    is_nvme=$(echo "$install_disk" | grep nvme)
    if [ -n "$is_nvme" ]; then
        install_disk="$install_disk"p
    fi
    mkfs.fat -F 32 "/dev/$install_disk"1
    sdx="2"
    if [ "$should_encrypt" = "True" ]; then

        # echo "$encrypt_password" | cryptsetup luksFormat --cipher aes-xts-plain64 --key-size 256 --hash sha256 --use-random "/dev/$install_disk$sdx" -d -
        # echo "$encrypt_password" | cryptsetup luksOpen "/dev/$install_disk$sdx" cryptroot -d -
        # TODO This is not working, make it work!

        cryptsetup luksFormat --cipher aes-xts-plain64 --key-size 256 --hash sha256 --use-random "/dev/$install_disk$sdx"
        cryptsetup luksOpen "/dev/$install_disk$sdx" cryptroot

        mkfs.btrfs -L root /dev/mapper/cryptroot -f
    else
        mkfs.btrfs -L root "/dev/$install_disk$sdx" -f
    fi
}

function mount_partition() {
    temp_install_disk=""

    temp_install_disk="/dev/$install_disk"2

    if [ "$should_encrypt" = "True" ]; then
        temp_install_disk="/dev/mapper/cryptroot"
    fi

    mount -o compress=lzo $temp_install_disk /mnt

    cd /mnt
    btrfs su cr @
    btrfs su cr @tmp
    btrfs su cr @home
    btrfs su cr @log
    btrfs su cr @pkg
    btrfs sub cr @snapshots

    cd /
    umount /mnt
    mount -o noatime,space_cache=v2,compress=zstd,discard=async,subvol=@ $temp_install_disk /mnt
    mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,btrfs,tmp}
    mount "/dev/$install_disk"1 /mnt/boot
    mount -o noatime,space_cache=v2,compress=zstd,discard=async,subvol=@home $temp_install_disk /mnt/home
    mount -o noatime,space_cache=v2,compress=zstd,discard=async,subvol=@log $temp_install_disk /mnt/var/log
    mount -o noatime,space_cache=v2,compress=zstd,discard=async,subvol=@pkg $temp_install_disk /mnt/var/cache/pacman/pkg/
    mount -o noatime,space_cache=v2,compress=zstd,discard=async,subvol=@tmp $temp_install_disk /mnt/tmp

    unset temp_install_disk
}

function install_base() {
    pacstrap /mnt base linux linux-firmware linux-headers base-devel git nano sudo man-db man-pages btrfs-progs bash-completion
}

function gen_fstab() {
    genfstab -U /mnt >>/mnt/etc/fstab
}
