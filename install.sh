#!/bin/bash

source lib/menu-helper.sh
source lib/install-helper.sh
source lib/info-helper.sh

message_box "Welcome!" "Welcome to monarchy-installer! Yet another arch installer.

WARNING This script it is still an WIP. Use it at your own risk!
WARNING 2 UEFI ONLY! (for now)

Any and all criticisms are welcome!

If you mistyped or selected the wrong option, select 'no' on the 'Final Warning' box and start from the beginning. This will be fixed in the future.
"

awser=$(yes_no_box "Monarchy" "Shall we begin?")

if [ $awser = "True" ]; then

    # ==================== Type ====================
#    message_box "Installation Type" "Monarchy-installer has 2 installation type, minimal (wip, missing encryption) and complete (wip).
#
#Minimal: Minimal arch install and some essential utilities.
#Complete: Cinnamon desktop environment and a lot, a lot more :)
#"

    types=("Minimal" "Complete")
    install_type= "TODO" #$(menu_box "Installation Type" "Which one would you like to install?" "" ${types[@]})

    # ==================== Location ====================

    locale_list=$(get_locale)
    locale_select=$(menu_box "Locale" "Select your locale (language)" "" ${locale_list[@]})

    timezone_select=""
    timezone="/usr/share/zoneinfo"
    while [ -d $timezone ]; do
        zone_list=$(ls "$timezone")
        timezone_select=$(menu_box "Zoneinfo" "Select your timezone" "" ${zone_list[@]})
        timezone="$timezone/$timezone_select"
    done

    # ==================== Keyboard ====================

    keymap_list=$(get_keymaps)
    keymap_select=$(menu_box "Keyboard" "Select your keyboard layout" "" ${keymap_list[@]})

    # ==================== Partitions ====================

    disks=$(get_disks)
    install_disk=$(menu_box "Disks" "Select which drive to install Arch Linux." "True" ${disks[@]})
    should_swap=$(yes_no_box "Swap" "Would you like to create a Swap partition?")

    should_encrypt=$(yes_no_box "Disk encryption" "Would you like to encrypt your new installation?")
    if [ $should_encrypt = "True" ]; then
        encrypt_password=$(get_password "Encryption")
    fi

    # ==================== Users ====================

    user_name=$(input_box "User Name" "What name do you want to give to your user?")
    pc_name=$(input_box "Computer Name" "What name should be given to this computer?")
    password=$(get_password "User")

    # ==================== Install ====================

    doit=$(yes_no_box "Final Warning!" "You are about to write changes to the disk.
THIS ACTION CANNOT BE UNDONE!
Let's do it?")
    if [ $doit != "True" ]; then
        echo ":("
        exit
    fi

    # == 1 ==

    update_system_clock
    disk_partition
    format_partition
    mount_partition
    install_base
    gen_fstab

    # == 2 ==

    mkdir /mnt/post-chroot-temp/
    cp /root/monarchy-installer/post-chroot-minimal.sh /mnt/post-chroot-temp/
    arch-chroot /mnt /usr/bin/bash /post-chroot-temp/post-chroot-minimal.sh $timezone $locale_select $pc_name $password $user_name $keymap_select $should_encrypt

    if [ $install_type = "Complete" ]; then
        cp /root/monarchy-installer/post-chroot-complete.sh /mnt/post-chroot-temp/
        arch-chroot /mnt /usr/bin/bash /post-chroot-temp/post-chroot-complete.sh
    fi

    rm -r /mnt/post-chroot-temp/
    umount -R /mnt

    message_box "Done!" "Installation finished! You can now reboot and login into your new system!"

    # ==================== Finish ====================

else
    echo ":("
fi
