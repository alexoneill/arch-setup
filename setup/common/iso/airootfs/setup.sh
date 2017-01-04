# setup.sh
# aoneill - 07/25/16

TABLE=gpt
BOOT_SIZE=500
SWAP_DIV=4

function tell() { echo $@; } # $@ }

function round_up() {
  [[ "$2" == "0" ]] && echo "$1"

  rem=$(echo "$1 % $2" | bc)
  [[ "$rem" == "0" ]] && echo "$1"

  echo "$1 + $2 - $rem" | bc
}

function confirm_parted() {
  parted $1 print
  echo -n "Continue (y/n)? "
  read cont
  if [[ "$cont" != "y" ]]; then
    echo "Aborting..."
    return 1
  fi

  return 0
}

function mkpart() {
  # Get the device
  dev=$1
  shift 1

  # Identify the filesystem
  fs=$2
  case $fs in
    linux-swap) fs=mkswap ;;
    fat16)      fs="fat -F 16" ;;
    fat32)      fs="fat -F 32" ;;
    hfs+)       fs=hfsplus ;;
    *)          return 1 ;;
  esac

  # Make the filesystem
  tell parted -a optimal $dev mkpart $@ || return 1
  num=$(parted $dev print \
          | grep "^ \+[0-9]" \
          | tail -n 1 \
          | sed -e "s|^ \+\([0-9]\+\).*$|\1|")

  # Format it
  tell mkfs.${fs} ${dev}${num} || return 1

  # Name it (optional)
  [[ -n $1 ]] && tell parted ${dev}${num} name $1
}

function init() {
  # Prompt for partitioning
  fdisk -l | grep "Disk /dev"

  opt=$(dialog --menu "Partition Scheme:" --stdout 10 40 3 \
          0 'Linux Only' \
          1 'Linux and Windows' \
          2 'Linux, Windows and OSX')

  clear
  [[ -z $opt ]] && return 1

  # Get the disk to partition
  while true; do
    echo -n "Which disk to partition (or \`skip'): "
    read dev

    if [[ $dev =~ ^/dev/sd[a-z]$ || "$dev" == "skip" ]]; then
      break
    fi
  done

  # Make sure the user wants to do this
  confirm_parted $dev || return 1

  # Create table
  tell parted $dev mktable $TABLE

  # Create boot area
  mkpart $dev boot fat32 0 "${BOOT_SIZE}M"

  # Calculate swap space
  ram="$(cat /proc/meminfo | grep MemTotal | awk -e '{ print $2 }')"
  ram=$(echo "$ram / ($SWAP_DIV * 1000)" | bc)
  swap=$(round_up $ram 500)

  # Create swap space
  end=$((swap + BOOT_SIZE))
  mkpart $dev swap linux-swap "${BOOT_SIZE}M" "${end}M"

  # Get the size for the remaining partitions
  hd=$(fdisk -l /dev/sda \
         | head -n 1 \
         | sed -e "s/.* \([0-9]\+\) bytes.*/\1/")
  hd=$(echo "($hd / 1000000) - $end" | bc)
  part="$(echo "$hd / ($opt + 1)" | bc)"

  # Implement partition scheme
  # Linux
  if [[ "$opt" -ge "0" ]]; then
    mkpart $dev Arch ext4 "${end}M" "$((end + part))M"
    end=$((end + part))
  fi

  # Windows
  if [[ "$opt" -ge "1" ]]; then
    echo "win"
  fi

  # OSX
  if [[ "$opt" -ge "2" ]]; then
    mkpart $dev OSX hfs+ "${end}M" "$((end + part))M"
    end=$((end + part))
  fi

  return 1

  # Partition and automatically format
  if [[ "$dev" != "skip" ]]; then
    parted $dev print
    echo -n "Continue (y/n)? "
    read cont
    if [[ "$cont" != "y" ]]; then
      echo "Aborting..."
      return 1
    fi

    # Create a partition table
    parted $dev mktable

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

    cat $tmp

    rm $tmp
    return 1
  fi

  return 1

  cd $HOME/$DIST_DIR/
  ./configure
}

init
if [[ "$?" == "0" ]]; then
  reboot
fi
