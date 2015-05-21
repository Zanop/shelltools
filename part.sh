#!/bin/bash

echo -n "Partitioning sda..."
DEVICE_TARGET="/dev/sda"
parted --script ${DEVICE_TARGET} mklabel gpt
parted --script ${DEVICE_TARGET} unit MB mkpart primary linux-swap 2048s 4096M
parted --script ${DEVICE_TARGET} unit MB mkpart primary ext4 4096M 99%
echo "Done."

echo -n "Partitioning sdb..."
DEVICE_TARGET="/dev/sdb"
parted --script ${DEVICE_TARGET} mklabel gpt
parted --script ${DEVICE_TARGET} unit MB mkpart primary ext4 2048s 100%
echo "Done."

echo -n "Formating swap"
mkswap /dev/sda1
echo "Done."

echo -n "Formating root..."
mkfs.ext4 /dev/sda2
echo "Done."


# Input params for next section
# filesystem: xfs, ext4
# raid level: 0,1,5,6,10
# number of disks: 
# stripe size:
# 

echo "Select filesystem for /cdn"
select FILESYSTEM in xfs ext4;
do
    case $FILESYSTEM in
        "xfs")
            echo "xfs selected"
            echo "Enter su and sw params for mkfs.xfs "
            echo "sunit = stripe / 512"
            echo "swidth = sunit * num data disks"
            echo -n "Enter sunit?"
            read SUNIT
            echo -n "Enter swidth?"
            read SWIDTH
            mkfs.xfs -d sunit=${SUNIT},swidth=${SWIDTH} /dev/sdb1
            break
            ;;
        "ext4")
            # stride = chunk / block = 128kB / 4k = 32
            # stripe-width = stride * n data disks  = 32 * ( (3) - 1 ) = 32 * 2 = 64 
            # 
            echo "ext4 selected"
            echo "Go to http://busybox.net/~aldot/mkfs_stride.html and get STRIDE AND STRIPE_WIDTH params"
            echo "for mkfs.ext4 /dev/sdb1 -b 4096 -E stride=STRIDE,stripe-width=STRIPE-WIDTH"
            echo -n "Enter STRIDE?"
            read STRIDE
            echo -n "Enter STRIPE-WIDTH?"
            read STRIPE
            mkfs.ext4 /dev/sdb1 -b 4096 -E stride=${STRIDE},stripe-width=${STRIPE}
            break
            ;;
        *)
            exit
            ;;
    esac
done

mount /dev/sda2 /mnt/gentoo/
if mountpoint /mnt/gentoo; then
    echo "Select sync source?"
    select SOURCE in host1 host2 host2.com;
    do
        echo "${SOURCE} selected"
        break
    done
    echo -n "Downloading rsync..."
    wget -O /tmp/rsync http://gett.ucdn.com/rsync
    chmod +x /tmp/rsync
    echo "Done."
    echo -n "Syncing root..."
    /tmp/rsync -a ${SOURCE}::org/ /mnt/gentoo/
    echo "Done."
    mkdir -v /mnt/gentoo/sys
    mkdir -v /mnt/gentoo/proc
    mkdir -v /mnt/gentoo/cdn
    mount -o bind /dev/ /mnt/gentoo/dev/
    mount -o bind /sys/ /mnt/gentoo/sys/
    mount -o bind /proc/ /mnt/gentoo/proc/
fi

