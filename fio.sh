#!/bin/bash


echo > test.fio

for i in {1..14}
do

test -d /cdn/disks/${i}/fio || mkdir /cdn/disks/${i}/fio
cat >> test.fio << END
[${i}]
blocksize=128k
directory=/cdn/disks/${i}/fio
size=3G
rw=write
direct=1
buffered=0
ioengine=libaio
iodepth=32
END
done
