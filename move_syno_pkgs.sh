#!/bin/bash
SOURCE=/volume2
DEST=/volume1

APPDIR=\@appstore

ASK=true

while getopts ":y" opt; do
  case $opt in
    y)
	  ASK=false
	  ;;
	\?)
	  echo "Invalid option: -$OPTARG" >&2
	  exit 1
	  ;;
  esac
done

echo "This will move packages from $SOURCE to $DEST"
echo ""

if [ ! -d $DEST/$APPDIR ]; then
  mkdir $DEST/$APPDIR
  chmod 777 $DEST/$APPDIR
  echo "New app directory created"
fi

echo "Searching for packages on $SOURCE..."

for d in /var/packages/*
do
  [ -d "$d" ] || continue
  app=$(basename $d)
  symlink=$d/target

  if [ ! -e "$symlink" ]; then 
    echo "$app has no symlink"
	continue
  fi

  if [ ! -e "$SOURCE/$APPDIR/$app" ]; then
    echo "$app is not in source directory"
	continue
  fi

  if [ ! "$(readlink $symlink)" -ef "$SOURCE/$APPDIR/$app" ]; then
    echo "$app: Symlink doesn't point to source directory"
	continue
  fi

  echo "Found $app"

  file_warnings=$(find $d -type f -exec grep -l "$SOURCE" {} \;)
  if [ ! -z $file_warnings ]; then
    echo "Be careful!"
	echo "The following files contain '$SOURCE':"
	echo "$file_warnings"
  fi

  if $ASK; then
    read -s -p "`echo $'\t'`Move $app? (y/n)`echo $'\n \b'`" -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] || continue
    echo ""
  fi

  echo "`echo $'\t'`Moving $app..." 
  synopkgctl stop $app
  cp -rp $SOURCE/$APPDIR/$app $DEST/$APPDIR/
  rm -f $symlink
  ln -s $DEST/$APPDIR/$app $symlink
  mv $SOURCE/$APPDIR/$app $SOURCE/$APPDIR/__$app
  synopkgctl start $app
  echo "`echo $'\t'`Done. Backup in: $SOURCE/$APPDIR/__$app"
  echo ""
done

echo "Done for all."
echo ""

echo "If you want to remove $SOURCE you should also move the following:"
echo ""

for f in /var/services/*
do
  [ -L $f ] || continue
  target=$(readlink $f)
  if echo "$target" | grep -q $SOURCE; then
    echo "System service symlink $f to $target"
  fi
done