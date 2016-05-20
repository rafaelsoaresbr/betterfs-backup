#!/bin/bash

#    betterfs-backup - Simple script for incremental backup with btrfs
#    Copyright (C) 2016  Rafael Soares

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo "betterfs-backup  Copyright (C) 2016  Rafael Soares
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to
redistribute it under certain conditions."

SOURCE="/home"
TARGET="/media/boss/backup"

set -e

echo "The following subvolume will be backed up: "${SOURCE}" to "${TARGET}""

echo -e "Are you sure you want to continue? (y/N)"
read option
if [[ "$option" != "y" ]]; then
    echo "Aborting!"
    exit
fi
SRC=$(ls -1 "${SOURCE}")
TG=$(ls -1 "${TARGET}")
if [[ -d "${SOURCE}/backup" ]] ; then
    echo "It's an incremental backup!"
    sudo btrfs subvolume snapshot -r "${SOURCE}" "${SOURCE}/backup-new"
    sync
    sudo btrfs send -v -p "${SOURCE}/backup" "${SOURCE}/backup-new" | btrfs receive -v "${TARGET}"
    sudo btrfs subvolume delete -C "${SOURCE}/backup"
    sudo mv "${SOURCE}/backup-new" "${SOURCE}/backup"
    sudo btrfs subvolume delete -C "${TARGET}/backup"
    sudo mv "${TARGET}/backup-new" "${TARGET}/backup"
else
    echo "It's the first backup!"   
    sudo btrfs subvolume snapshot -r "${SOURCE}" "${SOURCE}/backup"
    sync
    sudo btrfs send -v "${SOURCE}/backup" | btrfs receive -v "${TARGET}"
fi

echo "All done!"
