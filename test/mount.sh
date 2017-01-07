# mount.sh
# aoneill - 01/07/17

fdisk -l disk.img
echo "Offset: Start of a partition multiplied by sector size"
echo -n "Offset: "
read offset

mkdir -p ./mnt
mount -o loop,offset=$offset disk.img ./mnt
