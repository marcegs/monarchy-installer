#!/bin/bash

function get_cpu_info() {
    cat /proc/cpuinfo
}

function get_gpu_info() {
    lspci | grep VGA
}

function get_disks() {
    lsblk | grep disk | awk '{print $1 " " $4}'
}

function get_locale() {
    grep UTF-8 /etc/locale.gen | sed 's/#/''/g' | awk '{print $1}'
}

function get_keymaps() {
    localectl list-keymaps
}

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