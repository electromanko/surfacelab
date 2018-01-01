#!/sbin/openrc-run

ROOT_CHROOT=/ro

depend() {
   need localmount
   need bootmisc
}
 
start() {
    ebegin "Mounting chroot directories"
    mount --rbind /dev $ROOT_CHROOT/dev
    mount --make-rslave $ROOT_CHROOT/dev
    mount -t proc /proc $ROOT_CHROOT/proc
    mount --rbind /sys $ROOT_CHROOT/sys
    mount --make-rslave $ROOT_CHROOT/sys
    mount --rbind /tmp $ROOT_CHROOT/tmp 
    eend $? "An error occurred while mounting chroot directories"
}
 
stop() {
     ebegin "Unmounting chroot directories"
     umount -f $ROOT_CHROOT/dev > /dev/null &
     umount -f $ROOT_CHROOT/proc > /dev/null &
     umount -f $ROOT_CHROOT/sys > /dev/null &
     umount -f $ROOT_CHROOT/tmp > /dev/null &
     eend $? "An error occurred while unmounting chroot directories"
}
