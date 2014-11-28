#!/bin/bash

# Self-Copy Script
#
# Author: 910JQK https://github.com/910JQK
# This script is licensed under MIT License, with absolutely no warranty.
#
# *dialog* is required 


TMP="/tmp/self-copy.tmp";


function input(){
    cat "${TMP}";
}


function error(){
    echo "Error while ${1}, exit?";
    echo -n "(y|n):";
    read r;
    [[ "${r}" != [Nn] ]] && exit 2;
}


# Notice
dialog --title "Notice" \
       --yesno "This script will only copy files/folders from '/' to target *without* installing bootloader. Continue?" 8 35 || exit 0;


# Generate file list of '/'
files=();
copy=();
args=();
i=0
for file in /*; do
    files=("${files[@]}" "${file}");
    args=("${args[@]}" "${i}" "${file}" "on");
    let i=$i+1;
done

# Select files to be copied
dialog --title "Self-Copy Script" \
       --checklist "Select files to be copied" \
       15 40 8 "${args[@]}" \
       2> "${TMP}" || exit 0;

for index in $(input); do
    copy=("${copy[@]}" "${files[${index}]}");
done

# Select target
dialog --title "Target" \
       --inputbox "target directory:" \
       8 25 \
       2> "${TMP}";

target=$(input);

# Assert target
[ ! -d "${target}" ] && dialog --msgbox "Target directory is invalid. Please set target correctly." 7 25 && exit 1;

# Copy files
for item in "${copy[@]}"; do
    echo "=> Copy ${item}";
    cp -rvPp "${item}" "${target}" || error "copying ${item}";
done
