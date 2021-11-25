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
