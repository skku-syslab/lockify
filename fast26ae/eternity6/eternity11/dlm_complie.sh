#!/bin/bash
cd /usr/src/linux-6.6.23
cp -r /usr/src/linux-6.6.23-dlm/fs/dlm/* /usr/src/linux-6.6.23/fs/dlm/
cp -r /usr/src/linux-6.6.23-dlm/fs/gfs2/* /usr/src/linux-6.6.23/fs/gfs2/
cp -r /usr/src/linux-6.6.23-dlm/fs/ocfs2/* /usr/src/linux-6.6.23/fs/ocfs2/
cp -r /usr/src/linux-6.6.23-dlm/include/trace/events/dlm.h /usr/src/linux-6.6.23/include/trace/events/dlm.h
cp -r /usr/src/linux-6.6.23-dlm/include/uapi/linux/dlmconstants.h /usr/src/linux-6.6.23/include/uapi/linux/dlmconstants.h

make -j`nproc` M=/usr/src/linux-6.6.23/fs/dlm modules 
make -j`nproc` M=/usr/src/linux-6.6.23/fs/gfs2 modules 
make -j`nproc` M=/usr/src/linux-6.6.23/fs/ocfs2 modules 
make -j`nproc` INSTALL_MOD_STRIP=1 modules_install 
reboot
