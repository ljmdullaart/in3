#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3html
use strict;
use warnings;

my $DEBUG=0;
my $DEB_IN=4;		#All input lines 
my $DEB_PUSH=8;	#All push-outs
my $DEB_HEAD=16;	# Put headers in the debug-stream
my $DEB_ALINEA=32;	#alinea pricessing
my $DEB_CHAR=64;	#replace characters with GROFF escapes
my $DEB_IMG=128;	#Image processing
my $DEB_VARS=256;	# interpret and other vars
my $DEB_TABLE=512;	#debug table processing

sub debug {
	(my $level,my $msg)=@_;
	if ($DEBUG & $level){
		print STDERR "DEBUG $level: $msg\n";
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
                 4   All input lines
                 8   All push-outs
                 16  Put headers in the debug-stream
                 32  alinea pricessing
                 64  replace characters with GROFF escapes
                 128 Image processing
                 256 interpret and other vars
                 512 debug table processing

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

my $do_includes=1;
my $part_only=0;
my $continued=0;
my $fileread=0;
my $inalinea=0;
my @in3;
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
		close FILE;
		push @in3,@in_file;
		$fileread=1;
	}
	else {
		if (open(FILE,"$_")){
			my @in_file=<FILE>;
			close FILE;
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
my $notenum=1;
my $tablestate=0;
my $title='';
my $like=0;
my $side=0;
my %variables=();
my $mapnr=0;
my $cover='';
my @note;

$variables{'interpret'}=1;

my $notes;
sub pushnote{
	(my $txt)=@_;
	push @note,$txt;
}
my @output;
sub pushout{
	(my $txt)=@_;
	push @output,$txt;
	debug($DEB_PUSH,"PUSHOUT: $txt");
}


for (@in3){
	if (/^{TITLE}(.*)/){ $title=$1;}
	elsif($title eq ''){
		if (/^{HEADER 1}(.*)/){
			$title=$1;
		}
	}
	if (/^{COVER}(.*)/){ $cover=$1; }
	if (/^{LIKE}/){$like=1;}
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

if ($part_only==0){
	pushout ( "<!DOCTYPE HTML>");
	pushout ( "<html>");
	pushout ( "<head>");
	pushout ( "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">");
	if (-f "stylesheet.css"){
		pushout ( "<LINK HREF=\"stylesheet.css\" REL=\"stylesheet\" TYPE=\"text/css\">");
	}
	pushout ( "");
	if ($title ne ''){
	 	pushout ( "<title>$title</title>");
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
	pushout ( "<img src=$cover><br>");
}

sub alineatabstart {
	debug($DEB_ALINEA,"ALINEA START; alineatype=$alineatype;");
	if ($alineatype==0){
		pushout ( "<p><div class=\"alinea\">");
	}
	elsif ($alineatype==1){
		pushout ( "<table class=note><tr><td style=\"width:15%\">");
	}
	elsif ($alineatype==2){
		pushout ( "<table class=note><tr><td><div class=\"alinea\">");
	}
	elsif ($alineatype==3){
		pushout ( "<table class=note><tr><td style=\"width:15%\">");
	}
	$inalinea=1;
}
sub alineatabend {
	debug($DEB_ALINEA,"ALINEA END; alineatype=$alineatype;");
	if ($alineatype==0){
		if ($inalinea>0){pushout ( "</div>");}
	}
	elsif ($alineatype>0){
		#pushout ( "</div></td></tr></table>");
		pushout ( "</table>");
	}
	$inalinea=0;
}

my $litteraltext=0;
my @litblock;
sub pushlit{
	(my $text)=@_;
	$litteraltext=1;
	push @litblock,$text;
}
	

for (@in3){
	if (/^{TITLE}(.*)/){ pushout("<h1>$1</h1>");}
	if (/^{SUBTITLE}(.*)/){ pushout("<h3>$1</h3>");}
}


for (@in3){
	chomp;
	debug($DEB_IN,"INPUT; $_;");
	if($litteraltext==1){
		if (/^{LITTERAL}/){}
		else {
			pushout("<pre>");
			for my $i (0..$#litblock){ pushout("$litblock[$i]"); }
			pushout("</pre>");
			undef @litblock;
			$litteraltext=0;
		}
	}
	if (1==0){}
	elsif (/^{ALINEA}([0-9])/){
		my $newalineatype=$1;
		debug($DEB_ALINEA,"ALINEA DIRECTIVE; alineatype=$alineatype; new type=$newalineatype");
		if ($newalineatype != $alineatype){
			alineatabend;
			$alineatype=$newalineatype;
			alineatabstart;
		}
		else {
			if ($alineatype==0){pushout("<p><div class=\"alinea\">")}
			# below, sizes of the columns must be given
			elsif ($alineatype==1){pushout("<tr><td style=\"vertical-align:top;\"><div class=\"alinea\">");}
			elsif ($alineatype==2){pushout("<tr><td style=\"vertical-align:top;\"><div class=\"alinea\">");}
			elsif ($alineatype==3){pushout("<tr><td style=\"vertical-align:top;\"><div class=\"alinea\">");}
		}
	}
	elsif (/^{ALINEAEND}/){
		if ($alineatype<0){}
		elsif ($alineatype==0){
			if ($inalinea>0){pushout("</div>");}
		}
		elsif ($alineatype>0){
			pushout("</div></td></tr>")
		}
		$inalinea=0;
	}
	elsif (/^{AUTHOR}(.*)/){ }
	elsif (/^{COVER}(.*)/){ }
	elsif (/^{INCLUDE}(.*)/){
		if ($do_includes==1){
			if ( open (INCLUDE, $1)){
				while (<INCLUDE>){pushout ($_);}
				close INCLUDE;
			}
		}
		
	}
	elsif (/^{HEADER ([0-9])}(.*)/){
		my $num=$1;my $text=$2;
		alineatabend;
		debug($DEB_HEAD,"HEADER $num : $text");
		$headnum[$num]++;
		$headnum[$num+1]=0;
		my $titnr='';
		for (my $i=1;$i<=$num;$i++){
			$titnr="$titnr$headnum[$i].";
		}
		$num++;
		pushout ("<h$num id=\"a$titnr\">$titnr $text</h$num>");
		if ($alineatype >0){$alineatype &=2;}
	}
	elsif (/^{HEADUNNUM ([0-9])}(.*)/){
		my $num=$1;my $text=$2;
		alineatabend;
		$num++;
		pushout("<h$num>$text</h$num>");
		if ($alineatype >0){$alineatype &=2;}
	}
	elsif (/^{IMAGE}(.*)/){
		alineatabend;
		pushout ("<br>");
		my $image;my $text;
		if (/^{IMAGE}([^ ]*) (.*)/){
			$image=$1;$text=$2;
			pushout("<img src=\"$image\" alt=\"image for $text>\">");
			pushout ("<br>");
			pushout ($text);
		}
		else {
			$image=$1;$text=$2;
			pushout("<img src=\"$image\" alt=\"$image>\">");
		}
		pushout ("<br>");
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
		pushout("</ol>");
	}
	elsif (/^{LISTALPHAITEM}(.*)/){
		pushout("<li>");
		pushout("<div class=\"list\">$1</div>");
		pushout("</li>");
	}
	elsif (/^{LISTALPHASTART}/){
		pushout("<ol type=a>");
	}
	elsif (/^{LISTDASHEND}/){
		pushout("</ul>");
	}
	elsif (/^{LISTDASHITEM}(.*)/){
		pushout("<li>");
		pushout("<div class=\"list\">$1</div>");
		pushout("</li>");
	}
	elsif (/^{LISTDASHSTART}/){
		pushout("<ul>");
	}
	elsif (/^{LISTNUMEND}/){
		pushout("</ol>");
	}
	elsif (/^{LISTNUMITEM}(.*)/){
		pushout("<li>");
		pushout("<div class=\"list\">$1</div>");
		pushout("</li>");
	}
	elsif (/^{LISTNUMSTART}/){
		pushout("<ol type=1>");
	}
	elsif (/^{LITTERAL}(.*)/){
		my $text=$1;
		$text=~s/ /&nbsp;/g;
		$text=~s/</&lt;/g;
		$text=~s/>/&gt;/g;
		pushlit($text);
	}
	elsif (/^{MAPSTART}/){
		alineatabend;
	}
	elsif (/^{MAPPICT}(.*)/){
		pushout('<div align="center">');
		$mapnr++;
		pushout("<img src=\"$1\" usemap=#map$mapnr border=\"0\">");
		pushout("<map name=map$mapnr>");
	}
	elsif (/^{MAPFIELD}([^ ]*) (.*)/){
		pushout("<area shape=rectangle coords=\"$2\" href=\"$1\">");
	}
	elsif (/^{MAPLINK}([^ ]*) (.*)/){
		pushout("<area shape=rectangle coords=\"$2\" href=\"$1\">");
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
	elsif (/^{SET}([^ ]+) (.*)/){
	}
	elsif (/^{SIDENOTE}(.*)/){
		my $text=$1;
		pushout("</td><td style=\"vertical-align:top;width:25%\">");
		pushout("<div class=side>$text</div>");
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
		if ($text=~/<.s=[0-9]+>/){
			if ($text=~/<rs=([0-9]+)>/){
				$rowspan=" rowspan=\"$1\"";
				$text=~s/<rs=[0-9]*>//;
			}
			if ($text=~/<cs=([0-9]+)>/){
				$colspan=" colspan=\"$1\"";
				$text=~s/<cs=[0-9]*>//;
			}
			pushout ("<td$colspan$rowspan><div class=\"cel\">$text</div></td>");
		}
		elsif ($text=~/<.SPAN>/){}
		else {
			pushout ("<td><div class=\"cel\">$text</div></td>");
		}
	}
	elsif (/^{TABLEROW}/){
		pushout("<tr>");
	}
	elsif (/^{TABLEROWEND/){
		pushout("</tr>");
	}
	elsif (/^{TABLEEND}/){
		pushout ("</table>");
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
if ( open (CHARMAP,$charmapfile)){
	@charmap=<CHARMAP>;
	close CHARMAP;
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
