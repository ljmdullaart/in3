#!/usr/bin/perl
#INSTALL@ /usr/local/bin/xml3html
use strict;


my $trace=0;
my @output;
sub output{
	for (@_){
		push @output, $_;
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


sub debug {
	for (@_){
		print STDERR "debug: $_\n";
	}
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
    $variables{'debug'}=0;
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
	$variables{'mapnumber'}=1;

my @input;
my @infile;

# Variables that are picked-up in sub-states and used when higher states close
my $varname='';
my $value='';
my $text='';			
my $class='';
my $target='';
my $coord='';
my $image;
my $file='';
my $level=0;
my $seq='';

# Control variables
my @listtype;
my @listblock;
my @mapfields;
push @listtype,'none';
my $listlevel=0;
my $ptableopen=0;		# Paragraph table is open. This allows using the same table
						# for different paragraphs
my $inline=0;
my @sidenotes;
my @leftnotes;
my @blocktext='';
my $progressindicator=0;
my $fileline=0;
my $video;
my $type;
my $name;

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
					push @infile,"$file.$fileline";
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
		push @infile,"STDIN.$fileline";
	}
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
		output('<u>');
		state_push('underline');
	}
	elsif ($input[$linenumber] =~/<italic>/){
		output('<i>');
		state_push('italic');
	}
	elsif ($input[$linenumber] =~/<bold>/){
		output('<b>');
		state_push('bold');
	}
	elsif ($input[$linenumber] =~/<center>/){
		output('<div style="text-align: center;">');
		state_push('center');
	}
	elsif ($input[$linenumber] =~/<lst>/){
		state_push('lst');
	}
	elsif ($input[$linenumber] =~/<fixed>/){
		output('<tt>');
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
	(my $img)=@_;
	chomp $img;
	$img=~s/ *$//;
	my $imgsize=` imageinfo --geom $img`;
	chomp $imgsize;
	my $scale=100; #percent
	my $x; my $y;
	($x, $y)=split ('x',$imgsize);
	if ($x>$variables{'imagex'}){
		if ($scale > (100*$variables{'imagex'})/$x){ $scale=(100*$variables{'imagex'})/$x;}
	}
	if ($y>$variables{'imagey'}){
		if ($scale > (100*$variables{'imagey'})/$x){ $scale=(100*$variables{'imagey'})/$y;}
	}
	my $align='';
	if ($inline>0){$scale=12;}
	my $width=($x*$scale)/100;
	my $height=($y*$scale)/100;
	if ($inline>0){
		output ("<img src=\"$img\" alt=\"$img\" width=\"$width\" height=\"$height\" style=\"vertical-align:middle\"");
	}
	else {
		output ('<div style="text-align: center">');
		output ("<img src=\"$img\" alt=\"$img\" width=\"$width\" height=\"$height\" align='center'>");
		output ('</div>');
	}

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
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			state_push('video');
		}
		elsif ($input[$linenumber] =~/<map>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			$file='';
			undef @mapfields;
			state_push('map');
		}
		elsif ($input[$linenumber] =~/<image>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
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
			if ($ptableopen>0){ output ('</table>'); $ptableopen=0; }
			state_push('heading');
		}
		elsif ($input[$linenumber] =~/<table>/){
			$inline=1;
			$variables{'notes'}=$variables{'notes'}&2;
			if ($ptableopen>0){ output ('</table>'); $ptableopen=0; }
			output ('<table class=table>');
			state_push('table');
		}
		elsif ($input[$linenumber] =~/<([acdhlmnopstu]*)list>/){
			$type='';
			if ($1 ne ''){
				$type=$1;
			}
			$listlevel=1; # Should always have been 0 because we're in state in3xml.
			undef @listtype;
			$listtype[0]='none';
			$variables{'notes'}=$variables{'notes'}&2;
			if ($ptableopen>0){ output ('</table>'); $ptableopen=0; }
			# Look ahead to fill the list-types
			my $i=$linenumber;
			$listlevel=1; # Should always have been 0 because we're in state in3xml.
			if ($type ne ''){ $listtype[1]=$type; }
			my $intype=0;
			while ($listlevel>0){
				chomp $input[$i];
				$i++;
				if ($input[$i]=~/<\/list>/){
					$listlevel--;
				}
				elsif ($input[$i]=~/<([acdhlmnopstu]*)list>/){
					$listlevel++;
					if ($1 ne ''){$listtype[$listlevel]=$1; }
				}
				elsif($input[$i]=~/<type>/){
					$intype=1;
				}
				elsif($input[$i]=~/<\/type>/){
					$intype=0;
				}
				elsif ($intype>0){
					if ($input[$i]=~/(dash|dot|alpha|num|roman)/){
						$listtype[$listlevel]=$input[$i];
						chomp $listtype[$listlevel];
						$listtype[$listlevel]=~s/"//g;
					}
				}
				if ($i>$#input){$listlevel=0;} # For unclosed lists
			} # end listlevel array fill
			$listlevel=1;
			if ($listtype[$listlevel] eq 'dash'){ output ('<ul>');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('<ol type=1>');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('<ol type=a>');}
			elsif ($listtype[$listlevel] eq 'none'){ output ('<EMPTY>');}
			$inline=1;
			state_push('list');
		}
		elsif ($input[$linenumber] =~/<include>/){
			state_push('include');
		}
		elsif ($input[$linenumber] =~/<lst>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			output ('<br>');
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
			$inline=1;
			my $endpara=$linenumber;
			# Collect all side notes
			while (($endpara<=$#input) && !($input[$endpara] =~/<\/paragraph>/)){
				if ($intext>0){
					if ($input[$endpara] =~/<\/text>/){
						$intext=0;
					}
					else {
						push @paratext,$input[$endpara];
					}
				}
				if ($inside>0){
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
			if ($variables{'notes'}==0){
				output ('<p>');
			}
			elsif ($ptableopen==0){
				output('<table class=paragraph>');
				$ptableopen=1;
			}
			if ($variables{'notes'}>0){
				output ('<tr>');
			}
			if (($variables{'notes'}&1)>0){
				output ('<td class=leftnote>');
				for (@leftnotes){ output ($_);}
				output ('</td>');
				undef @leftnotes;
			}
			if ($variables{'notes'}>0){
				output ('<td class=paragraph>');
			}
			state_push('paragraph');
		}
		elsif ($input[$linenumber] =~/<block>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
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
			if ($listtype[$listlevel] eq 'dash'){ output ('</ul>');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('</ol>');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('</ol>');}
			elsif ($listtype[$listlevel] eq 'none'){ output ('<EMPTY>');}
			$listlevel--;
			if ($listlevel==0){ $inline=0;}
			state_pop;
		}
		elsif($input[$linenumber] =~/<list>/){
			$listlevel++;
			if ($listtype[$listlevel] eq 'dash'){ output ('<ul>');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('<ol type=1>');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('<ol type=a>');}
			elsif ($listtype[$listlevel] eq 'none'){ output ('<EMPTY>');}
			state_push('list');
		}
		elsif($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif($input[$linenumber] =~/<item>/){
			output ('<li>');
			output ('<div class=list>');
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
			output ('</div>');
			output ('</li>');
			state_pop;
		}
		else {
			$inline=1;
			formatrequest();
		}
	}
	elsif ($state  eq 'block'){

		if ($input[$linenumber] =~/<\/block>/){
			if ($type eq 'pre'){
				if ($ptableopen>0){ output('</table>');$ptableopen=0;}
				output ('<pre>');
				for (@blocktext){
					s/ /&nbsp;/g;
					s/^"//;
					s/"$//;
					output($_);
				}
				output ('</pre>');
			}
			elsif ($type eq 'lst'){
				if ($ptableopen>0){ output('</table>');$ptableopen=0;}
				for (@blocktext){
					s/ /&nbsp;/g;
					s/	/&nbsp;&nbsp;&nbsp;&nbsp;/g;
					s/^"//;
					s/"$//;
					output("<br><span class=\"lst\">$_</span>");
				}
				output ('</pre>');
			}
			elsif ($type=~/^class(.*)/){
				$class=$1;
				output ("<div class=\"$class\">");
				for (@blocktext){
					s/^"//;
					s/"$//;
					output($_);
				}
				output ('</div>');
			}
			elsif ($type=~/gnuplot(.*)/){
				my $mscale=100;
				#if ($format=~/scale=([0-9]+)/){
				#	$mscale=$1;
				#	$format=~s/scale=[0-9]+//;
				#}
				$mscale=$mscale;   # CHECK  for inline scale!
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open my $PLOT, '>',"$blk.gnuplot"){
					print $PLOT "set terminal svg size $x,$y enhanced font \"Helvetica,16\"\n";
					print $PLOT "set output '$blk.svg'\n";
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
					output("<img src=\"$blk.svg\"  width=\"$x\">");
				}
				else {
					error ("Cannot open $blk.gnuplot"); 
				}
			}
			elsif ($type=~/texeqn/){
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open (my $TEXEQN,'>',"$blk.tex")){
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
            		system("cd block; echo '' | latex ../$blk.tex > /dev/null 2>/dev/null");
					#system("convert  -trim  -density $density  $blk.dvi  $blk.png");
            		system("dvisvgm -n -c1.5  $blk.dvi -o $blk.svg");
					output("<img src=\"$blk.svg\" alt=\"$blk\">");
				}
				else {
					print STDERR "in3html cannot open $blk\n";
				}
			}
			elsif ($type=~/eqn/){	# must be after the texeqn obviously
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open (my $EQN,'>',"$blk.eqn")){
					print $EQN ".EQ\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
						}
						print $EQN "$_\n";
					}
					print $EQN ".EN\n";
					close $EQN;
					system ("eqn $blk.eqn > $blk.groff");
					system ("groff $blk.groff > $blk.ps");
					system ("ps2pdf $blk.ps  $blk.pdf");
					system ("convert -trim -density $density $blk.pdf  $blk.png");
					my $imgsize=` imageinfo --geom $blk.png`;
					my $x; my $y; my $yn;
					($x,$y)=split ('x',$imgsize);
					$yn=$y*$mscale/10000;
					my $ysize=$yn.'em';
					output("<img src=\"$blk.png\" alt=\"$blk\" style=\"height:$ysize;vertical-align:middle\">");
				}
				else { error ("Cannot open $blk.eqn");}
			}
			elsif ($type=~/pic/){
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open (my $PIC,'>',"$blk.pic")){
					print $PIC ".PS\n";
					for (@blocktext){
						chomp;
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
					system ("ps2pdf $blk.ps  $blk.pdf");
					system ("convert -trim -density $density $blk.pdf  $blk.png");
					my $imgsize=` imageinfo --geom $blk.png`;
					my $x; my $y; my $yn;
					($x,$y)=split ('x',$imgsize);
					$yn=$y*$mscale/10000;
					my $ysize=$yn.'em';
					output("<img src=\"$blk.png\" alt=\"$blk\" style=\"height:$ysize;vertical-align:middle\">");
				}
				else { error ("Cannot open $blk.pic");}
			}
			elsif ($type=~/music/){
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open (my $MUSIC,'>',"$blk.music")){
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
					system ("cd block; lilypond --png  -dresolution=500  ../$blk.music");
					system ("mv $blk.png $blk.fs.png");
					system ("convert -trim $blk.fs.png $blk.png");

					my $imgsize=` imageinfo --geom $blk.png`;
					my $x; my $y; my $yn;
					($x,$y)=split ('x',$imgsize);
					$yn=$y*$mscale/10000;
					my $ysize=$yn.'em';
					output("<img src=\"$blk.png\" alt=\"$blk\" style=\"height:$ysize;vertical-align:middle\">");
				}
				else { error ("Cannot open $blk.pic");}
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
			$image='';
			undef @blocktext;
			state_pop();
		} #end state block: end of block
		elsif ($input[$linenumber] =~/<name>/){
			state_push('name');
		}
		elsif ($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif ($input[$linenumber] =~/<image>/){
			state_push('image');
		}
		elsif ($input[$linenumber] =~/<text>/){
			state_push('blocktext');
		}
	} #end state block
	elsif ($state  eq 'cell'){
		$inline=1;
		if ($input[$linenumber] =~/<\/cell>/){
			$inline=0;
			output ('</div>');
			output ('</td>');
			state_pop();
		}
		else {
			formatrequest();
		}
	}
	elsif ($state  eq 'row'){
		if ($input[$linenumber] =~/<\/row>/){
			output ('</tr>');
			state_pop();
		}
		elsif ($input[$linenumber] =~/<cell/){
			my $rs=0;
			my $cs=0;
			my $tdstr='<td';
			if ($input[$linenumber] =~/cs=([0-9]+)/){$cs=$1;}
			if ($input[$linenumber] =~/colspan=([0-9]+)/){$cs=$1;}
			if ($input[$linenumber] =~/rs=([0-9]+)/){$rs=$1;}
			if ($input[$linenumber] =~/rowspan=([0-9]+)/){$rs=$1;}
			if ($rs>0){ $tdstr="$tdstr rowspan=\"$rs\"";}
			if ($cs>0){ $tdstr="$tdstr colspan=\"$cs\"";}
			$tdstr="$tdstr class=table>";
			output ($tdstr);
			output ('<div class=cel>');
			state_push('cell');
		}
		else { error ("Table row: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'table'){
		if ($input[$linenumber] =~/<\/table>/){
			output ('</table>');
			state_pop();
		}
		elsif ($input[$linenumber] =~/<row>/){
			output ('<tr>');
			state_push('row');
		}
		else { error ("Table: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'paragraph'){
		if ($input[$linenumber] =~/<\/paragraph>/){
			$inline=0;
			if ($variables{'notes'}==0){
				output ('</p>');
			}
			else{
				output ('</td>');
				if (($variables{'notes'}&2)>0){
					output ('<td class=sidenote>');
					for (@sidenotes){ output ($_); }
					output ('</td>');
				}
				output ('</tr>');
			}
			state_pop();
		}
		elsif($input[$linenumber] =~/<leftnote>/){
			state_push('leftnote');
		}
		elsif ($input[$linenumber] =~/<side[note]*>/){
			state_push('side');
		}
		elsif ($input[$linenumber] =~/<text>/){}
		elsif ($input[$linenumber] =~/<\/text>/){}
		else {
			formatrequest();
		}
	}
	elsif ($state  eq 'italic'){
		if ($input[$linenumber] =~/<\/italic>/){
			output ('</i>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'bold'){
		if ($input[$linenumber] =~/<\/bold>/){
			output ('</b>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'center'){
		if ($input[$linenumber] =~/<\/center>/){
			output ('</div>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'fixed'){
		if ($input[$linenumber] =~/<\/fixed>/){
			output ('</tt>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'underline'){
		if ($input[$linenumber] =~/<\/underline>/){
			output ('</u>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'lst'){
		if ($input[$linenumber] =~/<\/lst>/){
			state_pop();
		}
		else {
			$input[$linenumber] =~s/ /&nbsp;/g;
			$input[$linenumber] =~s/	/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$input[$linenumber] =~s/^"//g;
			$input[$linenumber] =~s/"$//g;
			output ('<span class="fixed">',$input[$linenumber],'</span>');
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
			output ("<h$level>");
			if ($seq ne ''){ output($seq);}
			if ($text ne ''){ output($text);}
			output ("</h$level>");
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
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}
				output ('<br>');
				output('<div style="text-align: center;">');
				output ("<video controls>","<source src=\"$file\">",$text,"</video>");
				output ('<br>');
				output ('</div>');
				$text='';
				$file='';
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
			error ("Video: text out of block");
		}
	}
	elsif ($state  eq 'map'){
		if ($input[$linenumber] =~/<\/map>/){
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}

				output ('<div style="text-align: center">');
				output ("<img src=\"$file\" alt=\"$file\" usemap=#map$variables{'mapnumber'}>");
				output ("<map name=map$variables{'mapnumber'}>");
				for (@mapfields){ output ($_);}
				output ('</map>');
				output ('</div>');
				$text='';
				$file='';
				$image='';
			}
			state_pop();
		}
		elsif ($input[$linenumber]=~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber]=~/<field>/){
			state_push('field');
		}
		elsif ($input[$linenumber]=~/<file>/){
			state_push('file');
		}
		else {
			$image=$input[$linenumber];
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
	elsif ($state  eq 'name'){
		if ($input[$linenumber] =~/<\/name>/){
			state_pop();
		}
		else {
			$name=$input[$linenumber];
			$name=~s/^"//;
			$name=~s/"$//;
		}
	}
	elsif ($state  eq 'type'){
		if ($input[$linenumber] =~/<\/type>/){
			state_pop();
		}
		else {
			$type=$input[$linenumber];
			$type=~s/^"//;
			$type=~s/"$//;
		}
	}
	elsif ($state  eq 'field'){
		if ($input[$linenumber] =~/<\/field>/){
			if (($coord ne '') && ($target ne '')){
				push @mapfields,"<area shape=\"rect\" coords=\"$coord\" href=\"$target\">";
			}
			$coord='';
			$target='';
			state_pop();
		}
		elsif ($input[$linenumber] =~/<coord>/){
			state_push('coord');
		}
		elsif ($input[$linenumber] =~/<target>/){
			state_push('target');
		}
		elsif ($input[$linenumber] =~/<file>/){
			state_push('file');
		}
		else { error("Undefined field in field $input[$linenumber]");}
	}
	elsif ($state  eq 'coord'){
		if ($input[$linenumber] =~/<\/coord>/){
			state_pop();
		}
		else {
			$coord=$input[$linenumber];
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
				output ("<a href=\"$target\">");
				if ($text ne ''){
					output ($text);
				}
				else {
					output ($target);
				}
				output ('</a>');
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


if ($trace > 0){
	for my $k (keys %variables){
		print "# Variable $k = $variables{$k}\n";
	}
}
if ($variables{"do_headers"} eq 'yes'){
	print "<!DOCTYPE html>\n";
	print "<html lang=\"en\">\n";
	print "<head>\n";
	print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n";
	print "<title>$variables{'title'}</title>\n";
	if (-f "stylesheet.css"){
		print "<link rel=\"stylesheet\" href=\"stylesheet.css\">\n";
	}
	print "</head>\n";
	print "<body>\n";
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
			$output[$i]=~s/$char/$html/g;
		}
	}
}

for (@output){print "$_\n";}

if ($variables{"do_headers"} eq 'yes'){
	print "</body>\n";
}
