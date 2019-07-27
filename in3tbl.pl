#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3tbl
use strict;
use warnings;
use open ':std' => ':encoding(UTF-8)';
use utf8;
#
#       _      _                 
#    __| | ___| |__  _   _  __ _ 
#   / _` |/ _ \ '_ \| | | |/ _` |
#  | (_| |  __/ |_) | |_| | (_| |
#   \__,_|\___|_.__/ \__,_|\__, |
#                          |___/ 
#
my $DEBUG=0;
my $DEB_FILE=1;		#files that are opened or closed
my $DEB_TABLE=2;		#all table-processing stuff
my $DEB_CMD=4;			#Command found
my $DEB_NOTE=8;			# Notes
my $DEB_ALINEA=32;	#alinea processing
my $DEB_CHAR=64;		#replace characters with GROFF escapes
my $DEB_IMG=128;		#Image processing
my $DEB_BLOCK=256;		#all pushes on the output
my $DEB_PUSH=512;		#all pushes on the output

sub debug {
	(my $level,my $msg)=@_;
	if ($DEBUG & $level){
		print "in3tbl DEBUG $level: $msg\n";
	}
}



################################################################################
#  _       _ _                         
# (_)_ __ (_) |_  __   ____ _ _ __ ___ 
# | | '_ \| | __| \ \ / / _` | '__/ __|
# | | | | | | |_   \ V / (_| | |  \__ \
# |_|_| |_|_|\__|   \_/ \__,_|_|  |___/
# 
my $inquote=0;

my @thistable;
my $intable=0;
my %variables=();
my $cover='';
$variables{'interpret'}=1;
$variables{'blockscale'}=100;
$variables{'blockinline'}=0;
$variables{'imgsize'}=15;
$variables{'linelength'}=17;
$variables{'indent'}=2;
$variables{'leftnote'}=2;
$variables{'sidenote'}=2;

#         _ _                  
#    __ _| (_)_ __   ___  __ _ 
#   / _` | | | '_ \ / _ \/ _` |
#  | (_| | | | | | |  __/ (_| |
#   \__,_|_|_|_| |_|\___|\__,_|
#			    
my $alineatype=-1;	# -1	Outside alineas
					#  0	Alinea without sidenotes
					#  1	Leftnote
					#  2	Sidenote right
					#  3	Notes left & right
my $inlist=0;
my $inalinea=0;
my $inalineacel=0;
# The sizes below are taken somewhat arbitrarily. Tbl considers itself
# free to change them anyway.
my $LEFTNOTE=2;			
my $BODYTEXT=10;
my $SIDENOTE=4;
my $actualbody=$LEFTNOTE+$BODYTEXT+$SIDENOTE;
my $appendix=0;

debug($DEB_ALINEA,"Initial alinea=-1");

sub alineatabend{			
	if ($inalineacel>0){
		pushout ('T}');
		$inalineacel=0;
	}
	if ($inalinea==1){
		if ($alineatype>0){pushout (".TE");}
		debug($DEB_ALINEA,"alinea tab end alineatype=$alineatype");
		$alineatype=-1;
		$inalinea=0;
	}
	$inalinea=0;
	debug($DEB_ALINEA,"alinea tab end exit alineatype=$alineatype inalinea=$inalinea");
}
sub alineatabstart{
	if ($inalinea==1){
		alineatabend();
	}
	$inalinea=1;
	if ($alineatype==0){
		#$actualbody=$variables{'linelength'}-$variables{'indent'};
		#pushout(".ll $variables{'linelength'}c");
		my $defll=$variables{'linelength'}-$variables{'indent'};
		pushout(".ll $defll".'c');
	}
	elsif ($alineatype==1){
		$actualbody=$variables{'linelength'}-$variables{'indent'}-$variables{'leftnote'}-0.05;
		pushout(".TS");
		$inalinea=1;
		pushout("tab(@);");
		pushout("lw($variables{'leftnote'}c) lw($actualbody"."c).");
		pushout("T{");
		$inalineacel=1;
	}
	elsif ($alineatype==2){
		$actualbody=$variables{'linelength'}-$variables{'indent'}-$variables{'sidenote'}-0.05;
		pushout(".TS");
		$inalinea=1;
		pushout("tab(@);");
		pushout("lw($actualbody"."c) lp6w($variables{'sidenote'}c).");
		pushout("T{");
		$inalineacel=1;
	}
	elsif ($alineatype==3){
		$actualbody=$variables{'linelength'}-$variables{'indent'}-$variables{'sidenote'}-$variables{'leftnote'}-0.15;
		pushout(".TS");
		$inalinea=1;
		pushout("tab(@);");
		pushout("lw($variables{'leftnote'}c) lw($actualbody"."c) lp6.");
		pushout("T{");
		$inalineacel=1;
	}
}

################################################################################
# _ __  _   _ ___| |__   ___  _   _| |_ 
#| '_ \| | | / __| '_ \ / _ \| | | | __|
#| |_) | |_| \__ \ | | | (_) | |_| | |_ 
#| .__/ \__,_|___/_| |_|\___/ \__,_|\__|
#|_| 
my @output;
my $pushlang='none';
sub pushout{
	(my $txt)=@_;
	debug ($DEB_PUSH,"--$txt--");
	if ($txt=~/[Ѐ-ӿ]/){
		if ($pushlang ne 'russian'){
			$pushlang='russian';
			push @output,".ft SFOR";
		}
	}
	else {
		if ($pushlang ne 'none'){
			$pushlang='none';
			push @output,".ft";
		}
	}
	if ($txt=~/^ *$/){}
	else {push @output,$txt;}
}


################################################################################
#      _                            _                                      
#   __| | ___  ___ _ __   __ _ _ __| | __     _ __ ___   __ _  ___ _ __ ___  
#  / _` |/ _ \/ __| '_ \ / _` | '__| |/ /    | '_ ` _ \ / _` |/ __| '__/ _ \ 
# | (_| | (_) \__ \ |_) | (_| | |  |   <     | | | | | | (_| | (__| | | (_) |
#  \__,_|\___/|___/ .__/ \__,_|_|  |_|\_\    |_| |_| |_|\__,_|\___|_|  \___/ 
# 
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
\\X'ps: import \\\\\$1 \\
\\\\n[llx] \\\\n[lly] \\\\n[urx] \\\\n[ury] \\
\\\\n[deswd] \\\\n[desht]'\\
\\h'\\\\n[deswd]u'\\x'-\\\\n[xht]u'
..
";
}

################################################################################
#      _         _           _               _   
#  ___| |_ _   _| | ___  ___| |__   ___  ___| |_ 
# / __| __| | | | |/ _ \/ __| '_ \ / _ \/ _ \ __|
# \__ \ |_| |_| | |  __/\__ \ | | |  __/  __/ |_ 
# |___/\__|\__, |_|\___||___/_| |_|\___|\___|\__|
#          |___/                                 

# If a style sheet for roff exists, copy is to the output. Otherwise
# use some default styling.
#
################################################################################
sub stylesheet {
	my $defll=$variables{'linelength'}-$variables{'indent'};
	push @output, ".ll $defll".'c';
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
#  _     _            _    
# | |__ | | ___   ___| | __
# | '_ \| |/ _ \ / __| |/ /
# | |_) | | (_) | (__|   < 
# |_.__/|_|\___/ \___|_|\_\
# 

my @block;
my $blocktype='none';
my $blockname='none';
my $blockformat='';
my $blockinline=0;


sub block_push {
	(my $txt)=@_;
	push @block,$txt;
}

sub block_end {
	my $blockscale=$variables{'blockscale'};
	$blockinline=$variables{'blockinline'};
	if($blockformat ne ''){
		if ($blockformat=~/scale=(\d+)/){ $blockscale=$1; }
		if ($blockformat=~/inline/){ $blockinline=1;}
	}
	if ($blockinline==0){
		alineatabend;
	}
	if ($blocktype eq 'pre'){
		# do nothing; pre is handled as {LITTERAL}
	}
    elsif ($blocktype eq 'music'){
        debug($DEB_BLOCK,"block type music");
        my $density=1000;
        if ($blockname eq 'none') {
            my $random=int(rand(1000000));
            $blockname="gen_$random";
        }
        system ("rm block_$blockname.*");
        if (open (my $MUSIC, '>',"block_$blockname.ly")){
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
            my $b_image;
            $b_image="block_$blockname.png";
            system ("lilypond -dbackend=eps  -dresolution=500 -dpreview block_$blockname.ly");
			my $scale=$blockscale;
			my $epsfile="block_$blockname.eps";
			debug($DEB_IMG,"Processing $epsfile");
			my $imgsize=` imageinfo --geom $epsfile`;
			my $x; my $y; my $xn;
			($x,$y)=split ('x',$imgsize);
			$xn=$x/12; $y=$y/12;
			$xn=$scale*$xn/250;
			$y=$scale*$y/250;
			if ($blockinline==0){
				alineatabend;
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
				if ($found == 0){pushout(".ne $y"."v");}
				pushout(".ce 1");
			}
			my $up=$y/20;
			pushout("\\v'$up"."c'");
			pushout(".dospark $epsfile $xn"."v $y"."v");
			pushout("\\v'-$up"."c'");
			if ($blockinline==0){
				pushout(".br");
			}

        }
        else {
            print STDERR "in3tbl cannot open $blockname\n";
        }
    }

	elsif ($blocktype eq 'gnuplot'){
        if ($blockname eq 'none') {
            my $random=int(rand(1000000));
            $blockname="gen_$random";
        }

        if (open (my $GNUPLOT,'>',"block_$blockname.gnuplot")){
            print $GNUPLOT 'set terminal postscript eps';
            print $GNUPLOT "\nset output 'block_$blockname.eps'\n";
            for (@block){ print $GNUPLOT "$_\n"; }
            close $GNUPLOT;
            my $b_image;
            system("gnuplot block_$blockname.gnuplot");
            $b_image="block_$blockname.eps";
			my $scale=$blockscale;
			my $epsfile="block_$blockname.eps";
			debug($DEB_IMG,"Processing $epsfile");
			my $imgsize=` imageinfo --geom $epsfile`;
			my $x; my $y; my $xn;
			($x,$y)=split ('x',$imgsize);
			$xn=($x*150+2000)/($x*5+1000); $y=$y*$xn/$x;
			$xn=$scale*$xn/100;
			$y=$scale*$y/100;

			alineatabend;
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
			if ($found == 0){pushout(".ne $y"."v");}
			pushout(".ce 1");
			pushout(".dospark $epsfile $xn"."v $y"."v");
			pushout(".br");
        }
        else {
            print STDERR "in3tbl cannot open $blockname.gnuplot\n";
        }

	}
	elsif ($blocktype eq 'texeqn'){
		my $density=1000;
        if ($blockname eq 'none') {
            my $random=int(rand(1000000));
            $blockname="gen_$random";
        }
        if (open (my $TEXEQN,'>',"block_$blockname.tex")){
		
			print $TEXEQN "\\documentclass{article}\n";
			print $TEXEQN "\\usepackage{amsmath}\n";
			print $TEXEQN "\\usepackage{amssymb}\n";
			print $TEXEQN "\\usepackage{algorithm2e}\n";
			print $TEXEQN "\\begin{document}\n";
			print $TEXEQN "\\begin{titlepage}\n";
			print $TEXEQN "\\begin{equation*}\n";
            for (@block){ 
				#s/\\/\\\\/g;
				print $TEXEQN "$_\n";
			}
			print $TEXEQN "\\end{equation*}\n";
			print $TEXEQN "\\end{titlepage}\n";
			print $TEXEQN "\\end{document}\n";
            close $TEXEQN;
            my $b_image;
            my $d_image;
            $b_image="block_$blockname.eps";
            $d_image="block_$blockname.dvi";
            system("echo '' |latex block_$blockname.tex > /dev/null 2>/dev/null");
			system("convert  -trim  -density $density  $d_image  $b_image");
			my $scale=$blockscale;
			my $epsfile="block_$blockname.eps";
			debug($DEB_IMG,"Processing $epsfile");
			my $imgsize=` imageinfo --geom $epsfile`;
			my $x; my $y; my $xn;
			($x,$y)=split ('x',$imgsize);
			$xn=$x/12; $y=$y/12;
			$xn=$scale*$xn/100;
			$y=$scale*$y/100;
			if ($blockinline==0){
				alineatabend;
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
				if ($found == 0){pushout(".ne $y"."v");}
				pushout(".ce 1");
			}
			pushout("\\v'.1'");
			pushout(".dospark $epsfile $xn"."v $y"."v");
			pushout("\\v'-.1'");
			if ($blockinline==0){
				pushout(".br");
			}
        }
        else {
            print STDERR "in3tbl cannot open $blockname\n";
        }

	}
	elsif ($blocktype eq 'eqn'){
		if ($blockinline==0){
			pushout (".br");
			pushout (".EQ");
		}
		else {
			pushout ('.EQ');
			pushout('delim $$');
			pushout (".EN");
		}
		for (@block){
			if ($blockinline==0){
				pushout ($_);
			}
			else {
				pushout ("\$$_\$");
			}

		}
		if ($blockinline==0){
			pushout (".EN");
			pushout (".br");
		}
		else {
			pushout ('.EQ');
			pushout('delim off');
			pushout (".EN");
		}

	}
	elsif ($blocktype eq 'pic'){
		# pic does not support in-line pictures. Therefore, in3tbl does not support them either.
		if ($blockinline==0){pushout (".br");}
		pushout (".PS");
		for (@block){
			pushout ($_);
		}
		pushout (".PE");
		if ($blockinline==0){pushout (".br");}

	}
	else {
		for (@block){
			pushout ($_);
		}
	}

	undef @block;
	$blocktype='none';
	$blockname='none';
	$blockformat='';
	$blockinline=0;
}



################################################################################
#  _ _ _   _                 _ 
# | (_) |_| |_ ___ _ __ __ _| |
# | | | __| __/ _ \ '__/ _` | |
# | | | |_| ||  __/ | | (_| | |
# |_|_|\__|\__\___|_|  \__,_|_|
# 
my $litteraltext=0;
my $litlines=2;
my @litblock;
sub pushlit{
      (my $text)=@_;
      $litteraltext=1;
	  $litlines++;
      push @litblock,$text;
}



################################################################################
#                                             _       
#   __ _ _ __ __ _ _   _ _ __ ___   ___ _ __ | |_ ___ 
#  / _` | '__/ _` | | | | '_ ` _ \ / _ \ '_ \| __/ __|
# | (_| | | | (_| | |_| | | | | | |  __/ | | | |_\__ \
#  \__,_|_|  \__, |\__,_|_| |_| |_|\___|_| |_|\__|___/
#            |___/                                    


my $gotinput=0;
my @in3;

for (@ARGV){
	if (/^-h/){ print "in3tbl [-h] [-d<value>] [files]\n"; }
	elsif (/^-d([0-9][0-9]*)/) {$DEBUG=$1;}
	else {
		if (open (my $FH, '<',$_)){
			debug ($DEB_FILE,"opened $_ as input file");
			my @curinput=<$FH>;
			push @in3,@curinput;
			$gotinput++;
			close $FH;
		}
		else { print "in3tbl cannot open $_\n";}
	}
}
if ($gotinput==0){
	@in3=<STDIN>;
}

################################################################################
$variables{'cp1'}=10;
$variables{'cp2'}=5;
$variables{'cp3'}=5;
$variables{'cp4'}=5;
$variables{'cp5'}=5;
$variables{'cp6'}=4;
$variables{'cp7'}=4;
$variables{'cp8'}=4;
$variables{'cp9'}=2;

#                          
#   ___ _____   _____ _ __ 
#  / __/ _ \ \ / / _ \ '__|
# | (_| (_) \ V /  __/ |   
#  \___\___/ \_/ \___|_|   
#  

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
#                              _               _   
#   ___ _____   _____ _ __ ___| |__   ___  ___| |_ 
#  / __/ _ \ \ / / _ \ '__/ __| '_ \ / _ \/ _ \ __|
# | (_| (_) \ V /  __/ |  \__ \ | | |  __/  __/ |_ 
#  \___\___/ \_/ \___|_|  |___/_| |_|\___|\___|\__|
#

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
	}
	for (@in3){
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
	}
	for (@in3){
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
#pushout(".ll 21"."c");

#                  _            _                   
#  _ __ ___   __ _(_)_ __      | | ___   ___  _ __  
# | '_ ` _ \ / _` | | '_ \     | |/ _ \ / _ \| '_ \ 
# | | | | | | (_| | | | | |    | | (_) | (_) | |_) |
# |_| |_| |_|\__,_|_|_| |_|    |_|\___/ \___/| .__/ 
#                                            |_|

for (@in3){
	if (/^{(..*)}/){ debug ($DEB_CMD,$1); }
	chomp;
	if ($inquote==1){
		if (/^{QUOTE}/){}
		else {$inquote=0;pushout(".br");}
	}
	if($litteraltext==1){
		if (/^{LITTERAL}/){}
		else {
			alineatabend;
			if ($litlines>50){
				$litlines=$litlines-50;
				pushout(".ne 50v");
			}
			else {
				pushout(".ne ".$litlines."v");
			}
			my $defll=$variables{'linelength'}-$variables{'indent'};
			pushout(".ll $defll".'c');
			pushout(".B1");
			pushout(".ft CR");
			pushout(".ps -2");
			for my $i (0..$#litblock){
				pushout(".br");
				$litblock[$i]=~s/\\/\\\\/g;
				pushout("{LITTERAL}$litblock[$i]");
				if (($i % 50)==49){
					pushout("");
					pushout("");
					pushout(".ps");
					pushout(".ft");
					pushout(".B2");
					pushout(".P");
					alineatabend;
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
			if ($alineatype==1){
				pushout("T{");
				$inalineacel=1;
			}
			elsif ($alineatype==2){
				pushout("T{");
				$inalineacel=1;
			}
			elsif ($alineatype==3){
				pushout("T{");
				$inalineacel=1;
			}
		}
		pushout(".ne 3");
			
	}
	elsif (/^{ALINEAEND}/){
		if ($alineatype<0){$alineatype=0;}
		elsif ($alineatype==0){
			pushout(".P");
		}
		elsif ($alineatype>0){
			pushout("T}");
			$inalineacel=0;
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
	elsif (/^{BLOCKSTART}(.+) (.+)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			$blocktype=$1;
			$blockname=$2;
		}
	}
	elsif (/^{BLOCKFORMAT}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			$blockformat=$1;
		}
	}
	elsif (/^{BLOCK [^}]*}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			block_push($1);
		}
	}
	elsif (/^{BLOCKEND}/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			block_end();
		}
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
		my $scale=100;
		if (/ ([0-9][0-9]*)$/){
			$scale=$1;
			$image=~s/ [0-9][0-9]*//;
		}
		my $defll=$variables{'linelength'}-$variables{'indent'};
		if ($inlist==0){
			pushout(".ll $defll".'c');
			pushout(".SP");
		}
		debug($DEB_IMG,"Processing $image");
		my $epsfile=$image; $epsfile=~s/\.[^.]+$/.eps/;
		debug($DEB_IMG,"convert $image $epsfile");
		#system("convert -trim $image $epsfile");
		system("convert  $image  pnm:- | convert -trim - $epsfile");
		my $imgsize=` imageinfo --geom $image`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$xn=$variables{'imgsize'}; $y=$y*$xn/$x;
		$xn=$scale*$xn/100;
		$y=$scale*$y/100;

		if ($intable>0){
			$xn=$xn/4;
			$y=$y/4;
			#push @thistable,".dospark $epsfile $xn"."c $y"."c";
			push @thistable,$_;
		}
		else {
			alineatabend;
			pushout(".br");
			my $found=0;
			my $yroom=$y+5;
			for (my $i=0; $i<10;$i++){
				my $qout=$#output;
				if ($output[$qout-$i]=~/^\.ne/){
					$output[$qout-$i]=".ne $yroom"."c";
					$found=1;
				}
			}
			if ($found == 0){pushout(".ne $yroom"."c");}
			pushout(".ce 1");
			pushout(".dospark $epsfile $xn"."c $y"."c");
			pushout(".br");
		}
	}
	elsif (/^{LANGUAGE}/){
	}
	elsif (/^{LEFTNOTE}(.*)/){
		pushout("$1");
		debug ($DEB_NOTE,"leftnote --$1-- type=$alineatype, inalinea=$inalinea, inalineacel=$inalineacel");
		pushout("T}\@T{");
		$inalineacel=1;
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
		$inlist=0;
	}
	elsif (/^{LISTALPHAITEM}(.*)/){
		pushout(".LI");
		pushout("$1");
		$inlist=1;
	}
	elsif (/^{LISTALPHASTART}/){
		alineatabend;
		pushout(".AL a");
		$inlist=1;
	}
	elsif (/^{LISTDASHEND}/){
		pushout(".LE 1");
		$inlist=0;
	}
	elsif (/^{LISTDASHITEM}(.*)/){
		pushout(".LI");
		pushout("$1");
		$inlist=1;
	}
	elsif (/^{LISTDASHSTART}/){
		alineatabend;
		pushout(".DL");
		$inlist=1;
	}
	elsif (/^{LISTNUMEND}/){
		pushout(".LE 1");
		$inlist=0;
	}
	elsif (/^{LISTNUMITEM}(.*)/){
		pushout(".LI");
		pushout("$1");
		$inlist=1;
	}
	elsif (/^{LISTNUMSTART}/){
		alineatabend;
		pushout(".AL 1");
		$inlist=1;
	}
    elsif (/^{LITTERAL}(.*)/){
        pushlit($1);
    }
	elsif (/^{LST}(.*)/){
		pushout(".br");
		if ( $1 ne ''){
			my $txt=$1;
			$txt=~s/\\$/\\\\/;
			pushout(".ft CR");
			pushout(".ps -2");
			pushout("$txt");
			pushout(".ps");
			pushout(".ft");
		}
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
		debug ($DEB_NOTE,"sidenote --$1-- type=$alineatype, inalinea=$inalinea, inalineacel=$inalineacel");
		if ($inalinea>0){
			pushout("T}\@T{");
			$inalineacel=1;
			pushout("$1");
		}
	}
	elsif (/^{SUBSCRIPT}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			if (($inalinea==0)&&($inlist==0)){
				alineatabstart();
			}
			pushout(".DOWN");
			pushout("$1");
			pushout(".UP");
		}
	}
	elsif (/^{SUBTITLE}/){
	}
	elsif (/^{SUPERSCRIPT}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			if (($inalinea==0)&&($inlist==0)){
				alineatabstart();
			}
			pushout(".UP");
			pushout("$1");
			pushout(".DOWN");
		}
	}
	elsif (/^{TABLEEND}/){
		$intable=0;
		alineatabend;
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
					if ($text ne ''){
						$text="T{\n$text\nT}";
					}
					else {
						$text="T{\nT}";
					}

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
				if ($text ne ''){
					$outline=~s/T}$/$text\nT}/;
				}
				debug($DEB_TABLE,"NORMAL: outline=$outline");
			}
			elsif (/{TEXTBOLD}(.*)/){
				my $text=$1;
				if ($text ne ''){
					$outline=~s/T}$/.B "$text"\nT}/;
				}
				debug($DEB_TABLE,"BOLD: outline=$outline");
			}
			elsif (/{SUBSCRIPT}(.*)/){
				my $text=$1;
				if ($text ne ''){
					$outline=~s/T}$/\\d $text \\u/;
				}
				debug($DEB_TABLE,"BOLD: outline=$outline");
			}
			elsif (/{SUPERSCRIPT}(.*)/){
				my $text=$1;
				if ($text ne ''){
					$outline=~s/T}$/\\u $text \\d/;
				}
				debug($DEB_TABLE,"BOLD: outline=$outline");
			}
			elsif (/{TEXTUNDERLINE}(.*)/){
				my $text=$1;
				if ($text ne ''){
					$outline=~s/T}$/.underline "$text"\nT}/;
				}
				debug($DEB_TABLE,"UNDL: outline=$outline");
			}
		    elsif (/^{BLOCKSTART}(.+) (.+)/){
		        $blocktype=$1;
        		$blockname=$2;
    		}
    		elsif (/^{BLOCKFORMAT}(.*)/){
        		$blockformat=$1;
    		}
    		elsif (/^{BLOCK [^}]*}(.*)/){
        		block_push($1);
    		}
    		elsif (/^{BLOCKEND}/){
				my $endedcell=0;
				$outline='' unless defined $outline;
				chomp $outline;
				if($outline=~/T}$/){
					$outline=~s/T}$//;
					$endedcell=1;
				}
				chomp $outline;
				if ($outline=~/^[ 	]*$/){}
				else {pushout ($outline);}
        		block_end();
				if ($endedcell==1){
					$endedcell=0;
					$outline='T}'
				}
				else {
					$outline='';
				}
    		}
			elsif(/{IMAGE}([^ ]*).*([0-9]*)$/){
				my $image=$1;
				my $scale=25;
				if(/{IMAGE}([^ ]*).*([0-9]+)$/){
					$scale=$2;
				}
				debug($DEB_IMG,"Processing $image");
				my $epsfile=$image; $epsfile=~s/\.[^.]+$/.eps/;
				debug($DEB_IMG,"convert $image $epsfile");
				#system("convert -trim $image $epsfile");
				system("convert  $image  pnm:- | convert -trim - $epsfile");
				my $imgsize=` imageinfo --geom $image`;
				my $x; my $y; my $xn;
				($x,$y)=split ('x',$imgsize);
				$xn=$variables{'imgsize'}; $y=$y*$xn/$x;
				$xn=$scale*$xn/100;
				$y=$scale*$y/100;
				my $endedcell=0;
				$outline='' unless defined $outline;
				chomp $outline;
				if($outline=~/T}$/){
					$outline=~s/T}$//;
					$endedcell=1;
				}
				chomp $outline;
				if ($outline=~/^[ 	]*$/){}
				else {pushout ($outline);}
				pushout(".sp 0.25");
				pushout(".dospark $epsfile $xn"."c $y"."c");
				pushout(".sp -0.25");
				if ($endedcell==1){
					$endedcell=0;
					$outline='T}'
				}
				else {
					$outline='';
				}


    		}

			elsif(/{TABLEROWEND}/){
				$outline='' unless defined $outline;
				chomp $outline;
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
			if (($inalinea==0)&&($inlist==0)){
				alineatabstart();
			}
			pushout(".B \"$1\"");
		}
	}
	elsif (/^{TEXTFIX}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			if (($inalinea==0)&&($inlist==0)){
				alineatabstart();
			}
			pushout(".ft CR");
			pushout(".ps -2");
			pushout(" $1");
			pushout(".ps");
			pushout(".ft");
		}
	}
	elsif (/^{TEXTNORMAL}(.*)/){
		if ($intable>0){
			push @thistable,$_;
		}
		else {
			if (($inalinea==0)&&($inlist==0)){
				alineatabstart();
			}
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
			if (($inalinea==0)&&($inlist==0)){
				alineatabstart();
			}
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
			if (($inalinea==0)&&($inlist==0)){
				alineatabstart();
			}
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
	if ($_ =~/^$/){
	}
	else {
		print "$_\n";
	}
}
