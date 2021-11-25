#!/bin/bash

source lib/menu-helper.sh
source lib/install-helper.sh
source lib/info-helper.sh

function get_password() {
    pass_title="$1 Password"
    pass_text="Please type your $1 password."

    repeat_pass_title="Repeat $1 Password"
    repeat_pass_text="Please confirm your $1 password."

    password=$(password_box "$pass_title" "$pass_text")
    password_confirm=$(password_box "$repeat_pass_title" "$repeat_pass_text")

    while [[ "$password" != "$password_confirm" || "$password" = "" ]]; do
        message_box "Bad Password" "Passwords did not match or was blank."
        password=$(password_box "$pass_title" "$pass_text")
        password_confirm=$(password_box "$repeat_pass_title" "$repeat_pass_text")
    done
    echo $password
}

# $install_disk
function final_warning() {
    doit=$(yes_no_box "Final Warning!" "You are about to write changes to the Wdisk.
THIS ACTION CANNOT BE UNDONE!
Let's do it?")
    if [ $doit != "True" ]; then
        echo ":("
        exit
    fi
}

message_box "Welcome!" "Welcome to monarchy-installer! Yet another arch installer.
WARNING: This script is still in development and might brick your entire system! Use it only inside a VM or in a spare computer!
"

awser=$(yes_no_box "Monarchy" "Shall we begin?")
# in the future give an option of a minimal arch install or full monarchy installation
if [ $awser = "True" ]; then

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
    should_swap=$(yes_no_box "Swap" "Would you like to create a 2G Swap partition?")
    if [ $should_swap = "True" ]; then
        echo "Swap!"
    fi
    should_encrypt=$(yes_no_box "Disk encryption" "Would you like to encrypt your new installation?")
    if [ $should_encrypt = "True" ]; then
        encrypt_password=$(get_password "Encryption")
    fi

    # ==================== Users ====================

    user_name=$(input_box "User Name" "What name do you want to give to your user?")
    pc_name=$(input_box "Computer Name" "What name should be given to this computer?")
    password=$(get_password "User")

    # ==================== Install ====================

    final_warning $install_disk
    # == 1 ==
    update_system_clock
    disk_partition $install_disk $should_swap
    format_partition $install_disk $should_swap $should_encrypt
    mount_partition $install_disk

    # == 2 ==
    install_base

    # == 3 ==
    gen_fstab

    mkdir /mnt/post-chroot-temp/
    cp /root/monarchy-installer/post-chroot.sh /mnt/post-chroot-temp/
    arch-chroot /mnt /usr/bin/bash /post-chroot-temp/post-chroot.sh $timezone $locale_select $pc_name $password $user_name $keymap_select



    rm -r /mnt/post-chroot-temp/
    umount -R /mnt

    message_box "Done!" "Installation finished! You can now reboot and login into your new system!"

    # == 4 ==
    #profit

    # ==================== Finish ====================

else
    echo ":("
fi
