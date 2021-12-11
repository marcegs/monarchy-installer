#!/bin/bash

source lib/menu-helper.sh
source lib/install-helper.sh
source lib/info-helper.sh

install_type=""
timezone=""
locale_select=""
keymap_select=""
install_disk=""
should_swap=""
should_encrypt=""
user_name=""
pc_name=""
password=""

function SelectType() {
    types=("Minimal" "Complete")
    install_type=$(menu_box "Installation Type" "Which one would you like to install?" "" ${types[@]})
    echo "$install_type"
}

function SelectLocale() {
    locale_list=$(get_locale)
    locale_select=$(menu_box "Locale" "Select your locale (language)" "" "${locale_list[@]}")
    echo "$locale_select"
}

function SelectTimezone() {
    timezone_select=""
    timezone="/usr/share/zoneinfo"
    while [ -d $timezone ]; do
        zone_list=$(ls "$timezone")
        timezone_select=$(menu_box "Time zone" "Select your time zone" "" "${zone_list[@]}")
        timezone="$timezone/$timezone_select"
    done

    echo "$timezone"
}

function SelectKeyboard() {

    keymap_list=$(get_keymaps)
    keymap_select=$(menu_box "Keyboard Layout" "Select your keyboard layout" "" "${keymap_list[@]}")
    localectl set-keymap "$keymap_select"
    echo "$keymap_select"
}

function SelectInstallLocation() {

    disks=$(get_disks)
    install_disk=$(menu_box "Disks" "Select which drive to install Arch Linux." "True" "${disks[@]}")
    echo "$install_disk"
}

function SelectSwap() {
    should_swap=$(yes_no_box "Swap" "Would you like to create a Swap partition?")
    echo "$should_swap"
}

function SelectEncryption() {
    should_encrypt=$(yes_no_box "Disk encryption" "Would you like to encrypt your new installation?
WARNING: Swap encryption is still missing")
    # if [ $should_encrypt = "True" ]; then
    # encrypt_password=$(get_password "Encryption")
    # fi
    echo "$should_encrypt"
}

function SelectEncryptionPassword() {
    encrypt_password=$(get_password "Encryption")
    echo "$encrypt_password"
}

function SelectUser() {
    user_name=$(input_box "User Name" "What name do you want to give to your user?")
    echo "$user_name"
}

function SelectPassword() {
    password=$(get_password "User")
    echo "$password"
}

function SelectHostName() {
    pc_name=$(input_box "Computer Name" "What name should be given to this computer?")
    echo "$pc_name"
}

function Install() {
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
    arch-chroot /mnt /usr/bin/bash /post-chroot-temp/post-chroot-minimal.sh "$timezone" "$locale_select" "$pc_name" "$password" "$user_name" "$keymap_select" "$should_encrypt" "$install_disk" "$should_swap"

    if [ "$install_type" = "Complete" ]; then
        cp /root/monarchy-installer/post-chroot-complete.sh /mnt/post-chroot-temp/
        arch-chroot /mnt /usr/bin/bash /post-chroot-temp/post-chroot-complete.sh
    fi

    rm -r /mnt/post-chroot-temp/
    umount -R /mnt

    message_box "Done!" "Installation finished! You can now reboot and login into your new system!"
}

function MainMenu() {
    
    whiptail --title "Monarchy installer" --menu --cancel-button "Exit" --default-item "$1" --ok-button "Select" "" 20 80 12 \
        "Installation Type" "    $install_type" \
        "Time zone" "    $timezone" \
        "Locale" "    $locale_select" \
        "Keyboard layout" "    $keymap_select" \
        "Install location" "    $install_disk" \
        "Swap" "    $should_swap" \
        "Encryption" "    $should_encrypt" \
        "User" "    $user_name" \
        "Host name" "    $pc_name" \
        " " " " \
        "Let's do it!" "    Begin installation" 3>&2 2>&1 1>&3
}

select=""

message_box "WARNING" "This script it is still an WIP. Use it at your own risk!"
awser=$(yes_no_box "Monarchy Installer" "Shall we begin?")

if [ "$awser" = "True" ]; then
    while [ "$select" != "Let's do it!" ]; do
        select=$(MainMenu "$select")
        if [ "$select" = "" ]; then
            echo ":("
            exit
        fi

        case $select in

        "Installation Type")
            install_type=$(SelectType)
            ;;

        "Time zone")
            timezone=$(SelectTimezone)
            ;;
        "Locale")
            locale_select=$(SelectLocale)
            ;;

        "Keyboard layout")
            keymap_select=$(SelectKeyboard)
            ;;
        "Install location")
            install_disk=$(SelectInstallLocation)
            ;;
        "Swap")
            should_swap=$(SelectSwap)
            ;;
        "Encryption")
            should_encrypt=$(SelectEncryption)
            ;;
        "User")
            user_name=$(SelectUser)
            password=$(SelectPassword)
            ;;
        "Host name")
            pc_name=$(SelectHostName)
            ;;

        "Let's do it!")
            doit=$(yes_no_box "Final Warning!" "You are about to write changes to the disk.
THIS ACTION CANNOT BE UNDONE!
Let's do it?")
            if [ "$doit" != "True" ]; then
                select="nah m8 im not done!"
            fi
            ;;

        *)
            true
            ;;
        esac

    done

    Install
else
    echo ":("
fi
