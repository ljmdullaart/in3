#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3html
use strict;
use warnings;


my $DEBUG=0;
my $DEB_BLOCK=2;	#Block=stuff
my $DEB_IN=4;		#All input lines 
my $DEB_PUSH=8;	#All push-outs
my $DEB_HEAD=16;	# Put headers in the debug-stream
my $DEB_ALINEA=32;	#alinea pricessing
my $DEB_CHAR=64;	#replace characters with GROFF escapes
my $DEB_IMG=128;	#Image processing
my $DEB_VARS=256;	# interpret and other vars
my $DEB_TABLE=512;	#debug table processing

my @output;
sub pushout{
	(my $txt)=@_;
	push @output,$txt;
	if ($DEB_PUSH & $DEBUG){
		print STDERR "DEBUG $DEB_PUSH: $txt\n";
	}
}
sub debug {
	(my $level,my $msg)=@_;
	if ($level & $DEBUG){

		print "<!-- DEBUG $level: $msg-->\n";
		pushout ("<!-- DEBUG $level: $msg-->");
	}
	if ($DEB_PUSH & $DEBUG){
		print STDERR "DEBUG $level $msg\n";
	}
}

sub hellup {
	print STDERR "
NAME: in3html -- convert in3-files to html
SYNOPSIS:
      in3html [flags] [file]
DESCRIPTION:
In3html converts in3-files to html-format. If no files are
present on the commandline, STDIN is used. Multiple files
on the commandline are concatenated before they are handled.
A single - represents the filename of STDIN.

FLAGS:
-d <value>
--debug <value> :Set debugging level; or of the following:
                 2     debug block processing
                 4     All input lines
                 8     All push-outs
                 16    Put headers in the debug-stream
                 32    alinea processing
                 64    replace characters with escapes
                 128   Image processing
                 256   interpret and other vars
                 512   debug table processing

-h
--help          :Produce this explanation.

-n
--noinclude     :Do not include files; usefull to suppress
                 the inclusion of headers.
-p
--partonly      :Create an HTML-part without headers.

BUGS:
The code is perfect; if you find any bugs it must be because 
you have an alternative perception of reality.

";

}

my $do_includes=1;		# Include files when the {INCLUDE} tag is found
my $part_only=0;		# Do not produce headers
my $inquote=0;
my $tcelopen=0;
my $inlist=0;
my @in3;				# The complete input-file

#
# _ __   __ _ _ __ ___  ___ 
# | '_ \ / _` | '__/ __|/ _ \
# | |_) | (_| | |  \__ \  __/
# | .__/ \__,_|_|  |___/\___|
# |_|                        
#                                           _       
#  __ _ _ __ __ _ _   _ _ __ ___   ___ _ __ | |_ ___ 
# / _` | '__/ _` | | | | '_ ` _ \ / _ \ '_ \| __/ __|
#| (_| | | | (_| | |_| | | | | | |  __/ | | | |_\__ \
# \__,_|_|  \__, |\__,_|_| |_| |_|\___|_| |_|\__|___/
#           |___/                                    
#

my $continued=0;		# argument is continued as next argument
my $fileread=0;			# a file is read; no need to read stdin
for (@ARGV){
	if ($continued==1){
		if (/([0-9]+)/){ $DEBUG=$1; $continued=0;}
		else { print STDERR "Invalid debug value $_\n"; $continued=0;}
	}
	elsif (/^--debug([0-9]+)/){$DEBUG=$1;}
	elsif (/^-d([0-9]+)/){$DEBUG=$1;}
	elsif (/^--debug/){$continued=1;}
	elsif (/^-d/){$continued=1;}
	elsif (/^-h/){hellup;exit(0);}
	elsif (/^-help/){hellup;exit(0);}
	elsif (/^--noinclude/){ $do_includes=0; }
	elsif (/^-n/){ $do_includes=0; }
	elsif (/^-p/){ $part_only=1; }
	elsif (/^--partonly/){ $part_only=1; }
	elsif (/^-$/){ 
		my @in_file=<STDIN>;
		#close FILE;
		push @in3,@in_file;
		$fileread=1;
	}
	else {
		if (open(my $FILE,'<',"$_")){
			my @in_file=<$FILE>;
			close $FILE;
			push @in3,@in_file;
			$fileread=1;
		}
		else {
			print STDERR "Cannot open $_\n";
		}
	}
}
if ($fileread==0){@in3=<STDIN>;}

my $alineatype=-1;
debug($DEB_ALINEA,"Initial alinea=-1");
	#	-1	No alinea is open.
	#	0	simple aline (no side or left note
	#	1	leftnote only
	#	2	side note only
	#	3	left and side note.


my @headnum=(0,0,0,0,0,0,0,0,0,0,0,0);
my $appendix=0;
my $notenum=1;
my $tablestate=0;
my $title='';
my $like=0;
my $side=0;
my %variables=();
my $mapnr=0;
my $cover='';
my @note;
my $language='en';

$variables{'interpret'}=1;

my $notes;
sub pushnote{
	(my $txt)=@_;
	push @note,$txt;
}
#     _                                       _   
#  __| | ___   ___ _   _ _ __ ___   ___ _ __ | |_ 
# / _` |/ _ \ / __| | | | '_ ` _ \ / _ \ '_ \| __|
#| (_| | (_) | (__| |_| | | | | | |  __/ | | | |_ 
# \__,_|\___/ \___|\__,_|_| |_| |_|\___|_| |_|\__|
#
#        _       _           _     
#   __ _| | ___ | |__   __ _| |___ 
#  / _` | |/ _ \| '_ \ / _` | / __|
# | (_| | | (_) | |_) | (_| | \__ \
#  \__, |_|\___/|_.__/ \__,_|_|___/
#  |___/     
#
$variables{'blockscale'}=100;
$variables{'blockinline'}=0;
for (@in3){
	if (/^{TITLE}(.*)/){ $title=$1;}
	elsif($title eq ''){
		if (/^{HEADER 1}(.*)/){
			$title=$1;
		}
	}
	if (/^{COVER}(.*)/){ $cover=$1; }
	if (/^{LIKE}/){$like=1;}
	if (/^{LANGUAGE} ([^ ])/){$language=$1;}
	if (/^{SIDE/){$side=1;}
	if (/^{SET}([^ ]*) (.*)/){
		my $val;
		$variables{$1}=$2;
		debug($DEB_VARS,"variables{$1}=$2 ($variables{$1})");
		if ($1 eq 'H1'){ $val=$2-1; $headnum[1]=$val;}
		elsif ($1 eq 'H2'){ $val=$2-1; $headnum[2]=$val;}
		elsif ($1 eq 'H3'){ $val=$2-1; $headnum[3]=$val;}
		elsif ($1 eq 'H4'){ $val=$2-1; $headnum[4]=$val;}
		elsif ($1 eq 'H5'){ $val=$2-1; $headnum[5]=$val;}
		elsif ($1 eq 'H6'){ $val=$2-1; $headnum[6]=$val;}
		elsif ($1 eq 'H7'){ $val=$2-1; $headnum[7]=$val;}
		elsif ($1 eq 'H8'){ $val=$2-1; $headnum[8]=$val;}
		elsif ($1 eq 'H9'){ $val=$2-1; $headnum[9]=$val;}
	}
}

#  _                    _               
# | |__   ___  __ _  __| | ___ _ __ ___ 
# | '_ \ / _ \/ _` |/ _` |/ _ \ '__/ __|
# | | | |  __/ (_| | (_| |  __/ |  \__ \
# |_| |_|\___|\__,_|\__,_|\___|_|  |___/
#
if ($part_only==0){
	pushout ( "<!DOCTYPE HTML>");
	pushout ( "<html lang=\"$language\">");
	pushout ( "<head>");
	pushout ( "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">");
	if (-f "stylesheet.css"){
		pushout ( "<LINK HREF=\"stylesheet.css\" REL=\"stylesheet\" TYPE=\"text/css\">");
	}
	pushout ( "");
	if ($title ne ''){
	 	pushout ( "<title>$title</title>");
	}
	else {
		pushout ( "<title>Untitled</title>");
	}
	pushout ( "</head>");
	pushout ( "<body>");
	if ($like>0){
		pushout ( "<div id=\"fb-root\"></div>");
		pushout ( "<script>(function(d, s, id) {");
		pushout ( "var js, fjs = d.getElementsByTagName(s)[0];");
		pushout ( "if (d.getElementById(id)) return;");
		pushout ( "js = d.createElement(s); js.id = id;");
		pushout ( "js.src = \"//connect.facebook.net/en_US/sdk.js#xfbml=1&version=v2.5\";");
		pushout ( "fjs.parentNode.insertBefore(js, fjs);");
		pushout ( "}(document, 'script', 'facebook-jssdk'));</script>");
	}
}
if ($cover ne ''){
	pushout ( "<img src=$cover alt=\"Cover\"><br>");
}

#       _ _                  
#  __ _| (_)_ __   ___  __ _ 
# / _` | | | '_ \ / _ \/ _` |
#| (_| | | | | | |  __/ (_| |
# \__,_|_|_|_| |_|\___|\__,_|
#            
#	-1	No alinea is open.
#	0	simple alinea (no side or left note
#	1	leftnote only
#	2	side note only
#	3	left and side note.

my $inalinea=0;
my $inalineatab=0;

sub alineatabstart {
	if ($inalineatab==0){
		debug($DEB_ALINEA,"ALINEA TABLE START { alineatype=$alineatype;inalinea=$inalinea");
		if ($alineatype==0){
			pushout ( "<p><div class=\"alinea\">");
		}
		elsif ($alineatype==1){
			pushout ( "<table class=note><tr><td></td><td></td></tr><tr><td><div class=\"leftnote\">");
		}
		elsif ($alineatype==2){
			pushout ( "<table class=note><tr><td></td><td></td></tr><tr><td><div class=\"alinea\">");
		}
		elsif ($alineatype==3){
		pushout ( "<table class=note><tr><td></td><td></td><td></td></tr><tr><td><div class=\"leftnote\">");
		}
		$inalinea=1;
		debug($DEB_ALINEA,"ALINEA TABLE START } alineatype=$alineatype;inalinea=$inalinea");
		$inalineatab=1;
	}
}
	
sub endalinea {
	debug($DEB_ALINEA,"ALINEA END { alineatype=$alineatype;inalinea=$inalinea");
	if ($inalineatab==0){ debug($DEB_ALINEA,"** ERROR ** End alinea outside an alineatab");}
	if ($alineatype<0){}
	elsif ($inalinea==0){}
	elsif ($alineatype==0){
		if ($inalinea>0){pushout("</div>");}
	}
	elsif ($alineatype==1){
		pushout("</div>      </td>      </tr>")
		#pushout(" </td>      </tr>")
	}
	elsif ($alineatype==2){
		pushout("</div>      </td>      </tr>")
		#pushout(" </td>      </tr>")
	}
	elsif ($alineatype==3){
		pushout("</div>      </td>      </tr>")
		#pushout(" </td>      </tr>")
	}
	$inalinea=0;
	debug($DEB_ALINEA,"ALINEA END } alineatype=$alineatype;inalinea=$inalinea");
}
sub alineatabend {
	if ($inalineatab==1){
		debug($DEB_ALINEA,"ALINEA TABLE END; {  alineatype=$alineatype;inalinea=$inalinea");
		endalinea;
		if ($alineatype>0){
			#pushout ( "</div></td></tr></table>");
			pushout ( "</table>");
		}
		$inalinea=0;
		debug($DEB_ALINEA,"ALINEA TABLE END } alineatype=$alineatype;inalinea=$inalinea");
		$inalineatab=0;
	}
}

sub startalinea {
	(my $newalineatype)=@_;
	if ($inalineatab==0){ alineatabstart;}
	if ($inalinea==1){ endalinea;}
	debug($DEB_ALINEA,"ALINEA START{ alineatype=$alineatype; new type=$newalineatype");
	if ($newalineatype != $alineatype){
		alineatabend;
		$alineatype=$newalineatype;
		alineatabstart;
	}
	else {
		if ($alineatype==0){pushout("<p><div class=\"alinea\">")}
		# below, sizes of the columns must be given
		elsif ($alineatype==1){pushout("<tr><td style=\"vertical-align:top;\"><div class=\"alinea\"><!--type-==$alineatype-->");}
		elsif ($alineatype==2){pushout("<tr><td style=\"vertical-align:top;\"><div class=\"alinea\"><!--type-==$alineatype-->");}
		elsif ($alineatype==3){pushout("<tr><td style=\"vertical-align:top;\"><div class=\"alinea\"><!--type-==$alineatype-->");}
		$inalinea=1;
	}
	debug($DEB_ALINEA,"ALINEA START} alineatype=$alineatype; new type=$newalineatype");
}


#  _     _            _        
# | |__ | | ___   ___| | _____ 
# | '_ \| |/ _ \ / __| |/ / __|
# | |_) | | (_) | (__|   <\__ \
# |_.__/|_|\___/ \___|_|\_\___/
#

my $litteraltext=0;
my @litblock;
sub pushlit{
	(my $text)=@_;
	$litteraltext=1;
	push @litblock,$text;
}
	
my @block;
my $blocktype='none';
my $blockname='none';
my $blockformat='';
my $blockinline=0;
sub block_push {
	(my $text)=@_;
	debug($DEB_BLOCK,"block-push $text");
	push @block,$text;
}
sub block_end {
	if (! (-d 'block')){ system ("mkdir block");}
	my $density;
	$blockinline=$variables{'blockinline'};
	if ($blockname eq 'none') {
		my $random=int(rand(1000000));
		$blockname="gen_$random";
	}
	my $blockscale=$variables{'blockscale'};;
	if($blockformat ne ''){
		debug($DEB_BLOCK,"block format $blockformat");
		if ($blockformat=~/scale=(\d+)/){ $blockscale=$1; }
		if ($blockformat=~/inline/){ $blockinline=1; }
	}
	if ($blockinline==0){
		alineatabend;
	}

	#------------------------------------------------------------
	if ($blocktype eq 'pre'){ 
		debug($DEB_BLOCK,"block type pre");
		# Do nothing; pre-blocks are handled as {LITTERAL}
	}
	#------------------------------------------------------------
	elsif ($blocktype eq 'music'){
		debug($DEB_BLOCK,"block type music");
		$density=1000;
		if (open (my $MUSIC, '>',"block/$blockname.ly")){
			debug($DEB_BLOCK,"Opened music block block/$blockname.ly");
			print $MUSIC "\\version \"2.18.2\"\n";
			print $MUSIC "\\book {\n";
  			print $MUSIC "\\paper {\n";
  			print $MUSIC "indent = 0\\mm\n";
  			print $MUSIC "line-width = 110\\mm\n";
  			print $MUSIC "oddHeaderMarkup = \"\"\n";
  			print $MUSIC "evenHeaderMarkup = \"\"\n";
  			print $MUSIC "oddFooterMarkup = \"\"\n";
  			print $MUSIC "evenFooterMarkup = \"\"\n";
  			print $MUSIC "}\n";
  			print $MUSIC "\\header {\n";
    		print $MUSIC "tagline = \"\"\n";
  			print $MUSIC "}\n";
			for (@block){
				print $MUSIC "$_\n";
			}
  			print $MUSIC "}\n";
			close $MUSIC;
			#$b_image="block/$blockname.png";
			system ("lilypond --png  -dresolution=500  block/$blockname.ly");
			system ("mv *$blockname.png block/$blockname.png");
			system ("convert -trim block/$blockname.png block/$blockname.tmp.png");
			system ("mv block/$blockname.tmp.png block/$blockname.png");
			my $imgsize=` imageinfo --geom block/$blockname.png`;
            my $x; my $y; my $yn;
            ($x,$y)=split ('x',$imgsize);
			$yn=$y*$blockscale/14000;
			my $ysize=$yn.'em';
			pushout("<img src=\"$blockname.png\" alt=\"$blockname.png\" style=\"height:$ysize;vertical-align:middle\">");
		}
		else {
			print STDERR "in3html cannot open $blockname\n";
		}
	}
	elsif ($blocktype eq 'texeqn'){
		debug($DEB_BLOCK,"block type texeqn");
		$density=1000;
		if ($blockname eq 'none') {
			my $random=int(rand(1000000));
			$blockname="gen_$random";
		}
		if (open (my $TEXEQN,'>',"block/$blockname.tex")){
			print $TEXEQN "\\documentclass{article}\n";
			print $TEXEQN "\\usepackage{amsmath}\n";
			print $TEXEQN "\\usepackage{amssymb}\n";
			print $TEXEQN "\\usepackage{algorithm2e}\n";
			print $TEXEQN "\\begin{document}\n";
			print $TEXEQN "\\begin{titlepage}\n";
			print $TEXEQN "\\begin{equation*}\n";
			for (@block){
				print $TEXEQN "$_\n";
			}
			print $TEXEQN "\\end{equation*}\n";
			print $TEXEQN "\\end{titlepage}\n";
			print $TEXEQN "\\end{document}\n";
			close $TEXEQN;
            my $b_image;
            my $d_image;
            $b_image="block/$blockname.png";
            $d_image="block/$blockname.dvi";
            debug($DEB_BLOCK,"latex block/$blockname.tex > /dev/null 2>/dev/null");
            debug($DEB_BLOCK,"convert  -trim  -density $density  $d_image  $b_image");
            system("echo '' | latex block/$blockname.tex > /dev/null 2>/dev/null");
			system("mv $blockname.dvi block");
            system("convert  -trim  -density $density  $d_image  $b_image");
			debug ($DEB_IMG, "  image=$b_image");
			my $imgsize=` imageinfo --geom $b_image`;
            my $x; my $y; my $yn;
            ($x,$y)=split ('x',$imgsize);
			$yn=$y*$blockscale/14000;
			my $ysize=$yn.'em';
			pushout("<img src=\"$blockname.png\" alt=\"$blockname.png\" style=\"height:$ysize;vertical-align:middle\">");
		}
		else {
			print STDERR "in3html cannot open $blockname\n";
		}
	}
	#------------------------------------------------------------
	elsif ($blocktype eq 'gnuplot'){
		debug($DEB_BLOCK,"block type gnuplot");
		if ($blockname eq 'none') {
			my $random=int(rand(1000000));
			$blockname="gen_$random";
		}

		if (open (my $GNUPLOT,'>',"block/$blockname.gnuplot")){
			my $x=800*$blockscale/100;
			my $y=600*$blockscale/100;
			print $GNUPLOT "set terminal png size $x,$y enhanced font \"Helvetica,8\"";
			print $GNUPLOT "\nset output 'block/$blockname.png'\n";
			for (@block){ print $GNUPLOT "$_\n"; }
			close $GNUPLOT;
			my $b_image;
			system("gnuplot block/$blockname.gnuplot");
			$b_image="block/$blockname.png";
			debug ($DEB_IMG, "  image=$b_image");
			pushout("<img src=\"$blockname.png\" alt=\"$blockname.png>\" width=\"$x\">");
		}
		else {
			print STDERR "in3html cannot open $blockname.gnuplot\n";
		}
	}
	elsif ($blocktype eq 'eqn'){
		debug($DEB_BLOCK,"block type eqn");
		$density=1000;
		my $ffn="block/$blockname";
		if (open my $EQN, '>',"$ffn.eqn"){
			debug ($DEB_BLOCK, "eqn block opened $ffn.eqn");
			print $EQN ".EQ\n";
			for (@block){
				print $EQN "$_\n";
			}
			print $EQN ".EN\n";
			close $EQN;
			debug ($DEB_BLOCK,"eqn $ffn.eqn > $ffn.groff");
			system ("eqn $ffn.eqn > $ffn.groff");
			debug ($DEB_BLOCK,"groff $ffn.groff > $ffn.ps");
			system ("groff $ffn.groff > $ffn.ps");
			debug ($DEB_BLOCK,"ps2pdf $ffn.ps  $ffn.pdf");
			system ("ps2pdf $ffn.ps  $ffn.pdf");
			debug ($DEB_BLOCK,"convert -trim -density $density $ffn.pdf  $ffn.png");
			system ("convert -trim -density $density $ffn.pdf  $ffn.png");
			debug ($DEB_BLOCK,$DEB_IMG, "  image=$ffn.png");
			system ("rm -f $ffn.groff $ffn.ps $ffn.pdf");
			my $imgsize=` imageinfo --geom $ffn.png`;
            my $x; my $y; my $yn;
            ($x,$y)=split ('x',$imgsize);
			$yn=$y*$blockscale/14000;
			my $ysize=$yn.'em';
			pushout("<img src=\"$blockname.png\" alt=\"$blockname>\" style=\"height:$ysize;vertical-align:middle\">");
		}
	}
	elsif ($blocktype eq 'pic'){
		my $density=1000;
		my $x=800*$blockscale/100;
		if ($blockname eq 'none') {
			my $random=int(rand(1000000));
			$blockname="gen_$random";
		}
		my $ffn="block/$blockname";
		if (open my $PIC, '>',"$ffn.pic"){
			print $PIC ".PS\n";
			for (@block){
				print $PIC "$_\n";
			}
			print $PIC ".PE\n";
			close $PIC;
			system ("pic $ffn.pic > $ffn.groff");
			system ("groff $ffn.groff > $ffn.ps");
			system ("ps2pdf $ffn.ps  $ffn.pdf");
			system ("convert -trim -density $density $ffn.pdf  $ffn.png");
			system ("rm $ffn.groff $ffn.ps $ffn.pdf");
			debug ($DEB_IMG, "  image=$ffn.png");
			if ($blockinline==1){
				$blockinline=0;
				my $imgsize=` imageinfo --geom $ffn.png`;
				(my $xsize, my $ysize)=split('x',$imgsize);
				$x=$xsize*40/$ysize;
			}
			pushout("<img src=\"$blockname.png\" alt=\"$blockname\" width=\"$x\">");
		}
	}
	elsif($blocktype =~/^(class.*)/) {
		if ($blockinline==1){
			pushout ("<div style=\"display:inline\"  class=\"$1\">");
		}
		else {
			pushout ("<p><div class=\"$1\">");
		}
		for (@block){ pushout ($_); }
		pushout ('</div>');
		if ($blockinline==0){
			pushout('</p>');
		}
		$blockinline=0;

	}
	else {
		pushout ('<p>');
		for (@block){ pushout ($_); }
		pushout ('</p>');
	}
	undef @block;
	$blocktype='none';
	$blockname='none';
	$blockformat='';
	$blockinline=0;

}

for (@in3){
	if (/^{TITLE}(.*)/){ pushout("<h1>$1</h1>");}
	if (/^{SUBTITLE}(.*)/){ pushout("<h3>$1</h3>");}
}


for (@in3){
	chomp;
	debug($DEB_IN,"INPUT; $_;");
	if ($inquote==1){
		if (/^{QUOTE}/){}
		else {
			pushout("</div>");
			$inquote=0;
		}
	}
	if($litteraltext==1){
		if (/^{LITTERAL}/){}
		else {
			alineatabend;
			pushout("<pre>");
			for my $i (0..$#litblock){ pushout("$litblock[$i]"); }
			pushout("</pre>");
			undef @litblock;
			$litteraltext=0;
			$inalinea=0;
		}
	}
	if (1==0){}
	elsif (/^{ALINEA}([0-9])/){
		my $newalineatype=$1;
		startalinea($newalineatype);
	}
	elsif (/^{ALINEAEND}/){
		endalinea;
	}
	elsif (/^{AUTHOR}(.*)/){ }
	elsif (/^{APPENDIX}(.*)/){
		$appendix=$headnum[1];
	}
	elsif (/^{BLOCKSTART}(.+) (.+)/){
		$blocktype=$1;
		$blockname=$2;
	}
	elsif (/^{BLOCKFORMAT}(.*)/){
		$blockformat=$1;
	}
	elsif (/^{BLOCK ([^}]+)}(.*)/){
		block_push($2);
	}
	elsif (/^{BLOCKEND}/){
		block_end();
	}
	elsif (/^{COVER}(.*)/){ }
	elsif (/^{INCLUDE}(.*)/){
		if ($do_includes==1){
			if ( open (my $INCLUDE,'<', $1)){
				while (<$INCLUDE>){pushout ($_);}
				close $INCLUDE;
			}
		}
		
	}
	elsif (/^{HARDPARAGRAPH}/){
		pushout ("<p>&nbsp;</p>");
	}
	elsif (/^{HEADER ([0-9])}(.*)/){
		my $num=$1;my $text=$2;
		alineatabend;
		debug($DEB_HEAD,"HEADER $num : $text");
		$headnum[$num]++;
		$headnum[$num+1]=0;
		my $titnr='';
		if ($appendix >0){
			$titnr=substr('ABCDEFGHIJKLMNOPQRSTUVWXYZ',$headnum[1]-$appendix-1,1);
		}
		else {
			$titnr="$headnum[1].";
		}
		for (my $i=2;$i<=$num;$i++){
			$titnr="$titnr$headnum[$i].";
		}
		$num++;
		pushout ("<h$num id=\"a$titnr\">$titnr $text</h$num>");
		if ($alineatype >0){
			$alineatype &=2;
			#pushout ("<table class=note>");
		}
	}
	elsif (/^{HEADUNNUM ([0-9])}(.*)/){
		my $num=$1;my $text=$2;
		alineatabend;
		$num++;
		pushout("<h$num>$text</h$num>");
		if ($alineatype >0){$alineatype &=2;}
	}
	elsif (/^{IMAGE}(.*)/){
		if (($inlist==0) && ($tcelopen==0)){
			alineatabend;
			pushout ("<br>");
		}
		my $image;my $text;
		my $scale=100;
		if (/ ([0-9][0-9]*)$/){
			$scale=$1;
			s/ *[0-9]*$//;
		}
		debug ($DEB_IMG, "scale=$scale  _=$_");
		$scale=$scale*80/100;
		if (/^{IMAGE}([^ ]*) (.*)/){
			$image=$1;$text=$2;
			debug ($DEB_IMG, "scale=$scale  image=$image text=$text");
			if ($inlist==0){
				pushout("<img src=\"$image\" width=\"$scale%\"  alt=\"image for $text>\">");
				#pushout("<img src=\"$image\" width=\"$scale%\" height=\"$scale%\" alt=\"image for $text>\">");
				pushout ("<br>");
				pushout ($text);
			}
			else {
				pushout("<img src=\"$image\" width=\"$scale%\"  alt=\"image for $text>\" align=\"middle\" >");
				pushout ("<br>");
				pushout ($text);
			}
		}
		elsif (/^{IMAGE}([^ ]*)/) {
			$image=$1;
			debug ($DEB_IMG, "scale=$scale  image=$image");
			if ($inlist==0){
				pushout("<img src=\"$image\" width=\"$scale%\"  alt=\"$image>\">");
			}
			else {
				pushout("<img src=\"$image\" width=\"$scale%\"  alt=\"$image>\" align=\"middle\">");
			}
		}
		else {
			print "<!-- in3html could not do an image -->";
		}
		if (($inlist==0) && ($tcelopen==0)){
			pushout ("<br>");
			alineatabstart;
		}
	}
	elsif (/^{LANGUAGE}/){
	}
	elsif (/^{LEFTNOTE}(.*)/){
		my $text=$1;
		pushout("<div class=left>$text</div>");
		pushout("</td><td style=\"vertical-align:top;\">");
	}
	elsif (/^{LIKE}/){
		pushout("<div class=\"fb-like\" data-href=\"http://ljm.name\" data-layout=\"standard\" data-action=\"like\" data-show-faces=\"true\" data-share=\"true\"></div>");
	}
	elsif (/^{LINE}/){
		alineatabend;
		pushout("<hr>");
		alineatabstart;
	}
	elsif (/^{LINK}([^ ]*) (.*)/){
		pushout("<a href=$1>$2</a>");
	}
	elsif (/^{LINEBREAK}/){
		if ($alineatype<1){
			pushout("<br>");
		}
	}
	elsif (/^{LISTALPHAEND}/){
		if($inlist>0){pushout("</div></li>");$inlist=0;}
		pushout("</ol>");
	}
	elsif (/^{LISTALPHAITEM}(.*)/){
		if($inlist>0){pushout("</div></li>");$inlist=0;}
		pushout("<li>");
		$inlist=1;
		pushout("<div class=\"list\">$1");
	}
	elsif (/^{LISTALPHASTART}/){
		if ($inalinea==0){startalinea($alineatype);}
		pushout("<ol type=a>");
	}
	elsif (/^{LISTDASHEND}/){
		if($inlist>0){pushout("</div></li>");$inlist=0;}
		pushout("</ul>");
	}
	elsif (/^{LISTDASHITEM}(.*)/){
		if($inlist>0){pushout("</div></li>");$inlist=0;}
		pushout("<li>");
		pushout("<div class=\"list\">$1");
		$inlist=1;
	}
	elsif (/^{LISTDASHSTART}/){
		if ($inalinea==0){startalinea($alineatype);}
		pushout("<ul>");
	}
	elsif (/^{LISTNUMEND}/){
		if($inlist>0){pushout("</div></li>");$inlist=0;}
		pushout("</ol>");
	}
	elsif (/^{LISTNUMITEM}(.*)/){
		if($inlist>0){pushout("</div></li>");$inlist=0;}
		pushout("<li>");
		$inlist=1;
		pushout("<div class=\"list\">$1");
	}
	elsif (/^{LISTNUMSTART}/){
		if ($inalinea==0){startalinea($alineatype);}
		pushout("<ol type=1>");
	}
	elsif (/^{LITTERAL}(.*)/){
		my $text=$1;
		$text=~s/ /&nbsp;/g;
		$text=~s/</&lt;/g;
		$text=~s/>/&gt;/g;
		pushlit($text);
	}
	elsif (/^{LST}(.*)/){
		my $line=$1;
		$line=~s/	/\&nbsp;\&nbsp;\&nbsp;\&nbsp;/g;
		pushout("<br><span class=\"fixed\">$line</span>");
	}
	elsif (/^{MAPSTART}/){
		alineatabend;
	}
	elsif (/^{MAPPICT}(.*)/){
		pushout('<div  style="text-align:center">');
		$mapnr++;
		pushout("<img src=\"$1\" usemap=#map$mapnr  alt=\"map\">");
		pushout("<map name=map$mapnr>");
	}
	elsif (/^{MAPFIELD}([^ ]*) (.*)/){
		pushout("<area shape=rect coords=\"$2\" href=\"$1\" alt=\"$1,$2\">");
	}
	elsif (/^{MAPLINK}([^ ]*) (.*)/){
		pushout("<area shape=rect coords=\"$2\" href=\"$1\">");
	}
	elsif (/^{MAPEND}/){
		pushout("</map>");
		pushout("</div>");
	}
	elsif (/^{NOTE}(.*)/){
		my $text=$1;
		pushout("$notenum");
		pushnote("$notenum: $text");
		$notenum++;
	}
	elsif (/^{PAGE}/){
	}
	elsif (/^{QUOTE}/){
		if ($inquote==0){
			pushout("<div class=quote>");
			$inquote=1;
		}
		s/^{QUOTE}//;
		pushout("$_");

	}
	elsif (/^{NOP}/){
	}
	elsif (/^{SET}([^ ]+) (.*)/){
	}
	elsif (/^{SIDENOTE}(.*)/){
		my $text=$1;
		if ($inalinea>0){
			pushout("</div></td><td style=\"vertical-align:top;width:25%\">");
			pushout("<div class=side>$text");
		}
	}
	elsif (/^{SUBTITLE}(.*)/){
	}
	elsif (/^{TABLESTART}/){
		alineatabend;
		pushout ("<table class=\"normal\">");
	}
	elsif (/^{TABLECEL}(.*)/){
		my $text=$1;
		my $colspan=''; my $rowspan='';
		if ($tcelopen>0){
			pushout ("</div></td>");
			$tcelopen=0;
		}
		if ($text=~/<.s=[0-9]+>/){
			if ($text=~/<rs=([0-9]+)>/){
				$rowspan=" rowspan=\"$1\"";
				$text=~s/<rs=[0-9]*>//;
			}
			if ($text=~/<cs=([0-9]+)>/){
				$colspan=" colspan=\"$1\"";
				$text=~s/<cs=[0-9]*>//;
			}
			pushout ("<td$colspan$rowspan><div class=\"cel\">$text");
			$tcelopen=1;
		}
		elsif ($text=~/<.SPAN>/){}
		else {
			pushout ("<td><div class=\"cel\">$text");
			$tcelopen=1;
		}
	}
	elsif (/^{TABLEROW}/){
		pushout("<tr>");
	}
	elsif (/^{TABLEROWEND/){
		if ($tcelopen>0){
			pushout ("</div></td>");
			$tcelopen=0;
		}
		pushout("</tr>");
	}
	elsif (/^{TABLEEND}/){
			pushout ("</table>");
	}
	elsif (/^{SUBSCRIPT}(.*)/){
		pushout("<sub>$1</sub>");
	}
	elsif (/^{SUPERSCRIPT}(.*)/){
		pushout("<sup>$1</sup>");
	}
	elsif (/^{TEXTBOLD}(.*)/){
		pushout("<b>$1</b>");
	}
	elsif (/^{TEXTFIX}(.*)/){
		pushout("<span class=\"fixed\">$1</span>");
	}
	elsif (/^{TEXTNORMAL}(.*)/){
		pushout("$1");
	}
	elsif (/^{TEXTITALIC}(.*)/){
		pushout("<i>$1</i>");
	}
	elsif (/^{TEXTUNDERLINE}(.*)/){
		pushout("<u>$1</u>");
	}
	elsif (/^{TITLE}(.*)/){
	}
	elsif (/^{.*}/){
		print STDERR "Unknown $_\n";
	}
}

alineatabend;
$alineatype=-1;

for (keys %variables){
	debug($DEB_VARS,"variables{$_}=$variables{$_}");
}

my $charmapfile;
if ( -f "/usr/local/share/in3charmap$variables{'interpret'}" ){
	$charmapfile="/usr/local/share/in3charmap$variables{'interpret'}";
}
else {
	$charmapfile="in3charmap$variables{'interpret'}";
}

my @charmap;
if ( open (my $CHARMAP,'<',$charmapfile)){
	@charmap=<$CHARMAP>;
	close $CHARMAP;
}
else { print STDERR "Cannot open in3charmap$variables{'interpret'}"; }

for (@charmap){
	chomp;
	(my $char,my $groff,my $html)=split '	';
	$char='NOCHAR' unless defined $char;
	$groff=$char unless defined $groff;
	$html=$char unless defined $html;
	debug($DEB_CHAR,"Replace $char with $html");
	for my $i (0..$#output){
		$output[$i]=~s/$char/$html/g;
		debug($DEB_CHAR,"New: $output[$i]");
		
	}
}

if ($variables{'interpret'}==1){
	for my $i (0..$#output){
		my $changed=1;
		while ($changed==1){
			$changed=0;
			if ($output[$i]=~/(.*)\%\*([^ ]*)\%\*(.*)/){
				$output[$i]="$1<b>$2</b>$3";
				$changed=1;
			}
			if ($output[$i]=~/(.*)\%_([^ ]*)\%_(.*)/){
				$output[$i]="$1<u>$2</u>$3";
				$changed=1;
			}
		}
	}
}
if ($variables{'interpret'}==2){
	print STDERR "INTERPRET =$variables{'interpret'}\n";
	for my $i (0..$#output){
		my $changed=1;
		while ($changed==1){
			$changed=0;
			if ($output[$i]=~/(.*)\*([^ ]*)\*(.*)/){
				$output[$i]="$1<b>$2</b>$3";
				$changed=1;
			}
			if ($output[$i]=~/(.*)_([^ ]*)_(.*)/){
				$output[$i]="$1<u>$2</u>$3";
				$changed=1;
			}
		}
	}
}
	

for (@output){
	if (/^ \./){}
	else { s/^ *//;}
	if (/==>/){
		my $qis=s/=/=/g;
		my $repl='&nbsp;'x$qis;
		s/===*>/$repl/;
	}
}
for (@output){
	if (!(/^$/)){
		print "$_\n";
	}
}
