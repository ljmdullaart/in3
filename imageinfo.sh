#!/bin/bash
#dontinstall@ /usr/local/bin/imageinfo
for pict in $* ; do
	if [ "$pict" != "--geom" ] ; then
		convert "$pict"  -print "%wx%h\n" /dev/null
	fi
done
