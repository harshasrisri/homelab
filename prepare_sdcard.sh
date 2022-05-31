#!/bin/sh
set -e

log() {
    echo $@ >&2
}

fatal() {
    echo $@ >&2
    exit 1
}

check_env_vars() {
    log "Check environment variables..."
    [ -z "${RPI_IMAGE}" ] && fatal "RPI_IMAGE not defined in env"
    [ -z "${DEST_DISK}" ] && fatal "DEST_DISK not defined in env"
    [ -z "${RPI_HNAME}" ] && fatal "RPI_HNAME not defined in env"
    [ -z "${PI_PASSWD}" ] && fatal "PI_PASSWD not defined in env"
    BOOT_PART=${DEST_DISK}1
    EXT4_PART=${DEST_DISK}2
    SSH_ID_PUB=$(cat ~/.ssh/id_rsa.pub)
    log "Done."
}

check_resources() {
    log "Check resources..."
    # check_command mkpasswd
    # check_command envsubst
    # check_command eject
    # check_command dd
    # check_command parted
    # check_command e2fsck
    # check_command resize2fs
    [ ! -f "${RPI_IMAGE}" ] && fatal "RPI_IMAGE file not found"
    [ ! -b "${DEST_DISK}" ] && fatal "DEST_DISK disk not found"
    log "Done."
}

display_header() {
    log "Raspi Img: ${RPI_IMAGE}"
    log "Dest Disk: ${DEST_DISK}"
    log "Boot Part: ${BOOT_PART}"
    log "Ext4 Part: ${EXT4_PART}"
    log "Host Name: ${RPI_HNAME}"
    log "Pi Passwd: ${PI_PASSWD}"
    sleep 3s
}

unmount_partitions() {
    log "Unmounting partitions..."
    umount "${BOOT_PART}" || true
    umount "${EXT4_PART}" || true
    log "Done."
}

write_image() {
    log
    log "Writing image to sd card..."
    dd if=${RPI_IMAGE} of=${DEST_DISK} bs=4096 conv=fsync status=progress
    eject ${BOOT_PART}
    sleep 1s
    eject -t ${DEST_DISK}
    log "Done."
}

edit_part_tbl() {
    log
    log "Editing partition table..."
    parted ${DEST_DISK} resizepart 2 -- -1
    log "Done."
}

repair_fs() {
    log
    log "Repairing partition if needed..."
    e2fsck -yf ${EXT4_PART}
    log "Done."
}

resize_fs() {
    log
    log "Resizing ext4 partition..."
    resize2fs ${EXT4_PART}
    log "Done."
}

eject_disk() {
    log
    log -n "Soft ejecting SD Card..."
    sync
    eject "${EXT4_PART}"
    sleep 1s
    log "Done."
}

wait_for_sdcard() {
    log
    log -n "Please insert/replace SD Card..."
    while [ ! -b "${EXT4_PART}" ]; do log -n "."; sleep 2s; done
    log "Done!"
}

configure_sdcard() {
    log
    log "Configuring sd card..."
    eject -t ${DEST_DISK}
    mkdir -p boot
    sleep 2s
    mount ${BOOT_PART} boot
    export RPI_HNAME
    export PI_PASSWD=$(echo $PI_PASSWD | mkpasswd -sm yescrypt)
    export SSH_ID_PUB
    cat user-data | envsubst > boot/user-data
    cat boot/user-data >&2
    sync
    umount boot
    eject ${BOOT_PART}
    log "Done."
}

prepare_sdcard() {
    check_env_vars
    check_resources
    display_header
    unmount_partitions
    write_image
    edit_part_tbl
    repair_fs
    resize_fs
    eject_disk
    configure_sdcard
}

main() {
    [ -z "${1}" ] || [ -z "${2}" ] && fatal "Usage: $0 <start_range> <end_range>"
    [ -z "${RPI_BASE_HNAME}" ] && fatal "RPI_BASE_HNAME not defined in env"
    mkdir -p logs

    for card in $(eval echo {${1}..${2}}); do
        RPI_HNAME="${RPI_BASE_HNAME}${card}"
        log
        log "Preparing card for $RPI_HNAME"
        prepare_sdcard > logs/${RPI_HNAME}.log
        wait_for_sdcard
    done
}

main $@
