#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3tbl
use strict;
use warnings;
################################################################################
#	Debugging where required
################################################################################
my $DEBUG=0;
my $DEB_FILE=1;		#files that are opened or closed
my $DEB_TABLE=2;		#all table-processing stuff
my $DEB_ALINEA=32;	#alinea processing
my $DEB_CHAR=64;		#replace characters with GROFF escapes
my $DEB_IMG=128;		#Image processing

sub debug {
	(my $level,my $msg)=@_;
	if ($DEBUG & $level){
		print STDERR "in3tbl DEBUG $level: $msg\n";
	}
}

################################################################################
#	Alinea processing
################################################################################
my $alineatype=-1;		# -1	Outside alineas
					#  0	Alinea without sidenotes
					#  1	Leftnote
					#  2	Sidenote right
					#  3	Notes left & right
# The sizes below are taken somewhat arbitrarily. Tbl considers itself
# free to change them anyway.
my $LEFTNOTE=2;			
my $BODYTEXT=11;
my $SIDENOTE=4;
my $actualbody=$LEFTNOTE+$BODYTEXT+$SIDENOTE;
my $appendix=0;

debug($DEB_ALINEA,"Initial alinea=-1");

sub alineatabend{			
	if ($alineatype>0){pushout (".TE");}
	$alineatype=-1;
}
sub alineatabstart{
	if ($alineatype==0){
	}
	elsif ($alineatype==1){
		$actualbody=$BODYTEXT+$SIDENOTE;
		pushout(".TS");
		pushout("tab(@);");
		pushout("l l.");
		pushout("T{");
		pushout(".ll $LEFTNOTE"."c");
	}
	elsif ($alineatype==2){
		$actualbody=$LEFTNOTE+$BODYTEXT;
		pushout(".TS");
		pushout("tab(@);");
		pushout("l lp6.");
		pushout("T{");
		pushout(".ll $actualbody"."c");
	}
	elsif ($alineatype==3){
		$actualbody=$BODYTEXT;
		pushout(".TS");
		pushout("tab(@);");
		pushout("l l lp6.");
		pushout("T{");
		pushout(".ll $LEFTNOTE"."c");
	}
}

################################################################################
my @output;
sub pushout{
	(my $txt)=@_;
	push @output,$txt;
}


################################################################################
# Macro for encapsulated postsrcipt files (typically images)
#
################################################################################
sub img_macro {
print ".de dospark
.psbb \\\\\$1
.nr ht0 \\\\n[ury]-\\\\n[lly]
.nr wd0 \\\\n[urx]-\\\\n[llx]
.nr deswd (\\\\n[.ps]/\\\\n[ht0])*\\\\n[wd0]
.if \\\\\$2&(\\\\\$2>0) .nr deswd (u; \\\\\$2p)
.nr desht \\\\n[.ps]
.if \\\\\$3 .nr desht (u; \\\\\$3p)
.nr xht 0
.if (\\\\n[desht]>\\\\n[.ps]) .nr xht \\\\n[desht]-\\\\n[.ps]
\\X’ps: import \\\\\$1 \\
\\\\n[llx] \\\\n[lly] \\\\n[urx] \\\\n[ury] \\
\\\\n[deswd] \\\\n[desht]’\\
\\h’\\\\n[deswd]u’\\x’-\\\\n[xht]u’
..
";
}

################################################################################
#
# If a style sheet for roff exists, copy is to the output. Otherwise
# use some default styling.
#
################################################################################
sub stylesheet {
	if (open (my $STYLE,'<',"stylesheet.mm")){
		debug ($DEB_FILE,"Stylesheet found");
		while (<$STYLE>){chomp;push @output,$_;}
		close $STYLE;
	}
	else {
		debug ($DEB_FILE,"No stylesheet found");
		push @output, ".nr Ej 0";
		push @output, ".ds HF  3 3 2 2 2 2 2 ";
		push @output, ".nr Hb 4";
		push @output, ".nr Hs 1";
		push @output, ".nr Hps 0";
		push @output, ".ds HP  14 12 12 0 0 0 0";
	}
}
################################################################################

my $litteraltext=0;
my $litlines=2;
my @litblock;
sub pushlit{
      (my $text)=@_;
      $litteraltext=1;
	  $litlines++;
      push @litblock,$text;
}

my $inquote=0;
################################################################################

my @thistable;
my $intable=0;
my %variables=();
my $cover='';
$variables{'interpret'}=1;
my @in3=<>;

$variables{'cp1'}=10;
$variables{'cp2'}=5;
$variables{'cp3'}=5;
$variables{'cp4'}=5;
$variables{'cp5'}=5;
$variables{'cp6'}=4;
$variables{'cp7'}=4;
$variables{'cp8'}=4;
$variables{'cp9'}=2;

################################################################################
#	Cover processing
################################################################################

for (@in3){
	if (/^{COVER}(.*)/){ $cover=$1;}
}
if ($cover ne ''){
	pushout(".PGNH");
	pushout(".ds pg*header");
}

img_macro;
stylesheet;

if ($cover ne ''){
	my $epsfile=$cover; $epsfile=~s/\.[^.]+$/.eps/;
	system("convert $cover $epsfile");
	pushout(".ce 1");
	pushout(".dospark $epsfile 19c 27.5c");
	pushout(".nr P 0");

}
################################################################################
#	Cover sheet  processing
################################################################################

my $coversheet=0;
my $title;
my $subtitle;
my $author;
for (@in3){
	if (/^{TITLE}(.*)/){ $coversheet=1;}
}
if ($coversheet > 0){
	for (@in3){
		if (/^{TITLE}(.*)/){
			$title=$1;
			pushout(".PGNH");
			pushout(".bp 0");
			pushout(".sv 4c");
			pushout(".sp 2c");
			pushout(".ls 3");
			pushout(".ps +16");
			pushout(".ce 1");
			pushout("$title");
			pushout(".ps");
			pushout(".P");
			pushout(".ls 1");
			pushout(".sp 2c");

		}
		if (/^{SUBTITLE}(.*)/){
			$subtitle=$1;
			pushout(".ps +8");
			pushout(".ls 2");
			pushout(".ce 1");
			pushout("$subtitle");
			pushout(".ps");
			pushout(".P");
			pushout(".ls 1");
			pushout(".sp 3c");

		}
		if (/^{AUTHOR}(.*)/){
			$author=$1;
			pushout(".sp 1c");
			pushout(".ps +10");
			pushout(".ls 2");
			pushout(".ce 1");
			pushout("$author");
			pushout(".ps");
			pushout(".P");
			pushout(".ls 1");

		}
	}
	pushout(".nr P 0");
	pushout(".bp");
	
}

################################################################################
pushout(".ds pg*header ''- \\\\nP -''");

################################################################################
# Main loop
################################################################################
for (@in3){
	chomp;
	if ($inquote==1){
		if (/^{QUOTE}/){}
		else {$inquote=0;pushout(".br");}
	}
	if($litteraltext==1){
		if (/^{LITTERAL}/){}
		else {
			pushout(".P");
			if ($litlines>50){
				$litlines=$litlines-50;
				pushout(".ne 50v");
			}
			else {
				pushout(".ne ".$litlines."v");
			}
			pushout(".B1");
			pushout(".ft CR");
			pushout(".ps -2");
			for my $i (0..$#litblock){
				pushout(".br");
				pushout("{LITTERAL}$litblock[$i]");
				if (($i % 50)==49){
					pushout("");
					pushout("");
					pushout(".ps");
					pushout(".ft");
					pushout(".B2");
					pushout(".P");
					if ($litlines>50){
						$litlines=$litlines-50;
						pushout(".ne 50v");
					}
					else {
						pushout(".ne ".$litlines."v");
					}
					pushout(".B1");
					pushout(".ft CR");
					pushout(".ps -2");
				}
					
			}
			pushout("  ");
			pushout(".ps");
			pushout(".ft");
			pushout(".B2");
			undef @litblock;
			$litteraltext=0;
			$litlines=2;
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
			if ($alineatype==1){pushout("T{");pushout(".ll $LEFTNOTE"."c");}
			elsif ($alineatype==2){pushout("T{");pushout(".ll $actualbody"."c");}
			elsif ($alineatype==3){pushout("T{");pushout(".ll $LEFTNOTE"."c");}
		}
		pushout(".ne 3");
			
	}
	elsif (/^{ALINEAEND}/){
		if ($alineatype<0){$alineatype=0;}
		elsif ($alineatype==0){
			pushout(".P");
		}
		elsif ($alineatype>0){
			pushout("T}")
		}
	}
	elsif (/^{APPENDIX}(.*)/){
		my $aptxt=$1;
		if ($aptxt eq ''){ $aptxt="Appendix"; }
		$appendix++;
		pushout(".HM A 1 1 1 1 1 1 1 1 1 1 1");
		pushout(".nr H1 0");

	}
	elsif (/^{AUTHOR}/){
	}
	elsif (/^{COVER}/){
	}
	elsif (/^{INCLUDE}/){
	}
	elsif (/^{HEADER ([0-9])}(.*)/){
		alineatabend;
		if ($1==1){
			my $dist=$variables{'cp1'};
			pushout(".ne $dist"."v");
			# pushout(".bp")
			if ($appendix==0){
				pushout(".H $1 \"$2\"");
			}
			else {
				# 	pushout (".APP '$2'");
				pushout(".H $1 \"$2\"");
			}
		}
		else {
			my $var="cp$1";
			my $dist=$variables{$var};
			pushout (".ne $dist"."v");
			pushout(".H $1 \"$2\"");
		}
	}
	elsif (/^{HARDPARAGRAPH}/){
		pushout (".sp");
	}
	elsif (/^{HEADUNNUM ([0-9])}(.*)/){
		my $level=$1;
		my $text=$2;
		alineatabend;
		pushout(".nr Hu $level");
		if ($level<2){
			pushout(".bp");
			pushout(".ps +12");
			pushout(".ls 3");
			pushout(".P");
			pushout("");
		}
		else{
			pushout(".ps +10");
			pushout(".ls 2");
			pushout(".P");
			pushout("");
		}
		pushout(".HU \"$text\"");
		if ($level<2){
			pushout(".P");
			pushout(".ps +0");
			pushout(".ls 1");
			pushout(".P");
			pushout("");
		}
		else{
			pushout(".ls 1");
			pushout(".ps +0");
			pushout(".P");
			pushout("");
		}
	}
	elsif (/^{IMAGE}(.*)/){
		my $image=$1;
		debug($DEB_IMG,"Processing $image");
		my $epsfile=$image; $epsfile=~s/\.[^.]+$/.eps/;
		debug($DEB_IMG,"convert $image $epsfile");
		system("convert $image $epsfile");
		my $imgsize=` imageinfo --geom $image`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$xn=($x*150+2000)/($x*5+1000); $y=$y*$xn/$x;
		pushout(".br");
		my $found=0;
		my $yroom=$y+15;
		for (my $i=0; $i<10;$i++){
			my $qout=$#output;
			if ($output[$qout-$i]=~/^\.ne/){
				$output[$qout-$i]=".ne $yroom"."v";
				$found=1;
			}
		}
		alineatabend;
		if ($found == 0){pushout(".ne $y"."v");}
		pushout(".ce 1");
		pushout(".dospark $epsfile $xn"."v $y"."v");
		pushout(".br");
	}
	elsif (/^{LANGUAGE}/){
	}
	elsif (/^{LEFTNOTE}(.*)/){
		pushout("$1");
		pushout("T}\@T{");
		pushout(".ll $actualbody"."c");
	}
	elsif (/^{LINE}/){
		alineatabend;
		pushout(".br");
		pushout(".ce 1");
		pushout("\\l'18c'");
		pushout(".br");
		alineatabstart;

	}
	elsif (/^{LINK}([^ ]*) (.*)/){
		pushout("$2");
	}
	elsif (/^{LINEBREAK}/){
		pushout(".br");
	}
	elsif (/^{LISTALPHAEND}/){
		pushout(".LE 1");
	}
	elsif (/^{LISTALPHAITEM}(.*)/){
		pushout(".LI");
		pushout("$1");
	}
	elsif (/^{LISTALPHASTART}/){
		pushout(".AL a");
	}
	elsif (/^{LISTDASHEND}/){
		pushout(".LE 1");
	}
	elsif (/^{LISTDASHITEM}(.*)/){
		pushout(".LI");
		pushout("$1");
	}
	elsif (/^{LISTDASHSTART}/){
		pushout(".DL");
	}
	elsif (/^{LISTNUMEND}/){
		pushout(".LE 1");
	}
	elsif (/^{LISTNUMITEM}(.*)/){
		pushout(".LI");
		pushout("$1");
	}
	elsif (/^{LISTNUMSTART}/){
		pushout(".AL 1");
	}
    elsif (/^{LITTERAL}(.*)/){
        pushlit($1);
    }
	elsif (/^{MAPFIELD}(.*)/){
      }
	elsif (/^{MAPEND}(.*)/){
      }
	elsif (/^{MAPSTART}(.*)/){
      }
	elsif (/^{MAPPICT}(.*)/){
		my $image=$1;
		debug($DEB_IMG,"Processing $image");
		my $epsfile=$image; $epsfile=~s/\.[^.]+$/.eps/;
		debug($DEB_IMG,"convert $image $epsfile");
		system("convert $image $epsfile");
		my $imgsize=` imageinfo --geom $image`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$xn=($x*150+2000)/($x*5+1000); $y=$y*$xn/$x;
		pushout(".br");
		my $found=0;
		my $yroom=$y+25;
		for (my $i=0; $i<10;$i++){
			my $qout=$#output;
			if ($output[$qout-$i]=~/^\.ne/){
				$output[$qout-$i]=".ne $yroom"."v";
				$found=1;
			}
		}
		alineatabend;
		if ($found == 0){pushout(".ne $yroom"."v");}
		pushout(".ce 1");
		pushout(".dospark $epsfile $xn"."v $y"."v");
		pushout(".br");
	}
	elsif (/^{NOTE}(.*)/){
		my $qout=$#output;
		$output[$qout]=$output[$qout].".\\*F";
		pushout(".FS");
		pushout("$1");
		pushout(".FE");
	}
	elsif (/^{NOP}/){
	}
	elsif (/^{PAGE}/){
		pushout(".bp");
	}
	elsif (/^{QUOTE}/){
		s/^{QUOTE}//;
		if ($inquote==0){
			$inquote=1;
			pushout(".br");
		}
		pushout(".I \" $_ \"");
	}
	elsif (/^{SET}([^ ]+) (.*)/){
		my $val;
		$variables{$1}=$2;
		if ($1 eq 'H1'){ $val=$2-1; pushout(".nr H1 $val");}
		elsif ($1 eq 'H2'){ $val=$2-1; pushout(".nr H2 $val");}
		elsif ($1 eq 'H3'){ $val=$2-1; pushout(".nr H3 $val");}
		elsif ($1 eq 'H4'){ $val=$2-1; pushout(".nr H4 $val");}
		elsif ($1 eq 'H5'){ $val=$2-1; pushout(".nr H5 $val");}
		elsif ($1 eq 'H6'){ $val=$2-1; pushout(".nr H6 $val");}
	}
	elsif (/^{SIDENOTE}(.*)/){
		pushout("T}\@T{");
		pushout(".ll $SIDENOTE"."c");
		pushout("$1");
	}
	elsif (/^{SUBTITLE}/){
	}
	elsif (/^{TABLEEND}/){
		$intable=0;
		if ($alineatype<0){}
		elsif ($alineatype==0){
			pushout(".P");
		}
		elsif ($alineatype>0){
			pushout(".TE");
			pushout(".P");
		}
		$alineatype=-1;
		pushout(".ne 20v");
		pushout(".TS H");
		my $outline="allbox,center;";
		debug($DEB_TABLE,"Start a table");
		pushout ($outline);
		my $frst=1;
		for (@thistable){
			if (/^{TABLEROW}/){ $outline=''; $frst=1;}
			elsif (/^{TABLEHEAD}/){
				$outline='';
				$frst=1;
			}
			elsif (/^{TABLECEL}<VSPAN>/){
				if ($frst==1){
					$frst=0;
					$outline .= "^";
				}
				else{
					$outline .= " ^";
				}
			}
			elsif (/^{TABLECEL}<HSPAN>/){
				if ($frst==1){
					# This should not happen in a correctly formatted table.
					$frst=0;
					$outline .= "s";
				}
				else{
					$outline .= " s";
				}
			}
			elsif (/^{TABLECEL}/){
				if ($frst==1){
					$frst=0;
					$outline .= "l";
				}
				else{
					$outline .= " l";
				}
			}
			elsif (/^{TABLEROWEND}/){
				pushout ($outline);
			}
		}
		$output[$#output] .= ".";
		#pushout(".TS H");
		pushout (".TH");
		$frst=1;
		my $thead=0;
		my $learcell=0;
		for (@thistable){
			my $text;
			if (/^{TABLEROW}/){ $outline=''; $frst=1;}
			elsif (/^{TABLECEL}/){
				s/{TABLECEL}//;
				s/<cs=.*>//;
				s/<rs=.*>//;
				if(/<VSPAN>/){$text="";}
				elsif(/<HSPAN>/){$text="";}
				else {
					$text=$_;
					if (/<br>/){
						$text=~s/<br>/\n.br\n/g;
					}
					$text="T{\n$text\nT}";

				}
				if ($frst==1){
					$frst=0;
					$outline = "$text";
				} 
				elsif ($text ne '') {
					$outline .= "	$text";
				}
				debug($DEB_TABLE,"CELL: outline=$outline");
		
			}
			elsif (/{TEXTNORMAL}(.*)/){ 	#Seen as an extension of the last cell
				my $text=$1;
				$outline=~s/T}$/$text\nT}/;
				debug($DEB_TABLE,"NORMAL: outline=$outline");
			}
			elsif (/{TEXTBOLD}(.*)/){
				my $text=$1;
				$outline=~s/T}$/.B "$text"\nT}/;
				debug($DEB_TABLE,"BOLD: outline=$outline");
			}
			elsif (/{TEXTUNDERLINE}(.*)/){
				my $text=$1;
				$outline=~s/T}$/.underline "$text"\nT}/;
				debug($DEB_TABLE,"UNDL: outline=$outline");
			}
			elsif(/{TABLEROWEND}/){
				$outline='' unless defined $outline;
				if ($outline=~/^	*$/){}
				else {pushout ($outline);}
			}
		}
		undef @thistable;
		pushout(".TE");
		pushout(".sp");

	}
	elsif (/^{TABLE/){
		#if ($intable<1){pushout (".ne 10v");}
		$intable=1;
		push @thistable,$_;
	}
	elsif (/^{TEXTBOLD}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			pushout(".B \"$1\"");
		}
	}
	elsif (/^{TEXTFIX}(.*)/){
		pushout(".ft CR");
		pushout(".ps -2");
		pushout("$1");
		pushout(".ps");
		pushout(".ft");
	}
	elsif (/^{TEXTNORMAL}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			if (/^{TEXTNORMAL}(\..*)/){
				pushout(" $1");
			}
			else {
				pushout("$1");
			}
		}
	}
	elsif (/^{TEXTITALIC}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			s/^{TEXTITALIC}//;
			s/"/\\[rq]/g;
			pushout(".I \" $_ \"");
		}
	}
	elsif (/^{TEXTUNDERLINE}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			pushout(".underline \"$1\"");
		}
	}
	elsif (/^{TITLE}(.*)/){
	}
	elsif (/^{.*}/){
		print STDERR "in3tbl Unknown $_\n";
	}
}

alineatabend;
$alineatype=-1;

pushout(".TC");

################################################################################
# Post processing
################################################################################

################################################################################
#  Char-map processing
################################################################################
# Depending on the interpret-flag, replace specific characters by their GROFF
# specific escaped ones.
# In the end, replace all HTML-characters by their GROFF equivalent.

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
else { print STDERR "in3tbl Cannot open in3charmap\n"; }


if ($variables{'interpret'}==1){
	print STDERR "in3tbl INTERPRET =$variables{'interpret'}\n";
	for my $i (0..$#output){
		my $changed=1;
		while ($changed==1){
			$changed=0;
			if ($output[$i]=~/(.*)\%\*([^ ]*)\%\*(.*)/){
				$output[$i]="$1\\fB$2\\fP$3";
				$changed=1;
			}
			if ($output[$i]=~/(.*)\%_([^ ]*)\%_(.*)/){
				$output[$i]="$1\\fI$2\\fP$3";
				$changed=1;
			}
		}
	}
}
if ($variables{'interpret'}==2){
	print STDERR "in3tbl INTERPRET =$variables{'interpret'}\n";
	for my $i (0..$#output){
		my $changed=1;
		while ($changed==1){
			$changed=0;
			if ($output[$i]=~/(.*)\*([^ ]*)\*(.*)/){
				$output[$i]="$1\\fB$2\\fP$3";
				$changed=1;
			}
			if ($output[$i]=~/(.*)_([^ ]*)_(.*)/){
				$output[$i]="$1\\fI$2\\fP$3";
				$changed=1;
			}
		}
	}
}

for (@charmap){
	chomp;
	my $char;
	my $groff;
	my $html;
	($char,$groff,$html)=split '	';
	$char='UNDEFINED_CHAR' unless defined $char;
	$groff=$char unless defined $groff;
	$html=$char unless defined $html;
	debug($DEB_CHAR,"Replace $char and $html with $groff");
	for my $i (0..$#output){
		if ($output[$i]=~/$char/){
			$output[$i]=~s/$char/$groff/g;
			debug($DEB_CHAR,"Replaced $char with $groff : $output[$i]");
		}
		if ($output[$i]=~/$html/){
			$output[$i]=~s/$html/$groff/g;
		}
		debug($DEB_CHAR,"New: $output[$i]");
		
	}
}


for (@output){
	if (/^ \./){}
	elsif (/^{LITTERAL}/){
		s/^{LITTERAL}//;
		s/^\./\\&./;
	}
	else { s/^ *//;}
	if (/==>/){
		my $qis=s/=/=/g;
		my $repl='\~'x$qis;
		s/===*>/$repl/;
	}
	if (/^'/){
		s/^'/ '/;
	}
}
for (@output){
	if ($_ =~ '-EMPTY LINE-'){
		print "$_\n";
	}
	else {
		print "$_\n";
	}
}
