# customize.sh
# aoneill - 07/25/16

function init() {
  # Prompt for partitioning
  fdisk -l | grep "Disk /dev"

  while true; do
    echo -n "Which disk to partition (or \`skip'): "
    read dev

    if [[ $dev =~ ^/dev/sd[a-z]$ || "$dev" == "skip" ]]; then
      break
    fi
  done

  # Partition and automatically format
  if [[ "$dev" != "skip" ]]; then
    #parted $dev
    parted $dev print
    echo -n "Continue (y/n)? "
    read cont
    if [[ "$cont" != "y" ]]; then
      echo "Aborting..."
      return 1
    fi

    tmp=$(temp)
    parted $dev print \
      | tail -n+8 \
      | sed -e "/^\w*$/d" \
      | awk -e '{print $5, $1}' \
      | sed -e "/^ /d" \
      | sed -e "s|\(.*\) \(.*\)|mkfs.\1 ${dev}\2|" \
      | sort | uniq \
      | tee ~/log \
      | grep -v "^\s*$" \
      | sed -e "s/mkfs\.linux-swap\((.*)\)\?/mkswap/" \
      | sed -e "s/fat\([0-9]\+\)/fat -F \1/" \
      | sed -e "s/hfs+/hfsplus/" \
      | sed -e "s/\(.*\)/echo '\1'\n\1/" > $tmp

    #bash $tmp
    rm $tmp
    return 1
  fi

  return 0

  cd $HOME/$DIST_DIR/
  ./configure
}

init
if [[ "$?" == "0" ]]; then
  reboot
fi
