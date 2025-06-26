#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

# 전체 경로를 직접 변수로 정의
set $createdir=/mnt/fast26ae/filebench/create
set $deletedir=/mnt/fast26ae/filebench/delete

set $nfiles=50000
set $meandirwidth=1000000
set $meanfilesize=16k
set $nthreads=100
set $meaniosize=16k
set $iosize=1m

# 수정된 fileset 정의
define fileset name=createset,path=$createdir,size=$meanfilesize,entries=$nfiles,dirwidth=$meandirwidth,prealloc=20
define fileset name=deleteset,path=$deletedir,size=$meanfilesize,entries=$nfiles,dirwidth=$meandirwidth,prealloc=80

define process name=proxycache,instances=1
{
  thread name=proxycache,memsize=10m,instances=$nthreads
  {
    # 삭제는 deleteset에서 수행
    flowop deletefile name=deletefile1,filesetname=deleteset
    
    # 생성 및 추가는 createset에서 수행
    flowop createfile name=createfile1,filesetname=createset,fd=1
    flowop appendfilerand name=appendfilerand1,iosize=$meaniosize,fd=1
    flowop closefile name=closefile1,fd=1
    
    # 읽기 작업은 createset에서 수행
    flowop openfile name=openfile2,filesetname=createset,fd=1
    flowop readwholefile name=readfile2,fd=1,iosize=$iosize
    flowop closefile name=closefile2,fd=1
    flowop openfile name=openfile3,filesetname=createset,fd=1
    flowop readwholefile name=readfile3,fd=1,iosize=$iosize
    flowop closefile name=closefile3,fd=1
    flowop openfile name=openfile4,filesetname=createset,fd=1
    flowop readwholefile name=readfile4,fd=1,iosize=$iosize
    flowop closefile name=closefile4,fd=1
    flowop openfile name=openfile5,filesetname=createset,fd=1
    flowop readwholefile name=readfile5,fd=1,iosize=$iosize
    flowop closefile name=closefile5,fd=1
    flowop openfile name=openfile6,filesetname=createset,fd=1
    flowop readwholefile name=readfile6,fd=1,iosize=$iosize
    flowop closefile name=closefile6,fd=1
    flowop opslimit name=limit
  }
}

run 5
echo  "Web proxy-server Version 3.0 personality successfully loaded"


