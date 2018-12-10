#!/bin/bash

VER=2018-11-13-raspbian-stretch-lite
IMG=$VER.img
ZIP=~/Downloads/$VER.zip
DISK=/dev/disk3
RDISK=/dev/rdisk3

echo "preparing"
#unzip $ZIP
diskutil list
sudo diskutil unmountDisk $DISK

echo "writing $IMG to $RDISK in 10 seconds, CMD-C to cancel"
sleep 10
sudo dd bs=1m if=$IMG of=$RDISK conv=sync

echo "finished writing image, waiting on boot to mount"
sleep 10

echo "configuring boot network, be sure to change pi/raspberry login ASAP"
touch /Volumes/boot/ssh
cp wpa_supplicant.conf /Volumes/boot/.

echo "unmounting disk, so it's safe to eject"
diskutil unmountDisk $DISK
