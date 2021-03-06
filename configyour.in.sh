#!/bin/bash
#INSTALL@ /usr/local/bin/configyour.in
#__IN__CONFIGYOUR__
#VERSION 3

WWWDIR=www
PDFDIR=pdf
EPUBDIR=epub
HTMLDIR=html
TXTDIR=text

LOG=configyour.log
echo "configour.in3 starting" >>$LOG
PWD=$(pwd)
WD=$(basename $PWD)
REST=''
REMOTE_DIR="WWW/$WD"
HOST=shell.xs4all.nl
DEST=xs4all
CLEANFILE=/tmp/in.clean.$$
UPLOADFILE=/tmp/in.upload.$$

if [ -x /usr/local/bin/my_banner ] ; then
    banner=/usr/local/bin/my_banner
else
    banner=banner
fi


$banner in3 >> Makefile

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

for argument in "$@" ; do
	case a$argument in
	(a-h*)	hellup
		;;
	esac
done


cat >> $LOG  <<EOF
#  Starting configure with:
#    host       = $HOST
#    remote_dir = $REMOTE_DIR
#    dest       = $DEST
#    pwd        = $PWD
#    wd         = $WD
EOF
  
ODTS=$(ls *.odt 2> /dev/null | wc -l )
if [ $ODTS != 0 ] ; then
	for FILE in *.odt ; do
		BASE=${FILE%%.odt}
		odt2txt --width=-1 $FILE > temporary.txt
		txt2in temporary.txt > $BASE.in
		rm -f temporary.txt 
	done
fi


INFILES=$(ls *.in  2> /dev/null | egrep -v 'total.in|complete.in' | sort -n | paste -sd' ')
INFILES_noindex=$(ls *.in  2> /dev/null | egrep -v 'index.in|total.in|complete.in'| sort -n | paste -sd' ')
INBASE=$(ls *.in  2> /dev/null | egrep -v 'configure.in' | sort -n | sed 's/.in$//' | paste -sd' ')

if [ "$INFILES" = "" ] ; then
	echo "No .in-files found" >>$LOG
	echo "No .in-files found" 
	echo 'tag/in: |tag' >> Makefile
	echo '	touch tag/in' >> Makefile
	echo 'tag/in'>>$CLEANFILE
	echo 'tag/clean.in: |tag' >> Makefile
	echo '	touch tag/clean.in' >> Makefile
	echo 'tag/upload.in: |tag' >> Makefile
	echo '	touch tag/upload.in' >> Makefile
	echo "configour.in3 finishing" >>$LOG
	exit 0
fi

if [ -d in3xml ] ; then
	echo "Superior in3xml found" >>$LOG
	echo "Superior in3xml found"
	echo 'tag/in: |tag' >> Makefile
	echo '	touch tag/in' >> Makefile
	echo 'tag/in'>>$CLEANFILE
	echo 'tag/clean.in: |tag' >> Makefile
	echo '	touch tag/clean.in' >> Makefile
	echo 'tag/upload.in: |tag' >> Makefile
	echo '	touch tag/upload.in' >> Makefile
	echo "configour.in3 finishing" >>$LOG
	exit 0
fi






echo -n 'tag/in: ' >> Makefile
if [ -d  $WWWDIR ] ; then  echo -n 'tag/in3.www ' >> Makefile ; fi
if [ -d  $HTMLDIR ] ; then  echo -n 'tag/in3.html ' >> Makefile ; fi
if [ -d  $PDFDIR ] ; then  echo -n 'tag/in3.pdf ' >> Makefile ; fi
if [ -d  $TXTDIR ] ; then  echo -n 'tag/in3.txt ' >> Makefile ; fi
if [ -d  $EPUBDIR ] ; then  echo -n 'tag/in3.epub ' >> Makefile ; fi
echo    'tag/in3.img' >> Makefile
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
if [ -f index.top ] ; then
	index_top_bottom=index.top
fi
if [ -f index.bottom ] ; then
	index_top_bottom="$index_top_bottom index.bottom"
fi
if grep "index.in:" Makefile >> $LOG ; then
	echo "Someone already made index.in" >> $LOG
else
	echo "index.in: $INFILES_noindex $index_top_bottom" >> Makefile
	echo "	mkinheader -i > index.in" >> Makefile
	echo 'index.in'>>$CLEANFILE
fi
echo "total.in: $INFILES_noindex" >> Makefile
echo "	grep -vh '^\.header'  $INFILES_noindex > total.in" >> Makefile
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

if [ -d $HTMLDIR ] ; then
	DONE_TOTAL=0
	DONE_INDEX=0
	
	INHTML=$(ls *.in  2> /dev/null | sort -n | sed 's/.in$/.html/' |sed "s/^/$HTMLDIR\//"| paste -sd' ')
	if [ ! -f index.in ] ; then INHTML="$INHTML $HTMLDIR/index.html" ; fi
	if [ ! -f total.in ] ; then INHTML="$INHTML $HTMLDIR/total.html" ; fi
	echo "tag/in3.html: $INHTML $HTMLDIR/header.htm" >> Makefile

	echo "	@cp block_*.png $HTMLDIR 2>/dev/null || echo 'no blocks to copy'" >> Makefile
	echo "	@cp block/*.png $HTMLDIR 2>/dev/null || echo 'no blocks in dir to copy'" >> Makefile
	echo "	touch tag/in3.html" >> Makefile
	echo "tag/in3.html">>$CLEANFILE
	
	echo "$HTMLDIR/header.htm: index.in" >> Makefile
	echo "	mkinheader > $HTMLDIR/header.htm" >> Makefile
	add_html(){
		echo "$HTMLDIR/$1.html: $1.in3 header |$HTMLDIR ">>Makefile
		echo "	in3html -n --partonly  $1.in3 > $HTMLDIR/$1.html">>Makefile
		echo "$HTMLDIR/$1.html">>$CLEANFILE
	}
	for FILE in $INBASE ; do
		if [ $FILE = total ] ; then DONE_TOTAL=1 ; fi
		if [ $FILE = index ] ; then DONE_INDEX=1 ; fi
		add_html $FILE
	done
	
	if [ $DONE_INDEX = 0 ] ; then
		add_html index
	fi
	if [ $DONE_TOTAL = 0 ] ; then
		add_html total
	fi
	echo "$HTMLDIR:" >> Makefile
	echo "	mkdir $HTMLDIR" >> Makefile
fi

#     #        #     #        #     #  
#  #  #        #  #  #        #  #  #  
#  #  #        #  #  #        #  #  #  
#  #  #        #  #  #        #  #  #  
#  #  #        #  #  #        #  #  #  
#  #  #        #  #  #        #  #  #  
 ## ##          ## ##          ## ##   

if [ -d $WWWDIR ] ; then
	DONE_TOTAL=0
	DONE_INDEX=0
	
	INHTML=$(ls *.in  2> /dev/null | sort -n | sed 's/.in$/.html/' |sed "s/^/$WWWDIR\//"| paste -sd' ')
	if [ ! -f index.in ] ; then INHTML="$INHTML $WWWDIR/index.html" ; fi
	if [ ! -f total.in ] ; then INHTML="$INHTML $WWWDIR/total.html" ; fi
	echo "tag/in3.www: $INHTML" >> Makefile
	echo "	touch tag/in3.www" >> Makefile
	echo "tag/in3.www">>$CLEANFILE

	if [ -f stylesheet.css ] ; then
		echo "$WWWDIR/stylesheet.css: stylesheet.css |$WWWDIR ">>Makefile
		echo "	@cp stylesheet.css $WWWDIR 2>/dev/null || echo 'no stylesheet to copy'">>Makefile
		echo "$WWWDIR/stylesheet.css">>$CLEANFILE
		echo "$WWWDIR/stylesheet.css">>$UPLOADFILE
	fi
	
	add_www(){
		echo "$WWWDIR/$1.html: $1.in3 header |$WWWDIR ">>Makefile
		echo "	in3html $1.in3 > $WWWDIR/$1.html">>Makefile
		echo "	@cp block/*.png $WWWDIR 2>/dev/null || echo 'No blocks to copy'" >> Makefile
	#	if grep '^\.BLOCK' $1.in*  > /dev/null ; then
	#		echo "	@cp block_*.png $WWWDIR 2>/dev/null || echo 'No blocks to copy'" >> Makefile
	#		echo "	@cp block/*.png $WWWDIR  2>/dev/null || echo 'No blocks in dir to copy'" >> Makefile
	#		echo "$WWWDIR/block_*png">>$CLEANFILE
	#	fi
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
	echo "$WWWDIR:" >> Makefile
	echo "	mkdir $WWWDIR" >> Makefile
fi
	

#######  ######   #     #  ######   
#        #     #  #     #  #     #  
#        #     #  #     #  #     #  
#####    ######   #     #  ######   
#        #        #     #  #     #  
#        #        #     #  #     #  
#######  #         #####   ######   


if [ -d $EPUBDIR ] ; then
	DONE_TOTAL=0
	DONE_INDEX=0
	pub_opt="--remove-paragraph-spacing-indent-size 0";
	
	INHTML=$(ls *.in  2> /dev/null | sort -n | sed 's/.in$/.html/' |sed "s/^/$EPUBDIR\//"| paste -sd' ')
	if [ ! -f index.in ] ; then INHTML="$INHTML $EPUBDIR/index.html" ; fi
	if [ ! -f total.in ] ; then INHTML="$INHTML $EPUBDIR/total.html" ; fi

	TITLE=$(grep '^.title '  *in | sed 's/.*:.title //;s/"/''/g' | sort -u | head -1)
	if [ "$TITLE" = "" ] ; then TITLE=$WD ; fi
	pub_opt="$pub_opt --title \"$TITLE\"";

	AUTHOR=$(grep '^.author '  *in | sed 's/.*:.author //' | sort -u | head -1)
	if [ "$AUTHOR" != "" ] ; then 
		pub_opt="$pub_opt --authors '$AUTHOR'";
	fi

	COVER=$(sed -n 's/^\.cover //p' *.in | head -1)
	if [ "$COVER" != "" ] ; then
		pub_opt="$pub_opt --cover $COVER"
	fi
	
	echo "tag/in3.epub: $EPUBDIR/$WD.epub" >> Makefile
	echo "	touch tag/in3.epub" >> Makefile
	echo "$EPUBDIR/$WD.epub: $INHTML $EPUBDIR/index.html" >> Makefile
	echo "	@cp *.png $EPUBDIR 2>/dev/null || echo 'no png to copy'" >> Makefile
	echo "	@cp block/*.png $EPUBDIR 2>/dev/null || echo 'no png from blockdir to copy'" >> Makefile
	if [ -f epubstylesheet.css ] ; then
		echo "	@cp epubstylesheet.css $EPUBDIR/stylesheet.css 2>/dev/null ||echo 'no epub stylesheet to copy'" >> Makefile
	elif [ -f stylesheet.css ] ; then
		echo "	@cp stylesheet.css $EPUBDIR 2>/dev/null ||echo 'no epub stylesheet to copy'" >> Makefile
	fi
	echo "	cd $EPUBDIR ; ebook-convert index.html $WD.epub $pub_opt" >> Makefile
	echo "tag/in3.epub">>$CLEANFILE
	echo "$EPUBDIR/$WD.epub">>$UPLOADFILE
	add_www(){
		echo "$EPUBDIR/$1.html: $1.in3 header |$EPUBDIR ">>Makefile
		echo "	in3html -n  $1.in3 > $EPUBDIR/$1.html">>Makefile
		echo "$EPUBDIR/$1.html">>$CLEANFILE
	}
	for FILE in $INBASE ; do
		if [ $FILE = total ] ; then DONE_TOTAL=1 ; fi
		if [ $FILE = index ] ; then
			DONE_INDEX=1
		else
			add_www $FILE
		fi
	done
	
	echo "$EPUBDIR/index.html: $EPUBDIR/index.in3 |$EPUBDIR ">>Makefile
	echo "	in3html <$EPUBDIR/index.in3 >$EPUBDIR/index.html">>Makefile
	echo "$EPUBDIR/index.in3:$EPUBDIR/index.in |$EPUBDIR ">>Makefile
	echo "	in3 < $EPUBDIR/index.in >$EPUBDIR/index.in3">>Makefile
	echo "$EPUBDIR/index.in: index.in">>Makefile
	echo "	mkinheader -t -i > $EPUBDIR/index.in">>Makefile
	echo "$EPUBDIR/index.html">>$CLEANFILE
	if [ $DONE_TOTAL = 0 ] ; then
		add_www total
	fi
	
	echo "$EPUBDIR:" >> Makefile
	echo "	mkdir $EPUBDIR" >> Makefile
fi
##### ###### #    # ##### 
  #   #       #  #    #   
  #   #####    ##     #   
  #   #        ##     #   
  #   #       #  #    #   
  #   ###### #    #   #   

if [ -d $TXTDIR ] ; then
	INTXT=$(ls *.in  2> /dev/null | sort -n | sed "s/.in$/.txt/;s/^/$TXTDIR\//" | paste -sd' ')
	echo "tag/in3.txt: $TXTDIR/total.txt $INTXT" >> Makefile
	echo "	touch tag/in3.txt" >> Makefile
	DONE_TOTAL=0
	DONE_INDEX=0
	 
	add_txt(){
		echo "$TXTDIR/$1.txt: $TXTDIR/$1.min">>Makefile
		echo "	nroff -min $TXTDIR/$1.min > $TXTDIR/$1.txt">>Makefile
		echo "$TXTDIR/$1.min: $TXTDIR/$1.tbl">>Makefile
		echo "	tbl $TXTDIR/$1.tbl > $TXTDIR/$1.min">>Makefile
		echo "$TXTDIR/$1.tbl: $1.in3 tag/in3.img |$TXTDIR">>Makefile
		echo "	egrep -v '^{BLOCK' $1.in3 | in3tbl > $TXTDIR/$1.tbl">>Makefile
		echo "$TXTDIR/$1.txt">>$UPLOADFILE
		echo "$TXTDIR/$1.min">>$CLEANFILE
		echo "$TXTDIR/$1.tbl">>$CLEANFILE
	}
	for FILE in $INBASE ; do
		if [ $FILE = total ] ; then DONE_TOTAL=1 ; fi
		if [ $FILE = index ] ; then DONE_INDEX=1 ; fi
		add_txt $FILE
	done
	if [ $DONE_TOTAL = 0 ] ; then
		add_txt total
	fi
	if [ $DONE_INDEX = 0 ] ; then
		add_txt index
	fi
	echo "$TXTDIR:" >> Makefile
	echo "	mkdir $TXTDIR" >> Makefile

fi
######   ######   #######  
#     #  #     #  #        
#     #  #     #  #        
######   #     #  #####    
#        #     #  #        
#        #     #  #        
#        ######   #     
if [ -d $PDFDIR ] ; then
	INPDF=$(ls *.in  2> /dev/null | sort -n | sed "s/.in$/.pdf/;s/^/$PDFDIR\//" | paste -sd' ')
	echo "tag/in3.pdf: $PDFDIR/total.pdf $INPDF" >> Makefile
	echo "	touch tag/in3.pdf" >> Makefile
	DONE_TOTAL=0
	DONE_INDEX=0
	 
	add_pdf(){
		echo "$PDFDIR/$1.pdf: $PDFDIR/$1.ps">>Makefile
		echo "	cat $PDFDIR/$1.ps | ps2pdf - - > $PDFDIR/$1.pdf">>Makefile
		echo "$PDFDIR/$1.ps: $PDFDIR/$1.min">>Makefile
		echo "	groff -min  -Kutf8 $PDFDIR/$1.min > $PDFDIR/$1.ps">>Makefile
		echo "$PDFDIR/$1.min: $PDFDIR/$1.tbl">>Makefile
		echo "	preconv $PDFDIR/$1.tbl | pic | tbl | eqn > $PDFDIR/$1.min">>Makefile
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
		
	echo "$PDFDIR:" >> Makefile
	echo "	mkdir $PDFDIR" >> Makefile
		
fi


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
	if [ "$BASEIMAGE" = "cover.png" ] && [ -f coverimage.png ] ; then
		mk_cover
	elif [ -f $BASEIMAGE.xcf ] ; then
		echo "$IMAGE: $BASEIMAGE.xcf" >> Makefile
		echo "	convert $BASEIMAGE.xcf $IMAGE" >> Makefile
		echo "$IMAGE">>$CLEANFILE
		echo "$IMAGE">>$UPLOADFILE
	#elif [ -f $BASEIMAGE.dia ] ; then
		#echo "$IMAGE: $BASEIMAGE.dia" >> Makefile
		#echo "	dia --export=$IMAGE $BASEIMAGE.dia" >> Makefile
		#echo "$IMAGE">>$CLEANFILE
		#echo "$IMAGE">>$UPLOADFILE
	elif [ -f $BASEIMAGE.gnuplot ] ; then
		echo "$IMAGE: $BASEIMAGE.gnuplot" >> Makefile
		echo "	gnuplot $BASEIMAGE.gnuplot" >> Makefile
		echo "$IMAGE">>$CLEANFILE
		echo "$IMAGE">>$UPLOADFILE
	elif [ -f $BASEIMAGE.eqn ] ; then
		echo "$IMAGE: $BASEIMAGE.eqn" >> Makefile
		echo "	eqn $BASEIMAGE.eqn > $BASEIMAGE.groff" >> Makefile
		echo "	groff  -Kutf8 $BASEIMAGE.groff > $BASEIMAGE.ps" >> Makefile
		echo "	ps2pdf $BASEIMAGE.ps > $BASEIMAGE.pdf" >> Makefile
		echo "	convert -trim -density 600 $BASEIMAGE.pdf  $IMAGE" >> Makefile
		echo "	rm $BASEIMAGE.groff $BASEIMAGE.ps $BASEIMAGE.pdf" >> Makefile
	fi
	echo "$BASEIMAGE.eps: $IMAGE" >> Makefile
	echo "	convert $IMAGE $BASEIMAGE.eps" >> Makefile
	echo "$BASEIMAGE.eps" >>$CLEANFILE
	
}

CURIMG=$(cat $INFILES | sed -n 's/ LEFT / /; s/ RIGHT / /;s/^\.img *//p' | sed 's/ .*//'|sort -u)
for IMAGE in $CURIMG ; do
	mk_images
	BASEIMAGE=${IMAGE%.*}
	TMPA="$ALLIMAGE $IMAGE"
	ALLIMAGE=$TMPA
done

CURIMG=$(cat $INFILES | sed -n 's/^\.map image *//p' | sed 's/ .*//'|sort -u)
for IMAGE in $CURIMG ; do
	mk_images
	BASEIMAGE=${IMAGE%.*}
	TMPA="$ALLIMAGE $IMAGE"
	ALLIMAGE=$TMPA
done

CURIMG=$(cat $INFILES | sed -n 's/^\.cover *//p' | sed 's/ .*//'|sort -u)
for IMAGE in $CURIMG ; do
	mk_images
	BASEIMAGE=${IMAGE%.*}
	TMPA="$ALLIMAGE $IMAGE"
	ALLIMAGE=$TMPA
done

#IMGFILES=$(cat $INFILES | sed -n 's/^.img //p'  | sed 's/ .*//'| paste -sd ' ')
#COVERS=$(cat $INFILES | sed -n 's/^.cover //p'  | sed 's/ .*//'| paste -sd ' ')
#MAPFILES=$(cat $INFILES | sed -n 's/^.map image *//p' | sed 's/ .*//'| paste -sd ' ')

echo "tag/in3.img: $ALLIMAGE|tag" >> Makefile
if [ -d $EPUBDIR ] ; then
	echo "	@cp $ALLIMAGE $EPUBDIR  2>/dev/null || echo 'No files to copy'">> Makefile
	echo "	rm -f $EPUBDIR/*.eps">> Makefile

fi
if [ -d $WWWDIR ] ; then
	if [ "$ALLIMAGE" != "" ] ; then
		echo "	@cp $ALLIMAGE $WWWDIR  2>/dev/null || echo 'No files to copy'">> Makefile
		echo "	rm -f $WWWDIR/*.eps">> Makefile
	fi
fi
echo "	touch tag/in3.img" >> Makefile
echo "tag/in3.img">>$CLEANFILE
if [ -d $WWWDIR ] ; then
	sed -n  "s/^.map *image */$WWWDIR\//p" *in >>$UPLOADFILE
	sed -n  "s/^\.img */$WWWDIR\//p" *in | sed 's/ .*//' >>$UPLOADFILE
fi


 #####   ######   #######           #      #####          #####    #####   #     #  ######    #####   #######  
#     #  #     #     #             # #    #     #        #     #  #     #  #     #  #     #  #     #  #        
#     #  #     #     #            #   #   #              #        #     #  #     #  #     #  #        #        
#     #  #     #     #           #     #   #####          #####   #     #  #     #  ######   #        #####    
#     #  #     #     #           #######        #              #  #     #  #     #  #   #    #        #        
#     #  #     #     #           #     #  #     #        #     #  #     #  #     #  #    #   #     #  #        
 #####   ######      #           #     #   #####          #####    #####    #####   #     #   #####   #######  

## odt-to-in
ODTS=$(ls *.odt 2> /dev/null | wc -l )
if [ $ODTS != 0 ] ; then
	for FILE in *.odt ; do
		BASE=${FILE%%.odt}
		echo "$BASE.in: $FILE" >> Makefile
		echo "	odt2txt --width=-1 $FILE > temporary.txt" >> Makefile
		echo "	txt2in temporary.txt > $BASE.in" >> Makefile
		echo "	rm -f temporary.txt " >> Makefile
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
echo "	rm -f block/*"  >> Makefile
echo "	rm -f www/*"  >> Makefile

echo "	rm -f block_* */block_*" >> Makefile
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
		UPLOADFILES=$(cat $UPLOADFILE UPLOAD | paste -sd' ')
	else
		UPLOADFILES=$(cat $UPLOADFILE | paste -sd' ')
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
echo "configour.in3 finishing" >>$LOG
exit 0



