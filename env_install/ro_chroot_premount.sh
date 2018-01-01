<<<<<<< HEAD
#!/bin/bash

ROOT_CHROOT=/ro

    #Mounting chroot directories
    mount -o remount,rw /ro
=======
#!/sbin/openrc-run

ROOT_CHROOT=/ro

depend() {
   need localmount
   need bootmisc
}
 
start() {
    ebegin "Mounting chroot directories"
>>>>>>> cd263fd78db013bc262b0f9161e4addc39dc4f44
    mount --rbind /dev $ROOT_CHROOT/dev
    mount --make-rslave $ROOT_CHROOT/dev
    mount -t proc /proc $ROOT_CHROOT/proc
    mount --rbind /sys $ROOT_CHROOT/sys
    mount --make-rslave $ROOT_CHROOT/sys
    mount --rbind /tmp $ROOT_CHROOT/tmp 
<<<<<<< HEAD
    
    chroot $ROOT_CHROOT /bin/bash --rcfile /var/lib/cloud9/surfacelab/env_install/bashrc_ro_chroot
    #-c "source /etc/profile; export PS1=\"(chroot) $PS1\""
 
    #Unmounting chroot directories
    umount -f $ROOT_CHROOT/dev > /dev/null &
    umount -f $ROOT_CHROOT/proc > /dev/null &
    umount -f $ROOT_CHROOT/sys > /dev/null &
    umount -f $ROOT_CHROOT/tmp > /dev/null &
    mount -o remount,ro /ro
=======
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
>>>>>>> cd263fd78db013bc262b0f9161e4addc39dc4f44
