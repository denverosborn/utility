#!/bin/bash

# Script to pull down amd cache the CoreOS image required by a disconnected install.
# Tested with a VMware IPI deployment. 
# Bare-metal may need tweaks depending on the type needed (pxe, iso, raw)

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin

Usage(){
cat << @EOF

   Usage:  $0 (vmware|aws|metal|qemu) 

@EOF
}

case $1 in 
  vmware) PLATFORM=vmware
          TYPE=ova
          ;;
  aws)    PLATFORM=aws
          TYPE=vmdk.gz
          ;;
  metal)  PLATFORM=metal
          TYPE=raw.gz
          ;;
  qemu)   PLATFORM=qemu
          TYPE=qcow2.gz
          ;;
  *)      Usage && exit 1
          ;;
esac

if [ ${PLATFORM}X == X ];then
  Usage && exit 1
fi

# Dump list of CoreOS images
COSJSON=/tmp/coreos.json
test -f ${COSJSON} || openshift-install coreos print-stream-json > ${COSJSON} 2>/dev/null

# Grab URL (location) and CoreOS image hash
URL=$(cat ${COSJSON}|jq -r '.architectures.x86_64.artifacts."'${PLATFORM}'".formats."'${TYPE}'".disk.location')
HASH1=$(cat ${COSJSON}|jq -r '.architectures.x86_64.artifacts."'${PLATFORM}'".formats."'${TYPE}'".disk.sha256')

# Download the image
echo Downloading the CoreOS Image for ${PLATFORM}
/usr/local/bin/coreos-installer download --insecure -u ${URL} -C /root/utility/image_cache >/dev/null 2>&1

# Verify hash
echo Verifying hash
COSIMG=$(find /root/utility/image_cache/ -type f -name \*${PLATFORM}\* 2>/dev/null)
HASH2=$(sha256sum ${COSIMG} 2>/dev/null |awk '{print $1}')

if [ "${HASH1}" != "${HASH2}" ];then
  echo The download failed.
  exit 1
else
  echo The download was successfull.
fi

