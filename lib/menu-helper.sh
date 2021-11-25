#!/bin/bash

backtitle="monarchy-linux installer"

default_height=25
default_width=60
default_lines=17

# $1 title, $2 text
function message_box() {
    whiptail --msgbox --title "$1" --backtitle "$backtitle" "$2" $default_height $default_width 3>&1 1>&2 2>&3
}

# $1 title, $2 question
function yes_no_box() {
    if whiptail --yesno --title "$1" --backtitle "$backtitle" "$2" 9 $default_width 3>&1 1>&2 2>&3; then
        echo "True"
    else
        echo "False"
    fi
}

# $1 title, $2 text, $3 --has-tag-item, $4 list
function menu_box() {
    title=$1 # Save first argument in a variable
    shift    # Shift all arguments to the left (original $1 gets lost)
    text=$1
    shift
    has_tag_item=$1
    shift

    whiptail_list=""
    options=("$@")

    #this is bad but it works for now
    if [ "$has_tag_item" = "True" ]; then
        for t in ${options[@]}; do
            whiptail_list+=$t$'\n'
        done
    else
        for t in ${options[@]}; do
            whiptail_list+=$t$'\n'
            whiptail_list+=$t$'\n'
        done
    fi

    if [ "$has_tag_item" = "True" ]; then
        whiptail --title "$title" --backtitle "$backtitle" --menu "$text" $default_height $default_width $default_lines \
            $whiptail_list 3>&1 1>&2 2>&3
    else
        whiptail --title "$title" --noitem --backtitle "$backtitle" --menu "$text" $default_height $default_width $default_lines \
            $whiptail_list 3>&1 1>&2 2>&3
    fi
}

# $1 title, $2 question
function input_box() {
    whiptail --title "$1" --backtitle "$backtitle" --inputbox "$2" 9 $default_width 3>&1 1>&2 2>&3
}

# $1 title, $2 question
function password_box() {
    whiptail --title "$1" --backtitle "$backtitle" --passwordbox "$2" 9 $default_width 3>&1 1>&2 2>&3
}
