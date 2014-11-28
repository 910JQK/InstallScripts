#!/bin/bash

# Fedora Installation Script
#
# Author: 910JQK https://github.com/910JQK
# This script is licensed under MIT License, with absolutely no warranty.
#
# *dialog* is required 


TMP="/tmp/install-fedora.tmp";
REPO_FILE="/etc/yum/repos.d/Fedora-Minimal-Install.repo";


function init(){
    editor="nano";
    target="";
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


function main_menu(){
    dialog --title "Fedora Installation" \
	   --default-item "${1}" \
	   --menu "Menu" 15 40 8 \
	   0 "Select Text Editor" \
	   1 "Set Target Directory" \
	   2 "Set Release and Mirror" \
	   3 "Install Base System" \
	   4 "Install Kernel and Grub" \
	   5 "Modify Configurations" \
	   6 "Set Root Password" \
	   7 "Install Bootloader" \
	   8 "Quit" \
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
	2) # Release(Architecture) and Mirror
	    dialog --inputbox "release (e.g. 20):" 8 25 \
		   2> "${TMP}";
	    release="$(input)";
	    dialog --title "Architecture" --menu "Menu" 9 25 5 \
		   i386 32bit x86_64 64bit \
		   2> "${TMP}";
	    arch="$(input)";
	    dialog --inputbox "mirror (http://***/fedora):" 10 30 \
		   2> "${TMP}";
	    mirror="$(input)";
	    cat << EOF > "${REPO_FILE}";
[fedora]
name=Fedora ${release}
failovermethod=priority 
baseurl=${mirror}/linux/releases/${release}/Everything/${arch}/os/
enabled=1 
metadata_expire=7d
EOF
	    ;;
	3) # Base System
	    assert_target || return "${item}";
	    yum makecache \
		&& yum groups install "Minimal Install" \
		       --installroot="${target}" \
		    || error "installing base system";
	    ;;
	4) # Kernel and Grub 
	    yum install kernel grub2 --installroot="${target}" \
		|| error "installing kernel and grub";
	    ;;
	5) # Configurations
	    assert_target || return "${item}";
	    "${editor}" "${target}/etc/fstab";
	    "${editor}" "${target}/etc/selinux/config";
	    ;;
	6) # Password
	    assert_target || return "${item}";
	    chroot_bind;
	    chroot "${target}" passwd root \
		|| error "setting root password";
	    ;;
	7) # Bootloader
	    assert_target || return "${item}";
	    dialog --title "Notice" --yesno "This script will install bootloader *GRUB* in a simple way. If you are using *UEFI* or advanced disk settings (e.g. GPT partition table, LVM and RAID), you'd better configure it manually. Continue installing?" 10 42 \
		|| return "${item}";
	    local boot_device;
	    dialog --inputbox "boot device (e.g. /dev/sda):" 8 25 2> "${TMP}";
	    boot_device=$(input);
	    chroot_bind;
	    chroot "${target}" grub2-install --recheck "${boot_device}" \
		&& chroot "${target}" grub2-mkconfig -o /boot/grub/grub.cfg \
		    || error "installing grub";
	    ;;
	8) # Quit
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
