#!/bin/bash
#INSTALL@ /usr/local/bin/configyour.in
#__IN__CONFIGYOUR__
#VERSION 3

WWWDIR=www
PDFDIR=pdf
EPUBDIR=epub


banner in3 >> Makefile
PWD=`pwd`
WD=`basename $PWD`
REST=''
TOREMOVE=''
REMOTE_DIR="WWW/$WD"
HOST=shell.xs4all.nl
DEST=xs4all
VERBOSE=0
CLEANFILE=/tmp/in.clean.$$
UPLOADFILE=/tmp/in.upload.$$

TMP=/tmp/in3.$$.tmp
if [ -f destination ] ; then
	. destination
fi

hellup(){
cat <<EOF
$0: template.in3 configurator
flags:
	-h[elp]     help screen
	-v[erbose]  be a bit more talkative

EOF
}

for argument in $* ; do
	case a$argument in
	(a-h*)	hellup
		;;
	(a-v*)	verbose=1
		;;
	esac
done


cat <<EOF
#  Starting configure with:
#    verbose    = $VERBOSE
#    host       = $HOST
#    remote_dir = $REMOTE_DIR
#    dest       = $DEST
#    pwd        = $PWD
#    wd         = $WD
EOF
  
ODTS=`ls *.odt 2> /dev/null | wc -l `
if [ $ODTS != 0 ] ; then
	for FILE in *.odt ; do
		BASE=${FILE%%.odt}
		odt2txt --width=-1 $FILE > temporary.txt
		txt2in temporary.txt > $BASE.in
		rm temporary.txt 
	done
fi


INFILES=`ls *.in | egrep -v 'total.in' | sort -n | paste -sd' '`
INFILES_noindex=`ls *.in | egrep -v 'index.in|total.in' | sort -n | paste -sd' '`
INBASE=`ls *.in | egrep -v 'configure.in' | sort -n | sed 's/.in$//' | paste -sd' '`

if [ "$INFILES" = "" ] ; then
	echo "No .in-files found"
	echo 'tag/in: |tag' >> Makefile
	echo '	touch tag/in' >> Makefile
	echo 'tag/in'>>$CLEANFILE
	echo 'tag/clean.in: |tag' >> Makefile
	echo '	touch tag/clean.in' >> Makefile
	echo 'tag/upload.in: |tag' >> Makefile
	echo '	touch tag/upload.in' >> Makefile
	exit 0
fi






echo 'tag/in: tag/in3.html tag/in3.pdf tag/in3.img' >> Makefile
echo '	touch tag/in' >> Makefile
echo 'tag/in'>>$CLEANFILE
#
#	Make some in-files that are not yet there
#
mkinheader -i > index.in
## odt-to-in

###  #     #  ######   #######  #     #        #######  #######  #######     #     #        
 #   ##    #  #     #  #         #   #            #     #     #     #       # #    #        
 #   # #   #  #     #  #          # #             #     #     #     #      #   #   #        
 #   #  #  #  #     #  #####       #              #     #     #     #     #     #  #        
 #   #   # #  #     #  #          # #             #     #     #     #     #######  #        
 #   #    ##  #     #  #         #   #            #     #     #     #     #     #  #        
###  #     #  ######   #######  #     #           #     #######     #     #     #  #######  


#     #  #######     #     ######   #######  ######   
#     #  #          # #    #     #  #        #     #  
#     #  #         #   #   #     #  #        #     #  
#######  #####    #     #  #     #  #####    ######   
#     #  #        #######  #     #  #        #   #    
#     #  #        #     #  #     #  #        #    #   
#     #  #######  #     #  ######   #######  #     # 
echo "index.in: $INFILES_noindex" >> Makefile
echo "	mkinheader -i > index.in" >> Makefile
echo 'index.in'>>$CLEANFILE
echo "total.in: $INFILES_noindex" >> Makefile
echo "	cat $INFILES_noindex > total.in" >> Makefile
echo 'total.in'>>$CLEANFILE
echo "header: $INFILES" >> Makefile
echo "	mkinheader -h > header" >> Makefile
echo 'header'>>$CLEANFILE

###  #     #   ###   
 #   ##    #  #   #  
 #   # #   #      #  
 #   #  #  #   ###   
 #   #   # #      #  
 #   #    ##  #   #  
###  #     #   ###   
#There may or may not be an index.in or total.in in this dir
#therefore use some flags to determine whether they're done or not.
DONE_TOTAL=0
DONE_INDEX=0
for FILE in $INBASE ; do
	if [ $FILE = total ] ; then DONE_TOTAL=1 ; fi
	if [ $FILE = index ] ; then DONE_INDEX=1 ; fi
	echo "$FILE.in3: $FILE.in" >> Makefile
	echo "	in3 $FILE.in > $FILE.in3">>Makefile	
	echo "$FILE.in3">>$CLEANFILE
done
if [ $DONE_INDEX = 0 ] ; then
	FILE=index
	echo "$FILE.in3: $FILE.in" >> Makefile
	echo "	in3 $FILE.in > $FILE.in3">>Makefile	
	echo "$FILE.in3">>$CLEANFILE
fi
if [ $DONE_TOTAL = 0 ] ; then
	FILE=total
	echo "$FILE.in3: $FILE.in" >> Makefile
	echo "	in3 $FILE.in > $FILE.in3">>Makefile	
	echo "$FILE.in3">>$CLEANFILE
fi

#     #  #######  #     #  #        
#     #     #     ##   ##  #        
#     #     #     # # # #  #        
#######     #     #  #  #  #        
#     #     #     #     #  #        
#     #     #     #     #  #        
#     #     #     #     #  ####### 

DONE_TOTAL=0
DONE_INDEX=0

INHTML=`ls *.in | sort -n | sed 's/.in$/.html/' |sed "s/^/$WWWDIR\//"| paste -sd' '`
if [ ! -f index.in ] ; then INHTML="INHTML $WWWDIR/index.html" ; fi
if [ ! -f total.in ] ; then INHTML="INHTML $WWWDIR/total.html" ; fi
echo "tag/in3.html: $INHTML" >> Makefile
echo "	touch tag/in3.html" >> Makefile
echo "tag/in3.html">>$CLEANFILE

add_www(){
	echo "$WWWDIR/$1.html: $1.in3 header |$WWWDIR ">>Makefile
	echo "	in3html $1.in3 > $WWWDIR/$1.html">>Makefile
	echo "$WWWDIR/$1.html">>$CLEANFILE
	echo "$WWWDIR/$1.html">>$UPLOADFILE
}
for FILE in $INBASE ; do
	if [ $FILE = total ] ; then DONE_TOTAL=1 ; fi
	if [ $FILE = index ] ; then DONE_INDEX=1 ; fi
	add_www $FILE
done
echo "index.htm: $INFILES" >> Makefile
echo "	mkinheader -h > index.htm" >> Makefile
echo 'index.htm'>>$CLEANFILE

if [ $DONE_INDEX = 0 ] ; then
	add_www index
fi
if [ $DONE_TOTAL = 0 ] ; then
	add_www total
fi

echo "www:" >> Makefile
echo "	mkdir www" >> Makefile
######   ######   #######  
#     #  #     #  #        
#     #  #     #  #        
######   #     #  #####    
#        #     #  #        
#        #     #  #        
#        ######   #     

INPDF=`ls *.in | sort -n | sed "s/.in$/.pdf/;s/^/$PDFDIR\//" | paste -sd' '`
echo "tag/in3.pdf: $PDFDIR/total.pdf $INPDF" >> Makefile
echo "	touch tag/in3.pdf" >> Makefile
DONE_TOTAL=0
DONE_INDEX=0
 
add_pdf(){
	echo "$PDFDIR/$1.pdf: $PDFDIR/$1.ps">>Makefile
	echo "	cat $PDFDIR/$1.ps | ps2pdf - - > $PDFDIR/$1.pdf">>Makefile
	echo "$PDFDIR/$1.ps: $PDFDIR/$1.min">>Makefile
	echo "	groff -min $PDFDIR/$1.min > $PDFDIR/$1.ps">>Makefile
	echo "$PDFDIR/$1.min: $PDFDIR/$1.tbl">>Makefile
	echo "	tbl $PDFDIR/$1.tbl > $PDFDIR/$1.min">>Makefile
	echo "$PDFDIR/$1.tbl: $1.in3 tag/in3.img |$PDFDIR">>Makefile
	echo "	in3tbl $1.in3 > $PDFDIR/$1.tbl">>Makefile
	echo "$PDFDIR/$1.pdf">>$CLEANFILE
	echo "$PDFDIR/$1.pdf">>$UPLOADFILE
	echo "$PDFDIR/$1.ps">>$CLEANFILE
	echo "$PDFDIR/$1.min">>$CLEANFILE
	echo "$PDFDIR/$1.tbl">>$CLEANFILE
}
 
for FILE in $INBASE ; do
	if [ $FILE = total ] ; then DONE_TOTAL=1 ; fi
	if [ $FILE = index ] ; then DONE_INDEX=1 ; fi
	add_pdf $FILE
done
if [ $DONE_TOTAL = 0 ] ; then
	add_pdf total
fi
if [ $DONE_INDEX = 0 ] ; then
	add_pdf index
fi
	
echo "pdf:" >> Makefile
echo "	mkdir pdf" >> Makefile
	



###  #     #     #      #####   #######   #####   
 #   ##   ##    # #    #     #  #        #     #  
 #   # # # #   #   #   #        #        #        
 #   #  #  #  #     #  #  ####  #####     #####   
 #   #     #  #######  #     #  #              #  
 #   #     #  #     #  #     #  #        #     #  
###  #     #  #     #   #####   #######   #####   
ALLIMAGE=""

mk_images(){
	BASEIMAGE=${IMAGE%.*}
	ALLIMAGE="$ALLIMAGE $IMAGE $BASEIMAGE.eps"
	if [ -f $BASEIMAGE.xcf ] ; then
		echo "$IMAGE: $BASEIMAGE.xcf" >> Makefile
		echo "	convert $BASEIMAGE.xcf $IMAGE" >> Makefile
		echo "$IMAGE">>$CLEANFILE
		echo "$IMAGE">>$UPLOADFILE
	fi
	if [ -f $BASEIMAGE.dia ] ; then
		echo "$IMAGE: $BASEIMAGE.dia" >> Makefile
		echo "	dia --export=$IMAGE $BASEIMAGE.dia" >> Makefile
		echo "$IMAGE">>$CLEANFILE
		echo "$IMAGE">>$UPLOADFILE
	fi
	echo "$BASEIMAGE.eps: $IMAGE" >> Makefile
	echo "	convert $IMAGE $BASEIMAGE.eps" >> Makefile
	
}

cat $INFILES | sed -n 's/^\.img *//p' | sed 's/ .*//'|sort -u|
while read IMAGE; do
	mk_images
done

cat $INFILES | sed -n 's/^\.map image *//p' | sed 's/ .*//'|sort -u|
while read IMAGE; do
	mk_images
done

IMGFILES=`cat $INFILES | sed -n 's/^.img //p'  | sed 's/ .*//'| paste -sd ' '`
MAPFILES=`cat $INFILES | sed -n 's/^.map image *//p' | sed 's/ .*//'| paste -sd ' '`

echo "tag/in3.img: $IMGFILES $MAPFILES |tag" >> Makefile
echo "	cp $IMGFILES $MAPFILES $WWWDIR">> Makefile
echo "	touch tag/in3.img" >> Makefile
echo "tag/in3.img">>$CLEANFILE

sed -n  "s/^.map *image */$WWWDIR\//p" *in >>$UPLOADFILE
sed -n  "s/^\.img */$WWWDIR\//p" *in | sed 's/ .*//' >>$UPLOADFILE


 #####   ######   #######           #      #####          #####    #####   #     #  ######    #####   #######  
#     #  #     #     #             # #    #     #        #     #  #     #  #     #  #     #  #     #  #        
#     #  #     #     #            #   #   #              #        #     #  #     #  #     #  #        #        
#     #  #     #     #           #     #   #####          #####   #     #  #     #  ######   #        #####    
#     #  #     #     #           #######        #              #  #     #  #     #  #   #    #        #        
#     #  #     #     #           #     #  #     #        #     #  #     #  #     #  #    #   #     #  #        
 #####   ######      #           #     #   #####          #####    #####    #####   #     #   #####   #######  

## odt-to-in
ODTS=`ls *.odt 2> /dev/null | wc -l `
if [ $ODTS != 0 ] ; then
	for FILE in *.odt ; do
		BASE=${FILE%%.odt}
		echo "$BASE.in: $FILE" >> Makefile
		echo "	odt2txt --width=-1 $FILE > temporary.txt" >> Makefile
		echo "	txt2in temporary.txt > $BASE.in" >> Makefile
		echo "	rm temporary.txt " >> Makefile
		echo "$BASE.in">>$CLEANFILE
	done
fi

 #####   #        #######     #     #     #  
#     #  #        #          # #    ##    #  
#        #        #         #   #   # #   #  
#        #        #####    #     #  #  #  #  
#        #        #        #######  #   # #  
#     #  #        #        #     #  #    ##  
 #####   #######  #######  #     #  #     #  

echo "tag/clean.in:" >> Makefile
cat $CLEANFILE | while read F ; do
	echo "	rm -f $F" >> Makefile
done
echo "	touch tag/clean.in" >> Makefile

rm -f $CLEANFILE
	



#     #  ######   #         #####      #     ######   
#     #  #     #  #        #     #    # #    #     #  
#     #  #     #  #        #     #   #   #   #     #  
#     #  ######   #        #     #  #     #  #     #  
#     #  #        #        #     #  #######  #     #  
#     #  #        #        #     #  #     #  #     #  
 #####   #        #######   #####   #     #  ######   
if [ -f destination ] ; then
	if [ -f stylesheet.css ] ; then
		echo stylesheet.css >> $UPLOADFILE
	fi
	if [ -f UPLOAD ] ; then
		UPLOADFILES=`cat $UPLOADFILE UPLOAD | paste -sd' '`
	else
		UPLOADFILES=`cat $UPLOADFILE | paste -sd' '`
	fi
	echo "tag/upload.in: $UPLOADFILES |tag">>Makefile
	echo "	upload_all -f  $UPLOADFILES">>Makefile
	echo "	touch tag/upload.in">>Makefile
else
	echo "tag/upload.in: |tag">>Makefile
	echo "	echo 'The following files would qualify for upload if a destination file would exist:'">>Makefile
	echo  -n "	ls -l ">>Makefile
	grep -v index.pdf  $UPLOADFILE | paste -sd' '  >>Makefile
	echo "	touch tag/upload.in">>Makefile
fi

rm -f $CLEANFILE
rm -f $UPLOADFILE
exit 0



