#!/bin/bash
#INSTALL@ /usr/local/bin/configyour.in
#__IN__CONFIGYOUR__
#VERSION 3


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
	(a-x*)	REMOTE_DIR="WWW/$wd"
		HOST=shell.xs4all.nl
		DEST=xs4all
		;;
	(a-z*)  REMOTE_DIR="$wd"
		HOST=homedrive.ziggo.nl
		DEST=ziggo
		;;
	(*)	echo "$0 does not understand $argument; try -h."
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
else
	echo 'tag/in: tag/in3.html tag/in3.pdf tag/in3.img' >> Makefile
	echo '	touch tag/in' >> Makefile
	echo 'tag/in'>>$CLEANFILE
	echo "total.in: $INFILES_noindex" >> Makefile
	echo "	cat $INFILES_noindex > total.in" >> Makefile
	echo 'total.in'>>$CLEANFILE
	#
	#	Make some in-files that are not yet there
	#
	mkinheader -i > index.in
	## odt-to-in
	ODTS=`ls *.odt 2> /dev/null | wc -l `
	if [ $ODTS != 0 ] ; then
		for FILE in *.odt ; do
			BASE=${FILE%%.odt}
			odt2txt --width=-1 $FILE > temporary.txt
			txt2in temporary.txt > $BASE.in
			rm temporary.txt 
		done
	fi

###  #     #  ######   #######  #     #  
 #   ##    #  #     #  #         #   #   
 #   # #   #  #     #  #          # #    
 #   #  #  #  #     #  #####       #     
 #   #   # #  #     #  #          # #    
 #   #    ##  #     #  #         #   #   
###  #     #  ######   #######  #     #  

	echo "index.in: $INFILES" >> Makefile
	echo "	mkinheader -i > index.in" >> Makefile
	echo "header: $INFILES" >> Makefile
	echo "	mkinheader -h > header" >> Makefile
	echo 'index.in'>>$CLEANFILE
	echo "index.htm: $INFILES" >> Makefile
	echo "	mkinheader -h > index.htm" >> Makefile
	echo 'index.htm'>>$CLEANFILE
###  #     #   ###   
 #   ##    #  #   #  
 #   # #   #      #  
 #   #  #  #   ###   
 #   #   # #      #  
 #   #    ##  #   #  
###  #     #   ###   
	DONE_TOTAL=0
	
	for FILE in $INBASE ; do
		if [ $FILE = total ] ; then DONE_TOTAL=1 ; fi
		echo "$FILE.in3: $FILE.in" >> Makefile
		echo "	in3 $FILE.in > $FILE.in3">>Makefile	
		echo "$FILE.in3">>$CLEANFILE
	done
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

	INHTML=`ls *.in | grep -v 'configure.in' | sort -n | sed 's/.in$/.html/' | paste -sd' '`
	echo "tag/in3.html: $INHTML" >> Makefile
	echo "	touch tag/in3.html" >> Makefile
	echo "tag/in3.html">>$CLEANFILE
	
	for FILE in $INBASE ; do
		echo "$FILE.html: $FILE.in3 header">>Makefile
		echo "	in3html $FILE.in3 > $FILE.html">>Makefile
		echo "$FILE.html">>$CLEANFILE
		echo "$FILE.html">>$UPLOADFILE
	done
	
######   ######   #######  
#     #  #     #  #        
#     #  #     #  #        
######   #     #  #####    
#        #     #  #        
#        #     #  #        
#        ######   #     

	INPDF=`ls *.in | grep -v 'configure.in'| grep -vi 'index.in' | grep -v total.in | sort -n | sed 's/.in$/.pdf/' | paste -sd' '`
	echo "tag/in3.pdf: total.pdf $INPDF" >> Makefile
	echo "	touch tag/in3.pdf" >> Makefile
	DONE_TOT=0
	for FILE in $INBASE ; do
		if [ $FILE = total ] ; then DONE_TOT=1 ; fi
		echo "$FILE.pdf: $FILE.ps">>Makefile
		echo "	cat $FILE.ps | ps2pdf - - > $FILE.pdf">>Makefile
		echo "$FILE.ps: $FILE.min">>Makefile
		echo "	groff -min $FILE.min > $FILE.ps">>Makefile
		echo "$FILE.min: $FILE.tbl">>Makefile
		echo "	tbl $FILE.tbl > $FILE.min">>Makefile
		echo "$FILE.tbl: $FILE.in3 tag/in3.img">>Makefile
		echo "	in3tbl $FILE.in3 > $FILE.tbl">>Makefile
		echo "$FILE.pdf">>$CLEANFILE
		echo "$FILE.pdf">>$UPLOADFILE
		echo "$FILE.ps">>$CLEANFILE
		echo "$FILE.min">>$CLEANFILE
		echo "$FILE.tbl">>$CLEANFILE
	done
	if [ $DONE_TOT = 0 ] ; then
		FILE=total
		echo "$FILE.pdf: $FILE.ps">>Makefile
		echo "	cat $FILE.ps | ps2pdf - - > $FILE.pdf">>Makefile
		echo "$FILE.ps: $FILE.min">>Makefile
		echo "	groff -min $FILE.min > $FILE.ps">>Makefile
		echo "$FILE.min: $FILE.tbl">>Makefile
		echo "	tbl $FILE.tbl > $FILE.min">>Makefile
		echo "$FILE.tbl: $FILE.in3 tag/in3.img">>Makefile
		echo "	in3tbl $FILE.in3 > $FILE.tbl">>Makefile
		echo "$FILE.pdf">>$CLEANFILE
		echo "$FILE.pdf">>$UPLOADFILE
		echo "$FILE.ps">>$CLEANFILE
		echo "$FILE.min">>$CLEANFILE
		echo "$FILE.tbl">>$CLEANFILE
	fi
		
		
	


###  #     #     #      #####   #######   #####   
 #   ##   ##    # #    #     #  #        #     #  
 #   # # # #   #   #   #        #        #        
 #   #  #  #  #     #  #  ####  #####     #####   
 #   #     #  #######  #     #  #              #  
 #   #     #  #     #  #     #  #        #     #  
###  #     #  #     #   #####   #######   #####   
	
	cat $INFILES | sed -n 's/^\.img //p' |
	while read IMAGE; do
		BASEIMAGE=${IMAGE%.*}
		ALLIMAGE="$ALLIMAGE $IMAGE"
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
	done
	sed -n  's/^.map *image *//p' *in >>$UPLOADFILE
	sed -n  's/^\.img *//p' *in >>$UPLOADFILE
	IMGFILES=`cat $INFILES | sed -n 's/^.img //p' | paste -sd ' '`
	echo "tag/in3.img: $IMGFILES |tag" >> Makefile
	echo "	touch tag/in3.img" >> Makefile
	echo "tag/in3.img">>$CLEANFILE
	# remark: eps files are done by in3tbl


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
		echo "	upload_all $UPLOADFILES">>Makefile
		echo "	touch tag/upload.in">>Makefile
	else
		echo "tag/upload.in: |tag">>Makefile
		echo "	echo 'The following files would qualify for upload if a destination file would exist:'">>Makefile
		echo  -n "	ls -l ">>Makefile
		grep -v index.pdf  $UPLOADFILE | paste -sd' '  >>Makefile
		echo "	touch tag/upload.in">>Makefile
	fi

fi
rm -f $CLEANFILE
rm -f $UPLOADFILE
exit 0


