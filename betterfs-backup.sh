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

LICENSE=$(dirname "$0")/LICENSE

get_dir(){
  set -e
  DIR=$(zenity --file-selection --title="Select a directory" --directory 2>/dev/null)
  case $? in
    0)  zenity --info --title="betterfs-backup" --text="\"$DIR\" selected." 2>/dev/null; echo "$DIR";;
    1)  zenity --error --title="betterfs-backup" --text="No directory selected. Please select a directory." 2>/dev/null; get_dir;;
    -1) zenity --error --title="betterfs-backup" --text="An unexpected error has occurred. Quitting." 2>/dev/null;;
  esac
}

backup(){
  set -e
  if [ -d "$1/backup" ] ; then
    zenity --info --title="betterfs-backup" --text="Previous backup detected! Making an incremental backup." 2>/dev/null
    (
    btrfs subvolume snapshot -r "$1" "$1/backup-new"
    sync
    btrfs send -v -p "$1/backup" "$1/backup-new" | btrfs receive -v "$2"
    btrfs subvolume delete -C "$1/backup"
    mv "$1/backup-new" "$1/backup"
    btrfs subvolume delete -C "$2/backup"
    mv "$2/backup-new" "$2/backup"
    ) |
    zenity --progress --title="betterfs-backup" --text="Copying..." --percentage=0 2>/dev/null
    if [ "$?" = -1 ] ; then
      zenity --error --title="betterfs-backup" --text="An unexpected error has occurred." 2>/dev/null
    fi
  else
    zenity --info --title="betterfs-backup" --text="It's the first backup! It may take long." 2>/dev/null
    (
    btrfs subvolume snapshot -r "$1" "$1/backup"
    sync
    btrfs send -v "$1/backup" | btrfs receive -v "$2"
    ) |
    zenity --progress --title="betterfs-backup" --text="Backing up..." --percentage=0 2>/dev/null
    if [ "$?" = -1 ] ; then
      zenity --error --title="betterfs-backup" --text="An unexpected error has occurred." 2>/dev/null
    fi
  fi
}

main(){
  zenity --info --title="betterfs-backup" \
         --text="You are about to make a backup of a btrfs subvolume. First select the SOURCE subvolume." 2>/dev/null
  SOURCE=$(get_dir)
  zenity --info --title="betterfs-backup" --text="Now select the TARGET subvolume." 2>/dev/null
  TARGET=$(get_dir)
  zenity --question --title="betterfs-backup" --default-cancel \
         --text="The following subvolume will be backed up: \"$SOURCE\" to \"$TARGET\". Are you sure you wish to proceed?" 2>/dev/null
  case $? in
    0)  backup "$SOURCE" "$TARGET";;
    1)  zenity --info --title="betterfs-backup" --text="Quitting." 2>/dev/null;;
    -1) zenity --error --title="betterfs-backup" --text="An unexpected error has occurred. Quitting." 2>/dev/null; exit;;
  esac

}

zenity --text-info --title="License" --filename="$LICENSE" --checkbox="I read and accept the terms." 2>/dev/null

case $? in
  0)  main;;
  1)  zenity --info --title="License" --text="You must accept the license to use this software." 2>/dev/null;;
  -1) zenity --error --title="License" --text="An unexpected error has occurred." 2>/dev/null;;
esac
