#!/bin/bash
#INSTALL@ /usr/local/bin/mk_cover

if [ -f coverimage.png ] ; then
	echo "Constructing cover..."
	echo $$
else
	echo "No coverimage.png; therefore exitting."
	exit 0
fi


b_img=/tmp/blank.$$.png
t_img=/tmp/title.$$.png
s_img=/tmp/sub.$$.png
a_img=/tmp/author.$$.png
i_img=/tmp/image.$$.png
temp_img=/tmp/tempimage.$$.png

title=$(grep '^.title ' *in | sed 's/.*:.title //' | sort -u)
subtitle=$(grep '^.subtitle ' *in | sed 's/.*:.subtitle //' | sort -u)
author=$(grep '^.author ' *in | sed 's/.*:.author //' | sort -u)

convert -size 1000x80 xc:white $b_img

if [ "$title" = "" ] ; then
	convert -size 1000x100 xc:white $t_img
else
	convert -fill black -font Nimbus-Sans-L-Bold -pointsize 80 -gravity center -size 1000x caption:"$title"	$t_img
fi
if [ "$subtitle" = "" ] ; then
	convert -size 1000x100 xc:white $s_img
else
	convert -fill black -font Nimbus-Sans-L-Regular-Italic -pointsize 60 -gravity center -size 1000x caption:"$subtitle"	$s_img
fi
if [ "$author" = "" ] ; then
	convert -size 1000x100 xc:white $a_img
else
	convert -fill black -font Nimbus-Sans-L -pointsize 60 -gravity center -size 1000x caption:"$author"	$a_img
fi

convert -trim  -resize 800x800 coverimage.png $temp_img
convert -extent 1000x1000 -gravity center $temp_img $i_img

convert $b_img $t_img $s_img $i_img $a_img $b_img -append cover.png


rm -f $b_img
rm -f $t_img
rm -f $s_img
rm -f $a_img
rm -f $i_img
rm -f $temp_img
