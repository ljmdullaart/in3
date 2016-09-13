#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3html

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

@in3=<>;


my $alineatype=-1;
debug($DEB_ALINEA,"Initial alinea=-1");
	#	-1	No alinea is open.
	#	0	simple aline (no side or left note
	#	1	leftnote only
	#	2	side note only
	#	3	left and side note.


@headnum=(0,0,0,0,0,0,0);
$notenum=1;
my $tablestate=0;
my $title='';
my $like=0;
my $side=0;
my %variables=();
my $mapnr=0;

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
	if (/^{LIKE}/){$like=1;}
	if (/^{SIDE/){$side=1;}
	if (/^{SET}([^ ]*) (.*)/){
		$variables{$1}=$2;
		debug($DEB_VARS,"variables{$1}=$2 ($variables{$1})");
		if ($1 eq 'H1'){ $val=$2-1; $headnum[1]=$val;}
		elsif ($1 eq 'H2'){ $val=$2-1; $headnum[2]=$val;}
		elsif ($1 eq 'H3'){ $val=$2-1; $headnum[3]=$val;}
		elsif ($1 eq 'H4'){ $val=$2-1; $headnum[4]=$val;}
		elsif ($1 eq 'H5'){ $val=$2-1; $headnum[5]=$val;}
	}
}

pushout ( "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">");
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

sub alineatabstart {
	debug($DEB_ALINEA,"ALINEA START; alineatype=$alineatype;");
	if ($alineatype==0){
		pushout ( "<p>");
	}
	elsif ($alineatype==1){
		pushout ( "<table class=note><tr><td style=\"width:15%\">");
	}
	elsif ($alineatype==2){
		pushout ( "<table class=note><tr><td>");
	}
	elsif ($alineatype==3){
		pushout ( "<table class=note><tr><td style=\"width:15%\">");
	}
}
sub alineatabend {
	debug($DEB_ALINEA,"ALINEA END; alineatype=$alineatype;");
	if ($alineatype==0){
		pushout ( "</p>");
	}
	elsif ($alineatype>0){
		#pushout ( "</td></tr></table>");
		pushout ( "</table>");
	}
	$alineatype=-1;
}

$litteraltext=0;
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
			if ($alineatype==0){pushout("<p>")}
			# below, sizes of the columns must be given
			elsif ($alineatype==1){pushout("<tr><td style=\"vertical-align:top;\">");}
			elsif ($alineatype==2){pushout("<tr><td style=\"vertical-align:top;\">");}
			elsif ($alineatype==3){pushout("<tr><td style=\"vertical-align:top;\">");}
		}
	}
	elsif (/^{ALINEAEND}/){
		if ($alineatype<0){}
		elsif ($alineatype==0){
			pushout("</p>");
		}
		elsif ($alineatype>0){
			pushout("</td></tr>")
		}
	}
	elsif (/^{INCLUDE}(.*)/){
		if ( open (INCLUDE, $1)){
			while (<INCLUDE>){pushout ($_);}
			close INCLUDE;
		}
		
	}
	elsif (/^{HEADER ([0-9])}(.*)/){
		$num=$1;$text=$2;
		alineatabend;
		debug($DEB_HEAD,"HEADER $num : $text");
		$headnum[$num]++;
		$headnum[$num+1]=0;
		$titnr='';
		for ($i=1;$i<=$num;$i++){
			$titnr="$titnr$headnum[$i].";
		}
		$num++;
		pushout ("<h$num>$titnr $text</h$num>");
		if ($alineatype >0){$alineatype &=2;}
	}
	elsif (/^{HEADUNNUM ([0-9])}(.*)/){
		$num=$1;$text=$2;
		alineatabend;
		$num++;
		pushout("<h$num>$text</h$num>");
		if ($alineatype >0){$alineatype &=2;}
	}
	elsif (/^{IMAGE}(.*)/){
		alineatabend;
		pushout ("<br>");
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
		$text=$1;
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
		pushout("$1");
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
		pushout("$1");
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
		pushout("$1");
		pushout("</li>");
	}
	elsif (/^{LISTNUMSTART}/){
		pushout("<ol type=1>");
	}
	elsif (/^{LITTERAL}(.*)/){
		$text=$1;
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
		$text=$1;
		pushout("$notenum");
		pushnote("$notenum: $text");
		$notenum++;
	}
	elsif (/^{SET}([^ ]+) (.*)/){
	}
	elsif (/^{SIDENOTE}(.*)/){
		$text=$1;
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
		$text=$1;
		$colspan=''; $rowspan='';
		if ($text=~/<.s=[0-9]+>/){
			if ($text=~/<rs=([0-9]+)>/){
				$rowspan=" rowspan=\"$1\"";
				$text=~s/<rs=[0-9]*>//;
			}
			if ($text=~/<cs=([0-9]+)>/){
				$colspan=" colspan=\"$1\"";
				$text=~s/<cs=[0-9]*>//;
			}
			pushout ("<td$colspan$rowspan>$text</td>");
		}
		elsif ($text=~/<.SPAN>/){}
		else {
			pushout ("<td>$text</td>");
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
$alinetype=-1;

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
	debug($DEB_CHAR,"Replace $char with $html");
	for my $i (0..$#output){
		$output[$i]=~s/$char/$html/g;
		debug($DEB_CHAR,"New: $output[$i]");
		
	}
}

if ($variables{'interpret'}==1){
	for my $i (0..$#output){
		$changed=1;
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
		$changed=1;
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
		$qis=s/=/=/g;
		$repl='&nbsp;'x$qis;
		s/===*>/$repl/;
	}
}
for (@output){
	if (!(/^$/)){
		print "$_\n";
	}
}
