#!/usr/bin/perl
#INSTALL@ /usr/local/bin/xml3roff
#
use strict;
use File::Basename;

my $trace=0;
my $DEBUG=1;

my @output;
sub output{
	for (@_){
		my $txt=$_;
		#if (/^ \./){ s/^ \./\\&./; }
		if ($txt=~/[Ѐ-ӿ]/){
			$txt=~s/([Ѐ-ӿ ]+)/\\f[SFOR]$1\\f[]/g;
		}

		push @output, $txt;
		if ($trace > 0){print STDERR "#                                                               output: $_\n";}
	}
}
sub outputreplace {
	(my $replace)=@_;
	pop @output;
	push @output,$replace;
}
sub outputlast {
	my $top=pop@output;
	push @output,$top;
	return $top;
}
sub nodupoutput {
	(my $te)=@_;
	my $mx=$#output;
	if ($output[$mx] ne $te){ push @output,$te;}
}




sub error {
	for (@_){
		print STDERR "$_\n";
	}
}


# Variables for overall use
my %variables;
    $variables{'sidechar'}='*';
    $variables{'sidesep'}=';';
    $variables{'notes'}=0;
    $variables{'interpret'}=1;
    $variables{'markdown'}=0;
    $variables{'inlineemp'}=0;
    $variables{'debug'}=$DEBUG;
    $variables{"appendix"}=-1;
    $variables{"H1"}=0;
    $variables{"H2"}=0;
    $variables{"H3"}=0;
    $variables{"H4"}=0;
    $variables{"H5"}=0;
    $variables{"H6"}=0;
    $variables{"H7"}=0;
    $variables{"H8"}=0;
    $variables{"H9"}=0;
    $variables{"blockcnt"}=0;
    $variables{"author"}='';
    $variables{"title"}='';
    $variables{"subtitle"}='';
    $variables{"cover"}='';
    $variables{"do_cover"}='no';
    $variables{"do_headers"}='yes';
    $variables{"imagex"}=800;
    $variables{"imagey"}=800;

my @input;
my @infile;

# Variables that are picked-up in sub-states and used when higher states close
my $varname='';
my $value='';
my $text='';			
my $name='';			
my $class='';
my $target='';
my $image;
my $file='';
my $level=0;
my $seq='';

# Control variables
my @listtype;
my @listblock;
push @listtype,'none';
my $listlevel=0;
my $ptableopen=0;		# Paragraph table is open. This allows using the same table
						# for different paragraphs
my $pcellopen=0;
my $inline=0;
my @sidenotes;
my @leftnotes;
my @blocktext='';
my $progressindicator=0;
my $fileline=0;
my $video;
my $type;
my $format;

sub debug {
	if ($variables{'debug'} >0){
		for (@_){
			print STDERR "debug: $_\n";
		}
	}
}
my $what='';
for (@ARGV){
	if ($what eq ''){
		if (/^--$/){ while (<STDIN>){push @input,$_;}}
		elsif (/^--debug([0-9]+)/){ $variables{"DEBUG"}=$1; }
		elsif (/^--debug=([0-9]+)/){ $variables{"DEBUG"}=$1; }
		elsif (/^-d$/){$what='debug';}
		elsif (/^--debug$/){$what='debug';}
		elsif (/^-c([0-9]+)/){ $variables{"H1"}=$1;$variables{"do_cover"}='no';}
		elsif (/^--chapter([0-9]+)/){ $variables{"H1"}=$1-1;$variables{"do_cover"}='no';}
		elsif (/^--chapter=([0-9]+)/){ $variables{"H1"}=$1-1;$variables{"do_cover"}='no';}
		elsif (/^-c$/){$what='chapter';$variables{"do_cover"}='no';}
		elsif (/^--chapter$/){$what='chapter';$variables{"do_cover"}='no';}
		elsif (/^--doheaders/){$variables{"do_headers"}='yes';}
		elsif (/^--do_headers/){$variables{"do_headers"}='yes';}
		elsif (/^--docover/){$variables{"do_cover"}='yes';}
		elsif (/^--do_cover/){$variables{"do_cover"}='yes';}
		elsif (/^-i([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^--interpret([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^--interpret=([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^-i$/){$what='interpret';}
		elsif (/^--interpret$/){$what='interpret';}
		elsif (/^-m/){$variables{"markdown"}=1;}
		elsif (/^--markdown/){$variables{"markdown"}=1;}
		elsif (/^--noheaders/){$variables{"do_headers"}='no';}
		elsif (/^--no_headers/){$variables{"do_headers"}='no';}
		elsif (/^--nocover/){$variables{"do_cover"}='no';}
		elsif (/^--no_cover/){$variables{"do_cover"}='no';}
		elsif (/^-+h/){ hellup(); }
		elsif (/^-p/){ $progressindicator=1;}
		elsif (/^-/){ print STDERR "$_ is not known as a flag; ignored.\n";}
		else {
			my $file=$_;
			my $ch;	# Chapter number from filename
			if ($file=~/^([0-9]+)_/){$ch=$1-1;} else {$ch=0;}
			if (open(my $IN,'<',$file)){
				$fileline=0;
				if ($ch>0){
					push @input,".set H1 $ch";
					$variables{"H1"}=$ch;
					push @infile,'INTERNAL';
				}
				while (<$IN>){
					push @input,$_;
					$fileline++;
					push @infile,"$file:$fileline";
				}
				close $IN;
			}
			else {print STDERR "Cannot open $_; ignored.\n";}
		}
	}
	elsif ($what eq 'debug'){
		if (/([0-9]+)/){ $variables{"H1"}=$1;}
		else {print STDERR "Can't find a numeric value for 'DEBUG' in $_; ignored the debug set.\n";}
		$what='';
	}
	elsif ($what eq 'chapter'){
		if (/([0-9]+)/){ $variables{"H1"}=$1-1;}
		else {print STDERR "Can't find a numeric value for chapter in $_; ignored the chapter set.\n";}
		$what='';
	}
	elsif ($what eq 'interpret'){
		if (/([0-9]+)/){ $variables{"interpret"}=$1;}
		else {print STDERR "Can't find a numeric value for interpretation in $_; ignored the interpretation set.\n";}
		$what='';
	}
	else { print STDERR "This should not be possible. (1)\n"; $what=''; }
}

if ($#input<0){
	$fileline=0;
	while (<STDIN>){
		$fileline++;
		push @input,$_;
		push @infile,"STDIN:$fileline";
	}
}

for (@input){
if (/^\./){s/^\./\\[char46]/;}
if (/^ \./){s/^ \./\\[char46]/;}
#if (/^\"./){s/^"/"\\[char46]/;}
}

#      _        _         _                   _
#  ___| |_ __ _| |_ ___  | | _____  ___ _ __ (_)_ __   __ _
# / __| __/ _` | __/ _ \ | |/ / _ \/ _ \ '_ \| | '_ \ / _` |
# \__ \ || (_| | ||  __/ |   <  __/  __/ |_) | | | | | (_| |
# |___/\__\__,_|\__\___| |_|\_\___|\___| .__/|_|_| |_|\__, |
#                                      |_|            |___/

my @states;
sub state_tos {
	return $states[$#states]
}
sub state_push {
	for (@_){
		push @states,$_;
	}
}
sub state_pop {
	my $retval=pop @states;
	return $retval;
}
state_push('outside');


my $linenumber=0;

for $linenumber (0 .. $#input){
	if ($input[$linenumber] =~/<side[note]*>/){ $variables{'notes'}=2;}
}

sub formatrequest {
	if ($input[$linenumber] =~/<underline>/){
		state_push('underline');
	}
	elsif ($input[$linenumber] =~/<italic>/){
		state_push('italic');
	}
	elsif ($input[$linenumber] =~/<bold>/){
		state_push('bold');
	}
	elsif ($input[$linenumber] =~/<center>/){
		state_push('center');
	}
	elsif ($input[$linenumber] =~/<lst>/){
		state_push('lst');
	}
	elsif ($input[$linenumber] =~/<fixed>/){
		state_push('fixed');
	}
	elsif ($input[$linenumber] =~/<video>/){
		$video='';
		$file='';
		$text='';
		state_push('video');
	}
	elsif ($input[$linenumber] =~/<image>/){
		$image='';
		$file='';
		$text='';
		state_push('image');
	}
	elsif ($input[$linenumber] =~/<block>/){
		$type='pre';
		$image='';
		$class='';
		undef@blocktext;
		state_push('block');
	}
	elsif ($input[$linenumber] =~/<link>/){
		$target='';
		$text='';
		state_push('link');
	}
	elsif ($input[$linenumber] =~/<set>/){
		state_push('set');
	}
	else {
		output ($input[$linenumber]);
	}

}

#  _
# (_)_ __ ___   __ _  __ _  ___  ___
# | | '_ ` _ \ / _` |/ _` |/ _ \/ __|
# | | | | | | | (_| | (_| |  __/\__ \
# |_|_| |_| |_|\__,_|\__, |\___||___/
#                    |___/

sub outimage {
	print STDERR "IMAGE TYPE $type \n";
	(my $img, my $iformat)=@_;
	my $scale=100;
	if ($iformat=~/scale=([0-9]+)/){ $scale=$1;}
	my $imagename='';
	$img=~s/"//g;
	$imagename=basename($img);
	$imagename=~s/\.\w+$/.eps/;
	my $dvifile=$img; $dvifile=~s/\.\w+$/.dvi/;
	my $imgstem=$imagename; $imgstem=~s/\.\w+$//;
	debug ("IMAGE VARS img=$img imagename=$imagename dvifile=$dvifile imgstem=$imgstem");
	if ($img=~/\.eps$/){
		debug ("img=eps");
		if ($img ne  "block/$imagename"){
			system ("rm block/$imagename");
			system ("eps2eps -B1 $img block/$imagename");
		}
	}
	elsif ($img=~/\.dvi$/){
		debug ("img=dvi");
		debug ("DVI block $imgstem.dvi");
		system ("dvips -E  $img -o block/$imagename");
	}
	else {
		debug ("img=other");
		system("convert  $img  pnm:- | convert -trim - block/$imagename");
	}
	# We now have an image in block/$imagename as .eps
	if ($iformat =~/inlinejhegfqewugfwueygfxqbugfquyfgxbqweuyfgbqeugfbqgefb/){
		#try that later
	}
	elsif ($type=~/music/) {
		debug ("IMAGE TYPE=music");
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$x=$x*$scale/100;
		$y=$y*$scale/100;
		debug("Music SIZE $x $y");
		if ($iformat=~/inline/){
			my $up=$y/4;
			output ("\\v'0.2'");
			output (".dospark block/$imagename $x $y");
			output ("\\v'-0.2'");
		}
		else {
			output ('.sp 1');
			output ('.ce 1');
			output (".dospark block/$imagename $x $y");
		}
	}
	elsif ($type=~/texeqn/) {
		debug ("IMAGE TYPE=texeqn");
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$x=$x*$scale/100;
		$y=$y*$scale/100;
		debug("Techeqn SIZE $x $y");
		if ($iformat=~/inline/){
			my $up=$y/4;
			output ("\\v'0.2'");
			output (".dospark block/$imagename $x $y");
			output ("\\v'-0.2'");
		}
		else {
			output ('.sp 1');
			output ('.ce 1');
			output (".dospark block/$imagename $x $y");
		}
	}
	else {
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		my $myscale=$scale;
		if ($x>$variables{'imagex'}){$myscale=$variables{'imagex'}*$scale/$x;}
		my $y2=$y*$myscale/$variables{'imagey'};
		if ($y2>$variables{'imagey'}){$myscale=$variables{'imagey'}*$scale/$y;}
		$y=$y*$myscale/750;
		$x=$x*$myscale/750;
		my $up=$y/100;
		my $need=$y*5;
		#output ("\\v'$up"."c'");
		if ($iformat=~/inline/){
			output ("\\v'$up".'v\'');
			output (".dospark block/$imagename $x $y");
			output ("\\v'-$up".'v\'');
		}
		else {
			output (".ne $need".'p');
			output ('.ce 1');
			$x=$x*4; $y=$y*4;
			output (".dospark block/$imagename $x $y");
		}
		#output (".PSPIC block/$imagename $x");
	}
}


sub close_paratable {
	if ($ptableopen>0){
		if ($pcellopen>0){
			if ($variables{'notes'}==1){
				output ('T}');
			}
			else{
				output ('T}@T{');
				if (($variables{'notes'}&2)>0){
					for (@sidenotes){ output ($_); }
					output ('T}');
				}
			}
			$pcellopen=0;
		}
		output ('.TE');
		$ptableopen=0;
	}
}

#  _        _     _        _             _         _                    _
# | |_ __ _| |__ | | ___  | | ___   ___ | | ____ _| |__   ___  __ _  __| |
# | __/ _` | '_ \| |/ _ \ | |/ _ \ / _ \| |/ / _` | '_ \ / _ \/ _` |/ _` |
# | || (_| | |_) | |  __/ | | (_) | (_) |   < (_| | | | |  __/ (_| | (_| |
#  \__\__,_|_.__/|_|\___| |_|\___/ \___/|_|\_\__,_|_| |_|\___|\__,_|\__,_|
#

my @thistable;
my $maxrow=0;
my $maxcol=0;
my $tablerow=0;
my $tablecol=0;
# tbl needs a definition before a table can be created.
sub table_lookahead{
	(my $start)=@_;
	my $localline=$start;
	my $substate='none';
	undef @thistable;
	while ($substate ne 'end'){
		chomp $input[$localline];
		if ($localline >$#input){
			$substate='end';
		}
		elsif ($substate eq 'none'){
			if ($input[$localline] =~ /<table>/){
				$maxrow=0;
				$maxcol=0;
				$tablerow=-1;
				$tablecol=-1;
				$substate='table';
			}
			elsif ($input[$localline] =~ /<\/table>/){
				$substate='end';
			}
		}
		elsif ($substate eq 'table'){
			if ($input[$localline] =~ /<row>/){
				$tablerow++;
				$tablecol=-1;
				if ($tablerow>$maxrow){$maxrow=$tablerow;}
				$substate='row';
			}
			elsif ($input[$localline] =~ /<\/table>/){
				$substate='end';
			}
		}
		elsif ($substate eq 'row'){
			if ($input[$localline] =~ /<\/row>/){
				$substate='table';
			}
			elsif ($input[$localline] =~ /<cell.*>/){
				$tablecol++;
				while ($thistable[$tablerow][$tablecol]=~/[rc][owl]*s[pan]*/){
					$tablecol++;
				}
				if ("$thistable[$tablerow][$tablecol]" eq ""){
					$thistable[$tablerow][$tablecol]="text";
				}
				if ($input[$localline] =~ /<cell[^>]*c[ol]*s[pan]*=([0-9]+)/){
					my $span=$1;
					for (my $i=1; $i<$span; $i++){
						$thistable[$tablerow][$tablecol+$i]="colspan";
					}
				}
				if ($input[$localline] =~ /<cell.*r[ow]*s[pan]*=([0-9]+)/){
					my $span=$1;
					for (my $i=1; $i<$span; $i++){
						$thistable[$tablerow+$i][$tablecol]="rowspan";
					}
				}
				if ("$thistable[$tablerow][$tablecol]" eq ""){
					$thistable[$tablerow][$tablecol]="text";
				}
				if ($tablecol>$maxcol){$maxcol=$tablecol;}
				$substate='cell';
			}
		}
		elsif ($substate eq 'cell'){
			if ($input[$localline] =~ /<\/cell>/){
				$substate='row';
			}
			elsif ($input[$localline] =~ /<\/row>/){
				$substate='table';
			}
			elsif ($input[$localline] =~ /<\/table>/){
				$substate='end';
			}
			else {
			}
		}
		$localline++;
	}
	my $vspace=2*$maxrow;
	nodupoutput (".ne $vspace".'v');
	output ('.TS');
	output ('expand,allbox,center;');
	for (my $i=0; $i<=$maxrow; $i++){
		my $rowfmt='';
		for (my $j=0; $j<=$maxcol; $j++){
			if ($thistable[$i][$j]=~/rowspan/){
				$rowfmt="$rowfmt ^";
			}
			elsif ($thistable[$i][$j]=~/colspan/){
				$rowfmt="$rowfmt s";
			}
			else {
				$rowfmt="$rowfmt l";
			}
		}
		$rowfmt=~s/^ //;
		if ($i==$tablerow){$rowfmt="$rowfmt.";}
		output ($rowfmt);
	}
	$maxrow=0;
	$maxcol=0;
}



#                  _         _
#  _ __ ___   __ _(_)_ __   | | ___   ___  _ __
# | '_ ` _ \ / _` | | '_ \  | |/ _ \ / _ \| '_ \
# | | | | | | (_| | | | | | | | (_) | (_) | |_) |
# |_| |_| |_|\__,_|_|_| |_| |_|\___/ \___/| .__/
#                                         |_|

$linenumber=0;
while ( $linenumber <= $#input){
	chomp $input[$linenumber];
	#$input[$linenumber]=~s/^ \./\\$./;
	$input[$linenumber]=~s/^[ 	]*//;
	my $state=state_tos();
	if ($trace>0){printf STDERR "# %10.10s - %8.8d : %s\n",($state,$linenumber,$input[$linenumber]);}
	if ($input[$linenumber] =~/<!--.*-->/){}

	elsif ($state  eq 'outside'){
		if ($input[$linenumber] =~/<in3xml>/){
			state_push('in3xml');
		}
	}
	elsif ($state  eq 'in3xml'){
		if ($input[$linenumber] =~/<\/in3xml>/){
			state_pop();
		}
		elsif ($input[$linenumber] =~/<title>/){
			state_push('title');
		}
		elsif ($input[$linenumber] =~/<subtitle>/){
			state_push('subtitle');
		}
		elsif ($input[$linenumber] =~/<author>/){
			state_push('author');
		}
		elsif ($input[$linenumber] =~/<video>/){
			close_paratable();
			state_push('video');
		}
		elsif ($input[$linenumber] =~/<image>/){
			close_paratable();
			state_push('image');
		}
		elsif ($input[$linenumber] =~/<cover>/){
			state_push('cover');
		}
		elsif ($input[$linenumber] =~/<headerlink>/){
			state_push('headerlink');
		}
		elsif ($input[$linenumber] =~/<set>/){
			state_push('set');
		}
		elsif ($input[$linenumber] =~/<heading>/){
			$variables{'notes'}=$variables{'notes'}&2;
			close_paratable();
			state_push('heading');
		}
		elsif ($input[$linenumber] =~/<table>/){
			$inline=1;
			$variables{'notes'}=$variables{'notes'}&2;
			close_paratable();
			table_lookahead($linenumber);
			$tablerow=0;
			$tablecol=0;
			state_push('table');
		}
		elsif ($input[$linenumber] =~/<([acdhlmnopritu]*)list>/){
			$type='';
			if ($1 ne ''){
				$type=$1;
			}
			$listlevel=1; # Should always have been 0 because we're in state in3xml.
			undef @listtype;
			$listtype[0]='none';
			$variables{'notes'}=$variables{'notes'}&2;
			close_paratable();
			# find the type at this level
			$listlevel=1;
			my $typelevel=$listlevel;
			my $i=$linenumber+1;
			my $intype=0;
			$listtype[$listlevel]='none';
			while (($listtype[$listlevel] eq 'none') && ($i<=$#input) && ($typelevel>=$listlevel)){
				if ($input[$i]=~/<[acdhlmnopritu]*list>/){
					$typelevel++;
				}
				elsif ($input[$i]=~/<\/[acdhlmnopritu]*list>/){
					$typelevel--;
				}
				elsif ($input[$i]=~/<type>/){
					$intype=1;
				}
				elsif ($input[$i]=~/<\/type>/){
					$intype=0;
				}
				elsif ($intype>0){
					if ($typelevel==$listlevel){
						chomp $input[$i];
						$listtype[$listlevel]=$input[$i];
						debug("List-type assignment: listtype[$listlevel]=$input[$i]");
					}
				}
				$i++;
			}
			
			if ($listtype[$listlevel]=~/dash/){ output ('.DL');}
			elsif ($listtype[$listlevel]=~/num/){ output ('.AL 1');}
			elsif ($listtype[$listlevel]=~/alpha/){ output ('.AL a');}
			else { output ('.DL');}
			$inline=1;
			state_push('list');
		}
		elsif ($input[$linenumber] =~/<include>/){
			state_push('include');
		}
		elsif ($input[$linenumber] =~/<lst>/){
			close_paratable();
			output ('.P');
			state_push('lst');
		}
		elsif ($input[$linenumber] =~/<paragraph>/){
			my @paratext;
			undef @sidenotes;
			undef @leftnotes;
			undef @paratext;
			my $inside=0;
			my $inleft=0;
			my $intext=0;
			my $prevnotes=$variables{'notes'};
			$inline=1;
			my $endpara=$linenumber;
			# Collect all side and left notes
			while (($endpara<=$#input) && !($input[$endpara] =~/<\/paragraph>/)){
				if ($intext>0){
					if ($input[$endpara] =~/<\/text>/){
						$intext=0;
					}
					else {
						push @paratext,$input[$endpara];
					}
				}
				elsif ($inside>0){
					if ($input[$endpara] =~/<\/side[note]*>/){
						$inside=0;
					}
					else {
						push @sidenotes,$input[$endpara];
					}
				}
				elsif ($inleft>0){
					if ($input[$endpara] =~/<\/leftnote>/){
						$inleft=0;
					}
					else {
						chomp $input[$endpara];
						push @leftnotes,$input[$endpara];
					}
				}
				elsif ($input[$endpara] =~/<leftnote>/){
					$variables{'notes'}=$variables{'notes'}|1;
					$inleft=1;
				}
				elsif ($input[$endpara] =~/<side[note]*>/){
					$variables{'notes'}=$variables{'notes'}|2;
					$inside=1;
				}
				elsif ($input[$endpara] =~/<text>/){
					$intext=1;
				}
				$endpara++;
			}
			if ($prevnotes != $variables{'notes'}){
				close_paratable
			}
			if ($variables{'notes'}==0){
				output ('.P');
			}
			elsif ($ptableopen==0){    
				output ('.TS');
				output ('tab(@);');
				if ($variables{'notes'}==1) { output ('lw(2c) lw(12.5c).');}
				if ($variables{'notes'}==2) { output ('lw(12.8c) lp6w(2c).');}
				if ($variables{'notes'}==3) { output ('lw(2c) lw(10.2c) lp6w(2c).');}
				output ('T{');
				if (($variables{'notes'}&1)>0){
					for (@leftnotes){ output ($_);}
					output ('T}@T{');
					undef @leftnotes;
				}
				$ptableopen=1;
			}
			elsif ($variables{'notes'}>0){
				output ('T{');
				if (($variables{'notes'}&1)>0){
					for (@leftnotes){ output ($_);}
					output ('T}@T{');
					undef @leftnotes;
				}
			}		# The output document is now always in the correct state to
					# process the text part of the paragraph.
			$pcellopen=1;
			state_push('paragraph');
		}
		elsif ($input[$linenumber] =~/<block>/){	# note: these are stand alone blocks
			close_paratable();
			$type='pre';
			$image='';
			$class='';
			undef@blocktext;
			state_push('block');
		}
		elsif($input[$linenumber] =~/^$/){}
		else {
			error ("in3xml: Plain text outside constructs in $linenumber: $input[$linenumber]");
		}
	}
	elsif ($state  eq 'list'){
		if ($input[$linenumber] =~/<\/[dashnumotlpr]*list>/){
			if ($listtype[$listlevel] eq 'dash'){ output ('.LE 1');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('.LE 1');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('.LE 1');}
			else { output ('.LE 1');}
			$listlevel--;
			if ($listlevel==0){ $inline=0;}
			state_pop;
		}
		elsif($input[$linenumber] =~/<list>/){
			$listlevel++;
			# find the type at this level
			my $typelevel=$listlevel;
			my $i=$linenumber+1;
			my $intype=0;
			$listtype[$listlevel]='none';
			while (($listtype[$listlevel] eq 'none') && ($i<=$#input) && ($typelevel>=$listlevel)){
				if ($input[$i]=~/<[acdhlmnopritu]*list>/){
					$typelevel++;
				}
				elsif ($input[$i]=~/<\/[acdhlmnopritu]*list>/){
					$typelevel--;
				}
				elsif ($input[$i]=~/<type>/){
					$intype=1;
				}
				elsif ($input[$i]=~/<\/type>/){
					$intype=0;
				}
				elsif ($intype>0){
					if ($typelevel==$listlevel){
						chomp $input[$i];
						$listtype[$listlevel]=$input[$i];
						debug("List-type assignment: listtype[$listlevel]=$input[$i]");
					}
				}
				$i++;
			}
			if ($listtype[$listlevel]=~/dash/){ output ('.DL');}
			elsif ($listtype[$listlevel]=~/num/){ output ('.AL 1');}
			elsif ($listtype[$listlevel]=~/alpha/){ output ('.AL a');}
			else { output ('.DL');}
			state_push('list');
		}
		elsif($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif($input[$linenumber] =~/<item>/){
			output ('.LI');
			$inline=1;
			state_push('item');
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'item'){
		$inline=1;
		if ($input[$linenumber] =~/<\/item>/){
			state_pop;
		}
		else {
			$inline=1;
			formatrequest();
		}
	}
	elsif ($state  eq 'block'){
		if ($input[$linenumber] =~/<\/block>/){
			if ($name eq ''){ $name="no_name.".int(rand(9999)); }
			my $blk="block/$name";
			if ($type eq 'pre'){
				close_paratable();
				output ('.ne 4v','.sp 1','.B1','.ft 6','.ps -2','.nf','.eo');
				for (@blocktext){
					s/^"//;
					s/"$//;
					output('.br',$_);
				}
				output ('.sp 1',,'.ps','.ft','.ec','.fi','.B2');
			}
			elsif ($type eq 'lst'){
				close_paratable();
				output ('.ne 4v','.sp 1','.ft 6','.ps -2','.nf','.eo');
				for (@blocktext){
					s/^"//;
					s/"$//;
					output('.br',$_);
				}
				output ('.sp 1',,'.ps','.ft','.ec','.fi');
			}
			elsif ($type eq 'pic'){
				if ($inline==0){
					output ('.PS');
					for (@blocktext){
						s/^"//;
						s/"$//;
						output($_);
					}
					output ('.PE');
				}
				else { # This is a hack because pic does not provide in-line images.
					my $mscale=100;
					if ($format=~/scale=([0-9]+)/){
						$mscale=$1;
						$format=~s/scale=[0-9]+//;
					}
					$mscale=$mscale;   # CHECK  for inline scale!
					if ($image eq ''){
						my $density=1000;
						if (open my $PIC, '>',"$blk.pic"){
							print $PIC ".PS\n";
							for (@blocktext){
								if (/^".*"$/){
									s/^"//;
									s/"$//;
								}
								print $PIC "$_\n";
							}
							print $PIC ".PE\n";
							close $PIC;
							system ("pic $blk.pic > $blk.groff");
							system ("groff $blk.groff > $blk.ps");
							system ("eps2eps -B1  $blk.ps $blk.eps");
							outimage("$blk.eps", $format." scale=$mscale ");
						}
						else {
							error ("Cannot open $blk.pic"); 
						}
					}
					else {
						outimage("$image", $format." scale=$mscale ");
						$format='';
						$image='';
					}
					undef @blocktext;
				}
			}
			elsif ($type eq 'eqn'){
				if ($inline == 0){ output ('.ce 1');}
				output ('.EQ');
				for (@blocktext){
					s/^"//;
					s/"$//;
					output($_);
				}
				output ('.EN');
			}
			elsif ($type eq 'gnuplot'){
				my $mscale=100;
				if ($format=~/scale=([0-9]+)/){
					$mscale=$1;
					$format=~s/scale=[0-9]+//;
				}
				$mscale=$mscale;   # CHECK  for inline scale!
				my $density=1000;
				if (open my $PLOT, '>',"$blk.gnuplot"){
					print $PLOT 'set terminal postscript eps';
					print $PLOT "\nset output '$blk.eps'\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
						}
						print $PLOT "$_\n";
					}
					close $PLOT;
					system("gnuplot $blk.gnuplot");
					#system ("eps2eps -B1  $blk.ps $blk.eps");
					outimage("$blk.eps", $format." scale=$mscale ");
				}
				else {
					error ("Cannot open $blk.gnuplot"); 
				}
			}
			elsif ($type eq 'music'){
					my $mscale=100;
					if ($format=~/scale=([0-9]+)/){
						$mscale=$1;
						$format=~s/scale=[0-9]+//;
					}
					$mscale=$mscale/2;
					system ("rm $blk.*");
					if (open (my $MUSIC, '>',"$blk.ly")){
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
						for (@blocktext){
							chomp;
							if (/^".*"$/){
								s/^"//;
								s/"$//;
							}
							print $MUSIC "$_\n";
						}
						print $MUSIC "}\n";
						close $MUSIC;
						system ("cd block; lilypond -dbackend=eps  -dresolution=500 -dpreview ../$blk.ly");
						system ("sed -i 's/\(%%BeginProcSet: .*\)/\1 0 0/' $blk.eps");
						system ("sed -i 's/%%IncludeResource: ProcSet (FontSetInit)/%%IncludeResource: ProcSet (FontSetInit) 0 0/' $blk.eps");


						outimage("$blk.eps", $format." scale=$mscale ");
					}
					else {
						error("Cannot open $blk");
					}
					$format='';
					$image='';
					undef @blocktext;
			
			}
			elsif ($type=~/texeqn/){
				my $mscale=100;
				if ($format=~/scale=([0-9]+)/){
					$mscale=$1;
					$format=~s/scale=[0-9]+//;
				}
				system ("rm $blk.*");
				if (open (my $TEXEQN, '>',"$blk.tex")){
					print $TEXEQN "\\documentclass{article}\n";
					print $TEXEQN "\\usepackage{amsmath}\n";
					print $TEXEQN "\\usepackage{amssymb}\n";
					print $TEXEQN "\\usepackage{algorithm2e}\n";
					print $TEXEQN "\\begin{document}\n";
					print $TEXEQN "\\begin{titlepage}\n";
					print $TEXEQN "\\begin{equation*}\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
						}
						print $TEXEQN "$_\n";
					}
					print $TEXEQN "\\end{equation*}\n";
					print $TEXEQN "\\end{titlepage}\n";
					print $TEXEQN "\\end{document}\n";
					close $TEXEQN;
					system("cd block; echo '' |latex ../$blk.tex -output-directory=block -aux-directory=block > /dev/null 2>/dev/null");
					#system("convert  -trim  -density 500  $blk.dvi  $blk.eps");
					system("dvips -E -o $blk.eps $blk.dvi");
					outimage("$blk.eps", $format." scale=$mscale ");
				}
				$format='';
				$image='';
				undef @blocktext;
			}


			elsif ($type=~/^class(.*)/){ ######################LATER!
				$class=$1;
				output ("<div class=\"$class\">");
				for (@blocktext){
					s/^"//;
					s/"$//;
					output($_);
				}
				output ('</div>');
			}
			else {
				if ($image ne '' ){
					outimage($image);
					$image='';
				}
				else { error ("Block type $type without image"); }
			}
			$class='';
			$type='';
			$name='';
			$image='';
			$format='';
			undef @blocktext;
			state_pop();
		} #end state block: end of block
		elsif ($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif ($input[$linenumber] =~/<image>/){
			state_push('image');
		}
		elsif ($input[$linenumber] =~/<name>/){
			state_push('name');
		}
		elsif ($input[$linenumber] =~/<text>/){
			state_push('blocktext');
		}
	} #end state block
	elsif ($state  eq 'cell'){
		$inline=1;
		if ($input[$linenumber] =~/<\/cell>/){
			$tablecol++;
			state_pop();
		}
		else {
			formatrequest();
		}
	}
	elsif ($state  eq 'row'){
		if ($input[$linenumber] =~/<\/row>/){
			output ('T}');
			$tablerow++;
			state_pop();
		}
		elsif ($input[$linenumber] =~/<cell/){
			if ($tablecol==0){
				output ('T{');
			}
			else {
				output ('T}	T{');
			}
			if ($thistable[$tablerow][$tablecol]=~/rowspan/){
				output 'span';
				output ('T}	T{');
			}
			state_push('cell');
		}
		else { error ("Table row: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'table'){
		if ($input[$linenumber] =~/<\/table>/){
			output ('.TE');
			output ('.sp 1');
			undef @thistable;
			state_pop();
		}
		elsif ($input[$linenumber] =~/<row>/){
			$tablecol=0;
			state_push('row');
		}
		else { error ("Table: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'paragraph'){
		if ($input[$linenumber] =~/<\/paragraph>/){
			$inline=0;
			if ($variables{'notes'}==0){
				output ('.P');
			}
			elsif (($pcellopen>0) && ($variables{'notes'}==1)){
				output ('T}');
			}
			elsif($pcellopen>0) {
				output ('T}@T{');
				if (($variables{'notes'}&2)>0){
					for (@sidenotes){ output ($_); }
					output ('T}');
				}
			}		# Table is always closed at the end.
			else {
				print STDERR "Already closed paragraph\n";
			}
			$pcellopen=0;
			state_pop();
		}
		elsif($input[$linenumber] =~/<leftnote>/){
			state_push('leftnote');
		}
		elsif ($input[$linenumber] =~/<side[note]*>/){
			state_push('side');
		}
		elsif ($input[$linenumber] =~/<text>/){}	# ignore the <text> tags for the moment
		elsif ($input[$linenumber] =~/<\/text>/){}	# this is not correct.
		else {
			formatrequest();
		}
	}
	elsif ($state  eq 'italic'){
		if ($input[$linenumber] =~/<\/italic>/){
			state_pop();
		}
		else {
			output (".I \"$input[$linenumber]\"");
		}
	}
	elsif ($state  eq 'bold'){
		if ($input[$linenumber] =~/<\/bold>/){
			state_pop();
		}
		else {
			output (".B \"$input[$linenumber]\"");
		}
	}
	elsif ($state  eq 'center'){
		if ($input[$linenumber] =~/<\/center>/){
			state_pop();
		}
		else {
			output (".ce 1");
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'fixed'){
		if ($input[$linenumber] =~/<\/fixed>/){
			state_pop();
		}
		else {
			output ('.ft 6','.ps -2',$input[$linenumber],'.ps','.ft');
		}
	}
	elsif ($state  eq 'underline'){
		if ($input[$linenumber] =~/<\/underline>/){
			state_pop();
		}
		else {
			output (".underline \"$input[$linenumber]\"");
		}
	}
	elsif ($state  eq 'lst'){
		if ($input[$linenumber] =~/<\/lst>/){
			output ('.br');
			state_pop();
		}
		else {
			$input[$linenumber] =~s/^"//g;
			$input[$linenumber] =~s/"$//g;
			output ('.br','.ft 6','.ps -2',$input[$linenumber],'.ps','.ft');
		}
	}
	elsif ($state  eq 'side'){
		if ($input[$linenumber] =~/<\/side[note]*>/){
			state_pop();
		}
	}
	elsif ($state  eq 'leftnote'){
		if ($input[$linenumber] =~/<\/leftnote>/){
			state_pop();
		}
	}
	elsif ($state  eq 'heading'){
		if ($input[$linenumber] =~/<\/heading>/){
			if ($level==0){$level=1;}
			my $v=3*$level;
			output (".ne $v".'v');
			output (".H $level \"$text\"");
			$level=0;
			$seq='';
			$text='';
			state_pop();
		}
		elsif ($input[$linenumber] =~/<level>/){
			state_push('level');
		}
		elsif ($input[$linenumber] =~/<seq>/){
			state_push('seq');
		}
		elsif ($input[$linenumber] =~/<text>/){
			state_push('text');
		}
		else {
			error ("heading Header accepts level, seq, or text: $input[$linenumber]");
		}
	}
	elsif ($state  eq 'blocktext'){
		if ($input[$linenumber] =~/<\/text>/){
			state_pop();
		}
		else {
			push @blocktext,$input[$linenumber];
		}
	}
	elsif ($state  eq 'video'){

		if ($input[$linenumber] =~/<\/video>/){
			print STDERR  ("OUTPUT A VIDEO\n");
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}
				my $imgfile=basename($file);
				my $epsfile=basename($file);
				$epsfile=~s/\.[^.]*$/.eps/;
				$imgfile=~s/\.\w+$/.jpg/;
				system("rm -f 'pdf/$imgfile'");
				system("ffmpeg -ss 00:00:05 -i '$file' -vframes 1 -q:v 2 'pdf/$imgfile' 2>/dev/null");
				outimage("pdf/$imgfile",'');
			}
			$file='';
			$text='';
			state_pop();
		}
		elsif ($input[$linenumber]=~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber]=~/<file>/){
			state_push('file');
		}
		else {
			error ("Video: text out of block");
		}
	}
	elsif ($state  eq 'image'){
		if ($input[$linenumber] =~/<\/image>/){
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}
				outimage($file);
				$text='';
				$file='';
				$image='';
			}
			state_pop();
		}
		elsif ($input[$linenumber]=~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber]=~/<file>/){
			state_push('file');
		}
		else {
			$image=$input[$linenumber];
		}
	}
	elsif ($state  eq 'type'){
		if ($input[$linenumber] =~/<\/type>/){
			state_pop();
		}
		else {
			$type=$input[$linenumber];
			chomp $type;
			$type=~s/^[ 	]*"//;
			$type=~s/"$//;
		}
	}
	elsif ($state  eq 'target'){
		if ($input[$linenumber] =~/<\/target>/){
			state_pop();
		}
		else {
			$target=$input[$linenumber];
		}
	}
	elsif ($state  eq 'name'){
		if ($input[$linenumber] =~/<\/name>/){
			$name=~s/^"//;
			$name=~s/"$//;
			state_pop();
		}
		else {
			$name=$input[$linenumber];
		}
	}
	elsif ($state  eq 'text'){
		if ($input[$linenumber] =~/<\/text>/){
			$text=~s/^"//;
			$text=~s/"$//;
			state_pop();
		}
		else {
			$text=$input[$linenumber];
		}
	}
	elsif ($state  eq 'seq'){
		if ($input[$linenumber] =~/<\/seq>/){
			$seq=~s/^"//;
			$seq=~s/"$//;
			state_pop();
		}
		else {
			$seq=$input[$linenumber];
		}
	}
	elsif ($state  eq 'level'){
		if ($input[$linenumber] =~/<\/level>/){
			$level=~s/^"//;
			$level=~s/"$//;
			state_pop();
		}
		else {
			$level=$input[$linenumber];
		}
	}
	elsif ($state  eq 'title'){
		if ($input[$linenumber] =~/<\/title>/){
			state_pop();
		}
		else {
			$variables{'title'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'subtitle'){
		if ($input[$linenumber] =~/<\/subtitle>/){
			state_pop();
		}
		else {
			$variables{'subtitle'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'author'){
		if ($input[$linenumber] =~/<\/author>/){
			state_pop();
		}
		else {
			$variables{'author'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'cover'){
		if ($input[$linenumber] =~/<\/cover>/){
			state_pop();
		}
		else {
			$variables{'cover'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'headerlink'){
		if ($input[$linenumber] =~/<\/headerlink>/){
			state_pop();
		}
		else {
			# Header links are for the header only; they are ignored in normal text
		}
	}
	elsif ($state  eq 'link'){
		if ($input[$linenumber] =~/<\/link>/){
			if ($target ne ''){
				output ('.ft 6','.ps -2',"[$target]",'.ps','.ft');
				if ($text ne ''){
					output ("($text)");
				}
			}
			else {
				error ("Link without a target");
			}
			$target='';
			$text='';
			state_pop();
		}
		elsif ($input[$linenumber] =~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber] =~/<target>/){
			state_push('target');
		}
		else {
			error("link: text outside text/target");
		}
	}
	elsif ($state  eq 'set'){
		if ($input[$linenumber] =~/<\/set>/){
			if ($varname ne ''){
				$variables{$varname}=$value;
				$value='';
				$varname='';
			}
			state_pop();
		}
		elsif ($input[$linenumber] =~/<variable>/){
			state_push('set_var');
		}
		elsif ($input[$linenumber] =~/<value>/){
			state_push('value');
		}
		else {
			error("set: set can only have variable or value");
		}
	}
	elsif ($state  eq 'set_var'){
		if ($input[$linenumber] =~/<\/variable>/){
			state_pop();
		}
		else {
			$varname=$input[$linenumber];
		}
	}
	elsif ($state  eq 'value'){
		if ($input[$linenumber] =~/<\/value>/){
			state_pop();
		}
		else {
			$value=$input[$linenumber];
		}
	}
	elsif ($state  eq 'file'){
		if ($input[$linenumber] =~/<\/file>/){
			$file=~s/^"//;
			$file=~s/"$//;
			state_pop();
		}
		else {
			$file=$input[$linenumber];
		}
	}
	elsif ($state  eq 'include'){
		if ($input[$linenumber] =~/<\/include>/){
			if ($file ne ''){
				if (open (my $FILE,'<',$file)){
					while (<$FILE>){
						chomp;
						output ($_);
					}
					close $FILE;
				}
				else {error("Cannot open $file for include");}
			}
			state_pop;
		}
		elsif ($input[$linenumber] =~/<file>/){
			state_push('file');
		}
	}
	$state=state_tos();
	$linenumber++;
}

close_paratable();

if ($trace > 0){
	for my $k (keys %variables){
		print "# Variable $k = $variables{$k}\n";
	}
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
	while (<$CHARMAP>){
		if (/^\#/){ #comment line
		}
		else {
			push @charmap,$_
		}
	}
	close $CHARMAP;
}
else { print STDERR "in3tbl Cannot open in3charmap\n"; }


for (@charmap){
	chomp;
	my $char;
	my $groff;
	my $html;
	($char,$groff,$html)=split '	';
	$char='UNDEFINED_CHAR' unless defined $char;
	$groff=$char unless defined $groff;
	$html=$char unless defined $html;
	for my $i (0..$#output){
		if ($output[$i]=~/$char/){
			$output[$i]=~s/$char/$groff/g;
		}
	}
}

if ( -f "stylesheet.mm" ) {
	if (open(my $STYLE,'<',"stylesheet.mm")){
		while (<$STYLE>){ print;}
		close $STYLE;
	}
	else {
		print STDERR "Cannot read stylesheet.mm\n";
	}
}

for (@output){print "$_\n";}
