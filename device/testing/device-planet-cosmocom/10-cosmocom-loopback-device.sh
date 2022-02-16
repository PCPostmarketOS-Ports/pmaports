#!/bin/sh
. /etc/deviceinfo
. ./init_functions.sh

mount_loopback_device() {
	LOOPBACK_IMG="postmarket.img" # rootfs filename
	SDCARD_LABEL="COSMOSD" # by default, can be changed on custom pmOS build
	GEMIAN_ROOTFS_LABELS="gemian-buster gemian-bullseye"

	# Create temporary mount point
	mkdir /tmpmnt

	# Check on SD card first
	mount -o ro $(findfs LABEL="${SDCARD_LABEL}") /tmpmnt || true # use '|| true' to avoid boot errors

	if [ -f "/tmpmnt/${LOOPBACK_IMG}" ]; then
		mount -o remount,rw /tmpmnt

		LOOPBACK_DEV="$(losetup -f)"
		losetup "${LOOPBACK_DEV}" "/tmpmnt/${LOOPBACK_IMG}"
		kpartx -afs "${LOOPBACK_DEV}"

		return 0
	fi

	# By this point, the SD card did *not* contain the rootfs.
	# Trying Gemian installs in label order.
	for GEMIAN_INSTALL in "${GEMIAN_ROOTFS_LABELS}" ; do
		mount -o ro "$(findfs LABEL="${GEMIAN_INSTALL}")" /tmpmnt || true # use '|| true' to avoid boot errors.

		LOOPBACK_DEV="$(losetup -f)"
		losetup "${LOOPBACK_DEV}" "/tmpmnt/${LOOPBACK_IMG}"
		kpartx -afs "${LOOPBACK_DEV}"

		return 0
	done

	umount /tmpmnt
}

mount_loopback_device
