#!/bin/bash

# Archlinux Installation Script
#
# Author: 910JQK https://github.com/910JQK
# This script is licensed under MIT License, with absolutely no warranty.
#
# *dialog* is required 


TMP="/tmp/install-archlinux.tmp";
MIRROR_LIST="/etc/pacman.d/mirrorlist";
CONF_FILES=("/etc/pacman.conf" "/etc/pacman.d/mirrorlist" "/etc/mkinitcpio.conf" "/etc/fstab");


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


function config_file_menu(){
    local i;
    local file;
    local item;
    local args=();
    i=0;
    for file in ${CONF_FILES[@]}; do
	args=(${args[@]} ${i} ${file});
	let i=$i+1;
    done
    dialog --title "Configuations" \
	   --default-item "${1}" \
	   --menu "" 15 40 8 ${args[@]} 2> "${TMP}";
    [ $? = 0 ] || return 255;
    item=$(input);
    "${editor}" "${target}/${CONF_FILES[${item}]}" \
	|| error "editing configuration file";
    return "${item}";
}


function main_menu(){
    dialog --title "Archlinux Installation" \
	   --default-item "${1}" \
	   --menu "Menu" 15 40 8 \
	   0 "Select Text Editor" \
	   1 "Set Target Directory" \
	   2 "Set Software Mirror" \
	   3 "Install Base System" \
	   4 "Modify Configuration Files" \
	   5 "Generate Initramfs" \
	   6 "Set Root Password" \
	   7 "Install Bootloader" \
	   8 "Empty Pacman Cache" \
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
	    "${editor}" "${MIRROR_LIST}" \
		|| error "editing mirror configuration";
	    ;;
	3) # Base System
	    assert_target || return "${item}";
	    optionalpkg="";
	    if yesno "Optional Package" 'Install group "base-devel"?'; then
		optionalpkg="base-devel";
	    fi
	    if yesno "Confirm" \
		     'Install base system into "'"${target}"'" ?'; then
		path_db="${target}/var/lib/pacman"
		path_gpg="${target}/etc/pacman.d/gnupg";
		path_cache="${target}/var/cache/pacman/pkg"
		path_log="${target}/var/log/";
		mkdir -p "${path_db}" "${path_gpg}" "${path_cache}" "${path_log}" \
		    && pacman -Sy base "${optionalpkg}" \
			   --dbpath "${path_db}" \
			   --root "${target}" \
			   --gpgdir "${path_gpg}" \
			   --cachedir "${path_cache}" \
		|| error "installing base system";
	    fi
	    ;;
	4) # Configuration
	    assert_target || return "${item}";
	    local item1;
	    config_file_menu 0;
	    item1=$?;
	    while [ ${item1} != 255 ]; do
		config_file_menu $item1;
		item1=$?;
	    done
	    ;;
	5) # Initramfs
	    assert_target || return "${item}";
	    chroot_bind;
	    chroot "${target}" mkinitcpio -p linux \
		|| error "generating initramfs";
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
	    chroot "${target}" pacman -S grub os-prober;
	    chroot "${target}" grub-install --recheck "${boot_device}" \
		&& chroot "${target}" grub-mkconfig -o /boot/grub/grub.cfg \
		    || error "installing grub";
	    ;;
	8) # Cache
	    assert_target || return "${item}";
	    pacman -Scc --dbpath "${path_db}" --cachedir "${path_cache}" \
		|| error "empting pacman cache";
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
