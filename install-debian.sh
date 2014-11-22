#!/bin/bash

# Debian(X86) Installation Script
#
# Author: 910JQK https://github.com/910JQK
# This script is licensed under MIT License, with absolutely no warranty.
#
# *dialog* is required 


TMP="/tmp/install-debian.tmp";
KERNELS=("linux-image-486" "linux-image-586" "linux-image-686-pae" "linux-image-amd64");
SUITES=("stable" "testing" "unstable");


function init(){
    editor="nano";
    target="";
    suite="stable"
    mirror="http://mirrors.ustc.edu.cn/debian";
}


function msg(){
    dialog --title "${1}" --msgbox "${2}" 7 25;
}


function yesno(){
    dialog --title "${1}" --yesno "${2}" 7 25;
}


function error(){
    echo "Error while ${1}";
    echo -n "(Enter):";
    read;
}


function input(){
    cat "${TMP}";
}


function assert_target(){
    if [ -d "${target}" ]; then
	return 0;
    else
	msg "Error" "Target directory is invalid. Please set target correctly.";
	return 1;
    fi
}


function chroot_bind(){
    cp /etc/resolv.conf "${target}/etc/resolv.conf";
    mountpoint -q "${target}/dev" || mount --bind /dev "${target}/dev";
    mountpoint -q "${target}/proc" || mount --bind /proc "${target}/proc";
    mountpoint -q "${target}/sys" || mount --bind /sys "${target}/sys";
}


function chroot_release(){
    mountpoint -q "${target}/dev" && umount "${target}/dev";
    mountpoint -q "${target}/proc" && umount "${target}/proc";
    mountpoint -q "${target}/sys" && umount "${target}/sys";
}


function list(){
    local title;
    local item;
    local i;
    local args;
    title="${1}";
    shift;
    args=();
    i=0;
    for item in "${@}"; do
	args=("${args[@]}" "${i}" "${item}");
	let i=$i+1;
    done
    dialog --menu "${title}" 12 30 7 "${args[@]}" 2> "${TMP}" || return 1;
}


function main_menu(){
    dialog --title "Debian Installation" \
	   --default-item "${1}" \
	   --menu "Menu" 15 40 8 \
	   0 "Select Text Editor" \
	   1 "Set Target Directory" \
	   2 "Set Software Mirror" \
	   3 "Select Suite" \
	   4 "Install Base System" \
	   5 "Set Apt Source and Fstab" \
	   6 "Install Kernel" \
	   7 "Set Root Password" \
	   8 "Install Bootloader" \
	   9 "Quit" \
	   2> "${TMP}";

    [ $? = 0 ] || exit 0;

    item=$(input)
    case "${item}" in
	0) # Text Editor
	    dialog --title "Text Editor" --menu "" 8 18 2 \
		   0 nano \
		   1 vi \
		   2> "${TMP}";
	    case $(input) in
		0)
		    editor="nano";
		    ;;
		1)
		    editor="vi";
		    ;;
	    esac
	    ;;
	1) # Target
	    dialog --inputbox "target directory:" 8 25 2> "${TMP}";
	    target="$(input)";
	    ;;
	2) # Mirror
	    dialog --inputbox "mirror (http://***/debian):" 10 30 2> "${TMP}";
	    mirror="$(input)";
	    ;;
	3) # Suite
	    list "Suite:" "${SUITES[@]}" || return 3;
	    suite="${SUITES[$(input)]}";
	    ;;
	4) # Base System
	    assert_target || return "${item}";
	    debootstrap "${suite}" "${target}" "${mirror}" \
		|| error "installing base system";
	    ;;
	5) # Apt Source & fstab
	    assert_target || return "${item}";
	    "${editor}" "${target}/etc/apt/sources.list";
	    "${editor}" "${target}/etc/fstab";
	    ;;
	6) # Kernel
	    assert_target || return "${item}";
	    list "Kernel:" "${KERNELS[@]}" || return 6;
	    kernel="${KERNELS[$(input)]}";
	    chroot_bind;	    
	    chroot "${target}" apt-get update \
		&& chroot "${target}" apt-get install "${kernel}" \
		    || error "installing kernel";
	    ;;
	7) # Password
	    assert_target || return "${item}";
	    chroot_bind;
	    chroot "${target}" passwd root \
		|| error "setting root password";
	    ;;
	8) # Bootloader
	    assert_target || return "${item}";
	    dialog --title "Notice" --yesno "This script will install bootloader *GRUB* in a simple way. If you are using *UEFI* or advanced disk settings (e.g. GPT partition table, LVM and RAID), you'd better configure it manually. Continue installing?" 10 42 \
		|| return "${item}";
	    chroot_bind;
	    chroot "${target}" apt-get install grub-pc os-prober \
		|| error "installing grub";
	    ;;
	9) # Quit
	    [ -d "${target}" ] && chroot_release;
	    exit 0
	    ;;
    esac
    return "${item}";
}


init;
main_menu 0;
while item=$?; do
    main_menu $item;
done
