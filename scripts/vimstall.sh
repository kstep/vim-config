#!/bin/sh

unpack_file ()
{
	UNPACKER=
	REALPATH=`readlink -f "$1"`
	case $REALPATH in
		*.tgz|*.tar.gz)
		UNPACKER="tar xzf"
		;;
		*.tbz|*.tar.bz2)
		UNPACKER="tar xjf"
		;;
		*.zip)
		UNPACKER="unzip"
		;;
		*.gz)
		UNPACKER="gunzip"
		;;
		*.bz2)
		UNPACKER="bunzip2"
		;;
	esac
	if test ! -z "$UNPACKER"; then
		TMPDIR=`mktemp -d /tmp/vimstall.XXXXXXX`
		cd $TMPDIR
		$UNPACKER "$REALPATH" > /dev/null 2>&1
		echo $TMPDIR
	fi
}

install_file ()
{
	IFILE="$1"
	FNAME=`basename "$IFILE"`

	case $FNAME in
		*.vim)
			mkdir -p $VIMDIR/plugin
			cp "$IFILE" $VIMDIR/plugin/
		;;
		*.vba)
			vim "$IFILE" -c ":so %" -c ":q"
		;;
		plugin|doc|autoload|syntax|ftplugin|ftdetect|indent|colors)
			test -d $IFILE && cp -r $IFILE $VIMDIR
		;;
		*.zip|*.gz|*.bz2|*.tbz|*.tgz|*.tar.gz|*.tar.bz2)
			TMPDIR=`unpack_file "$IFILE"`
			if test ! -z "$TMPDIR"; then
				CURDIR=`pwd`
				cd $TMPDIR
				for f in *; do install_file "$f"; done
				cd $CURDIR
				rm -rf $TMPDIR
			fi
		;;
		*)
		echo "Unknown file: $IFILE" >&2
		;;
	esac
}

VIMDIR=~/.vim
IFILE="$1"

if test -z "$IFILE"; then
	SELF=`basename $0`
	echo
	echo "Vimstall is a script to install vim plugins automatically."
	echo
	echo "Syntax:"
	echo -e "\t$SELF \<filename\>\|\<dirname\>"
	echo
	echo "If you run the script on filename it is treated as vim plugin, if run on directory"
	echo "it will try to install all files from this directory like they all are vim plugins."
	echo
	echo "Vimstall supports vimballs (vim is run to install them), simple vim files"
	echo "(they are treated as sinlge plugin and is copied into ~/.vim/plugin/ directory"
	echo "and packed files (zips & tarballs) in which case archive must contain either"
	echo "vim/vimball file or packed installation of a plugin (i.e. directories to put into"
	echo "~/.vim like \`doc', \`plugin', \`autoload' etc.)"
	echo
	echo "If during installation process the script runs into some unknown file, it will"
	echo "report this file's name into stderr."
	echo
	echo "This script can be used with \`downloadvimscripts' script to update & install"
	echo "vim plugins automatically."
	echo
fi

if test -d "$1"; then
	for i in $1/*; do install_file "$i"; done
elif test -f "$1"; then
	install_file "$1"
fi
