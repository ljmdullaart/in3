#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3
use strict;
use warnings;
use Time::localtime;
use Digest::MD5 qw(md5);

########################################################

#     #     #     ######    #####   
#     #    # #    #     #  #     #  
#     #   #   #   #     #  #        
#     #  #     #  ######    #####   
 #   #   #######  #   #          #  
  # #    #     #  #    #   #     #  
   #     #     #  #     #   ##### 
my %variables=();
$variables{"interpret"}=1;
$variables{"markdown"}=0;
$variables{"inlineemp"}=1;	# Allow inline emphasis _underline_ and *bold*
$variables{"appendix"}=0;	# We're in an appendix
my $tm=localtime;
my $datestring=sprintf("The current date is %04d-%02d-%02d\n", $tm->year+1900, ($tm->mon)+1, $tm->mday);

my @input;			# array containing all input lines
my $leftnote;
my $level;
my $bodytext;
my @reflist;		# all references with .ref
my $blockcount=0;
########################################################

#     #  #######  #        ######   
#     #  #        #        #     #  
#     #  #        #        #     #  
#######  #####    #        ######   
#     #  #        #        #        
#     #  #        #        #        
#     #  #######  #######  #   

sub hellup{
print STDERR '
NAME: 
	in3 : convert in-style text to in3-format
SYNOPSIS:
	in3 [ arguments,...]
DESCRIPTION:
	In3 takes a run-off format following the "in" convention and produces an
	in3-formatted  file. If multiple filenames are present, their content is
	contatenated. If  an input filename starts with a number followed  by an 
	underscore, the number is understood to be the first chapter number.
ARGUMENTS:
	-h,--help: Produces this help and terminates the program
	-c <nr>:   Set the first chapter to be nr
	-i <nr>:   Set interpretation mode to nr
	-d <nr>:   Debugging at level nr; shows some internals
	filename:  take the input from the filename

';
exit 0;
}

########################################################

######   #######  ######   #     #   #####   
#     #  #        #     #  #     #  #     #  
#     #  #        #     #  #     #  #        
#     #  #####    ######   #     #  #  ####  
#     #  #        #     #  #     #  #     #  
#     #  #        #     #  #     #  #     #  
######   #######  ######    #####    ##### 
$variables{"DEBUG"}=0;
#	Debug levels:
my $GENERAL=1;   #	general flow
my $FUNCTIONS=2; #	function called
my $TAGS=4;	     #	tags and escapes
my $SIDENOTE=8;  #	sidenotes
my $LISTS=16;    #	lists
my $TABLE=32;    #	tables
my $MARKDOWN=64; #	Markdown-style formats
my $COPYIN=128;  #	Copy all input lines
my $IN3PUSH=256; #	all pushes to in3
my $DETAILS=512; #	real detailed stuff

sub debug{
	my $level;my $message;
	($level,$message)=@_;
	if ($variables{"DEBUG"} & $level){
		print "{variables{'DEBUG'} $level}$message\n";
	}
}
########################################################
########################################################

   #     ######    #####    #####   
  # #    #     #  #     #  #     #  
 #   #   #     #  #        #        
#     #  ######   #  ####   #####   
#######  #   #    #     #        #  
#     #  #    #   #     #  #     #  
#     #  #     #   #####    #####  

if ($#ARGV<0){
	@input=<>;
}
else {
	my $what='';
	for (@ARGV){
		debug (1, "arg=$_");
		if ($what eq ''){
			if (1==0){}
			elsif (/^--$/){ while (<STDIN>){push @input,$_;}}
			elsif (/^-d([0-9]+)/){ $variables{"DEBUG"}=$1; }
			elsif (/^-d$/){$what='debug';}
			elsif (/^-c([0-9]+)/){ $variables{"H1"}=$1;}
			elsif (/^-c$/){$what='chapter';}
			elsif (/^-i([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^-i$/){$what='interpret';}
			elsif (/^-m/){$variables{"markdown"}=1;}
			elsif (/^-+h/){ hellup; }
			elsif (/^-/){ print STDERR "$_ is not known as a flag; ignored.\n";}
			else {
				my $file=$_;
				my $ch;	# Chapter number from filename
				if ($file=~/^([0-9]+)_/){$ch=$1;} else {$ch=-1;}
				if (open(my $IN,'<',$file)){
					if ($ch>0){
						push @input,".set H1 $ch";
						$variables{"H1"}=$ch;
					}
					while (<$IN>){
						push @input,$_;
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
			if (/([0-9]+)/){ $variables{"H1"}=$1;}
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
}

if (open(my $META, '<', "meta.in")){
	while (<$META>){
		chomp;
		if (/^\.set ([^ ][^ ]*) ([^ ]*)/){
			push @input,".set $1 $2";
		}
	}
	close $META;
}
		
########################################################

#     #  #######  #######  #######   #####   
##    #  #     #     #     #        #     #  
# #   #  #     #     #     #        #        
#  #  #  #     #     #     #####     #####   
#   # #  #     #     #     #              #  
#    ##  #     #     #     #        #     #  
#     #  #######     #     #######   #####  
$variables{'notes'}=0; 
	#	0	no notes
	#	1	left note
	#	2	side note
	#	3	left and side note
my $sidenote='';
my $sidechar='*';
my $sideseparator=';';
########################################################


#######  #     #  #######  ######   #     #  #######  
#     #  #     #     #     #     #  #     #     #     
#     #  #     #     #     #     #  #     #     #     
#     #  #     #     #     ######   #     #     #     
#     #  #     #     #     #        #     #     #     
#     #  #     #     #     #        #     #     #     
#######   #####      #     #         #####      # 
my @in3;

sub inpush{
	(my $line)=@_;
	debug ($IN3PUSH,"PUSH $line");
	if ($line=~/\{([A-Z]*)\}(.*)/){
		my $tag=$1;
		my $txt=$2;
		if (( $variables{"inlineemp"}>0) || ( $variables{"markdown"}>0)){
			debug ($MARKDOWN,"tag=$1 text=$2");
			if (($tag eq 'TEXTNORMAL')||($tag =~/LIST.*ITEM/) ||($tag eq 'TABLECEL')) {
				if ($txt=~/[_\[\*][^_\* ]+[_\]\*]/){
					while ($txt=~/([^_\[\*]*)([_\[\*]+)([^_\]\* ]+)([_\]\*]+)(.*)/){
						my $pre=$1;
						my $empopen=$2;
						my $emptxt=$3;
						my $empclose=$4;
						my $post=$5;
						debug ($MARKDOWN,"-----\npre=$pre\nempopen=$empopen\nemptxt=$emptxt\nempclose=$empclose\npost=$post");
						push @in3,"{$tag}$pre";
						$tag='TEXTNORMAL';
						if (($empopen ne $empclose) && (($empopen ne '[')&&($empclose ne ']'))) {
							push @in3,"{$tag}$empopen$emptxt";
							$txt="$empclose$post";
						}
						else {
							if ($empopen eq '['){
								if ($emptxt=~/^[hf]t+p/){	# We only allow http and ftp links; may be elaborated further later.
									if ($post=~/^\(([^\)]*)\)/){
										debug ($MARKDOWN,"LINK found $1 -> $emptxt");
										push @in3,"{LINK}$emptxt $1";
										$post=~s/^\([^\)]*\)//;
									}
									else {
										debug ($MARKDOWN,"LINK found $emptxt (no description)");
										push @in3,"{LINK}$emptxt";
									}
								}
								else {
									if ($post=~/^\(([^\)]*)\)/){
										debug ($MARKDOWN,"NOT A REAL LINK; pushing [$emptxt $1]");
										push @in3,"{TEXTNORMAL}[$emptxt $1]";
										$post=~s/^\([^\)]*\)//;
									}
									else {
										debug ($MARKDOWN,"NOT A REAL LINK; pushing [$emptxt]");
										push @in3,"{LINK}[$emptxt]";
									}
								}
							}
							elsif ($empopen =~/__*/){
								debug ($MARKDOWN,"UNDERLINE");
								push @in3,"{TEXTUNDERLINE}$emptxt";
							}
							else {
								push @in3,"{TEXTBOLD}$emptxt";
								debug ($MARKDOWN,"BOLD");
							}
							$txt=$post;
						}
							
					}
					if ($txt ne ''){
						push @in3,"{$tag}$txt";
					}
				}
				else {
					push @in3,$line;
				}
			}
			else {
				push @in3,$line;
			}
		}
		else {
			push @in3,$line;
		}
	}
	else {
		push @in3,$line;
	}
}
sub inappend {
	(my $line)=@_;
	$in3[$#in3]=$in3[$#in3].' '.$line;
	debug ($IN3PUSH,"APPEND $#in3 $line -> $in3[$#in3]");
}
########################################################

#        ###   #####   #######   #####   
#         #   #     #     #     #     #  
#         #   #           #     #        
#         #    #####      #      #####   
#         #         #     #           #  
#         #   #     #     #     #     #  
#######  ###   #####      #      #####   
my @thislist;
my $inlist=0;

sub close_list {
	debug($FUNCTIONS,"close_list");
	if ($inlist>0){
		debug($LISTS,"Close list: inlist=1");
		my $listlevel=0;
		my $target=0;
		my @types=(' ',' ',' ',' ');
		for (@thislist){
			debug ($LISTS,"list line: $_");
			# Determine target list-level and the type
			if (0==1){}
			elsif (/^-[ 	]/)		{ $target=1; $types[1]='-';}
			elsif (/^	-[ 	]/)		{ $target=2; $types[2]='-';}
			elsif (/^		-[ 	]/)	{ $target=3; $types[3]='-';}
			elsif (/^\#[ 	]/)		{ $target=1; $types[1]='#';}
			elsif (/^	\#[ 	]/)		{ $target=2; $types[2]='#';}
			elsif (/^		\#[ 	]/)	{ $target=3; $types[3]='#';}
			elsif (/^\@[ 	]/)		{ $target=1; $types[1]='@';}
			elsif (/^	\@[ 	]/)		{ $target=2; $types[2]='@';}
			elsif (/^		\@[ 	]/)	{ $target=3; $types[3]='@';}
			# Start lists until the required level
			while($listlevel<$target){
				debug($LISTS,"increment listlevel $listlevel < target $target");
				$listlevel++;
				if ($types[$listlevel] eq '-'){ inpush("{LISTDASHSTART}$listlevel");}
				elsif ($types[$listlevel] eq '#'){ inpush("{LISTNUMSTART}$listlevel");}
				elsif ($types[$listlevel] eq '@'){ inpush("{LISTALPHASTART}$listlevel");}
			}
			# End lists until target level
			while ($listlevel>$target){
				debug($LISTS,"decrement listlevel $listlevel > target $target");
				if ($types[$listlevel] eq '-'){ inpush("{LISTDASHEND}$listlevel");}
				elsif ($types[$listlevel] eq '#'){ inpush("{LISTNUMEND}$listlevel");}
				elsif ($types[$listlevel] eq '@'){ inpush("{LISTALPHAEND}$listlevel");}
				$listlevel--;
			}
			debug ($LISTS,"list line before push logic: $_");
			if (/^\.i / )                    { s/^\.i *//;       inpush ("{TEXTITALIC}$_"); }
			elsif (/^\.b / )                 { s/^\.b *//;       inpush ("{TEXTBOLD}$_"); }
			elsif (/^\.u / )                 { s/^\.u *//;       inpush ("{TEXTUNDERLINE}$_"); }
			elsif (/^\.fix / )               { s/^\.fix *//;     inpush ("{TEXTFIX}$_"); }
			elsif (/^\.fixed / )             { s/^\.fixed *//;   inpush ("{TEXTFIX}$_"); }
			elsif (/^\.inline / )            { inline($_,'force'); }
			elsif (/^\.img / )               { s/^.img /{IMAGE}/;inpush ($_);}
			elsif (/^\.rimg / )               { s/^.img /{RIMAGE}/;inpush ($_);}
			elsif (!(/^[-#@ 	]/))         {                   inpush ("{TEXTNORMAL}$_"); }
			elsif ($types[$listlevel] eq '-'){s/^[-#@ 	]*//;inpush("{LISTDASHITEM}$_");}
			elsif ($types[$listlevel] eq '#'){s/^[-#@ 	]*//;inpush("{LISTNUMITEM}$_");}
			elsif ($types[$listlevel] eq '@'){s/^[-#@ 	]*//;inpush("{LISTALPHAITEM}$_");}
		}
		$target=0;
		while ($listlevel>$target){
			debug($LISTS,"closing listlevel $listlevel > target $target");
			if ($types[$listlevel] eq '-'){ inpush("{LISTDASHEND}$listlevel");}
				elsif ($types[$listlevel] eq '#'){ inpush("{LISTNUMEND}$listlevel");}
				elsif ($types[$listlevel] eq '@'){ inpush("{LISTALPHAEND}$listlevel");}
			$listlevel--;
		}
		undef @thislist;
		$inlist=0;
	}
}



########################################################

#     #     #     ######   
##   ##    # #    #     #  
# # # #   #   #   #     #  
#  #  #  #     #  ######   
#     #  #######  #        
#     #  #     #  #        
#     #  #     #  #      

my $inmap=0;
my @thismap;
my $mappict='';
my $mapnr=0;

sub close_map {
	if ($inmap>0){
		$mapnr++;
		my $mapname="map$mapnr";
		inpush ("{MAPSTART}");
		inpush ("{MAPPICT}$mappict");
		for (@thismap){
			inpush ("{MAPFIELD}$_");
		}
		inpush ("{MAPEND}");
		$inmap=0;
		undef @thismap;
	}
}

########################################################

#######     #     ######   #        #######  
   #       # #    #     #  #        #        
   #      #   #   #     #  #        #        
   #     #     #  ######   #        #####    
   #     #######  #     #  #        #        
   #     #     #  #     #  #        #        
   #     #     #  ######   #######  #######  

my $intable=0;
my @thistable;

sub close_table{
	my @output_table;
	my @line;
	my $x=0; my $y=0;
	my $maxx=0; my $maxy=0;
	my $head=0;
	debug ($FUNCTIONS,"Close table ($intable)");
	if ($intable>0){
		inpush("{TABLESTART}");
		for (@thistable){
			chomp;
			s/^	//;
			debug ($TABLE,"table-line=$_");
			if (/^\{.*\}$/){$head=1;}
			@line=split('	',$_);
			$x=0;
			for (@line){
				my $txt=$_;
				debug ($TABLE,"table-cell x=$x y=$y --- $txt ");
				if (! defined ($output_table[$x][$y])){$output_table[$x][$y]='';}
				if (/<cs=([0-9]+)>/){
					while ($output_table[$x][$y] =~ /<[HV]SPAN>/){
						$x++;
						if (! defined ($output_table[$x][$y])){$output_table[$x][$y]='';}
					}
					debug ($TABLE,"table-cell past SPAN x=$x y=$y --- $txt ");
					my $span=$1;
					for (my $i=0;$i<$span;$i++){
						$output_table[$x+$i][$y]='<HSPAN>';
					}
					$output_table[$x][$y]=$txt;
					
				}
				if (/<rs=([0-9]+)>/){
					while ($output_table[$x][$y] =~ /<[HV]SPAN>/){
						$x++;
						if (! defined ($output_table[$x][$y])){$output_table[$x][$y]='';}
					}
					debug ($TABLE,"table-cell past SPAN x=$x y=$y --- $txt ");
					my $span=$1;
					for (my $i=0;$i<$span;$i++){
						$output_table[$x][$y+$i]='<VSPAN>';
					}
					$output_table[$x][$y]=$txt;
				}
				if (! defined ($output_table[$x][$y])){$output_table[$x][$y]='';}
				while ($output_table[$x][$y] =~ /<[HV]SPAN>/){
					$x++;
					if (! defined ($output_table[$x][$y])){$output_table[$x][$y]='';}
				}
				$output_table[$x][$y]=$txt;
				$x++; if($x>$maxx){$maxx=$x;}
			}
			$y++;if($y>$maxy){$maxy=$y;}
		}
			
		for ($y=0; $y<$maxy; $y++){
			if (($y==0) && ($head==1)){
				inpush( "{TABLEHEAD}");
			}
			else {
				inpush( "{TABLEROW}");
			}
			for ($x=0; $x<$maxx;$x++){
				if (! defined $output_table[$x][$y]){$output_table[$x][$y]=' ';}
				if ($output_table[$x][$y]=~/^\.inline/){
					inpush("{TABLECEL}");
					inline ($output_table[$x][$y]);
				}
				elsif($output_table[$x][$y]=~/^\.img (.*)/){
					inpush("{TABLECEL}");
					inpush("{IMAGE}$1");
				}
				else {
					inpush("{TABLECEL}$output_table[$x][$y]");
				}
					
			}
			inpush( "{TABLEROWEND}");
		}
		inpush("{TABLEEND}");
	}
	undef @thistable;
	$intable=0;
}

########################################################

# #    # #      # #    # ###### 
# ##   # #      # ##   # #      
# # #  # #      # # #  # #####  
# #  # # #      # #  # # #      
# #   ## #      # #   ## #      
# #    # ###### # #    # ###### 

sub inline {
	(my $inp,my $force)=@_;
	my $ch;
	my $type;
	my $content;
	my $blockname;
	if ($inp=~/^\.inline ([a-z]+) (.*)/){
		my $type=$1;
		my $content=$2;
		if (exists $variables{"H1"} ){
			$ch=$variables{"H1"}
		}
		else {
			$ch=0;
		}
		$blockcount++;
		$blockname="inline.$ch.$blockcount";
		if (($inlist>0) && ($force ne 'force')) {
			push @thislist,"$inp";
		}
		else {
			inpush("{BLOCKSTART}$type $blockname");
			inpush ("{BLOCKFORMAT}inline");
			inpush("{BLOCK $type}$content");
			inpush ("{BLOCKEND}");
		}
	}
	else {
		#silently ignore
	}
}
########################################################

   #     #        ###  #     #  #######     #     
  # #    #         #   ##    #  #          # #    
 #   #   #         #   # #   #  #         #   #   
#     #  #         #   #  #  #  #####    #     #  
#######  #         #   #   # #  #        #######  
#     #  #         #   #    ##  #        #     #  
#     #  #######  ###  #     #  #######  #     #  

my $inalinea=0; 
	# 0	Not in any alinea
	# 1	In the alinea
sub close_alinea{
	debug($FUNCTIONS,"Close alinea (inalinea=$inalinea)");
	close_list;
	close_map;
	close_table;
	if ($inalinea>0){
		if ($variables{'notes'} & 2){
			inpush("{SIDENOTE}$sidenote");
			$sidenote='';
		}
		inpush("{ALINEAEND}");
	}
	$inalinea=0;
}
sub start_alinea{
	if ($inalinea==0){
		inpush("{ALINEA}$variables{'notes'}");
		if ($variables{'notes'}&1){
			inpush("{LEFTNOTE}");
		}
		$inalinea=1;
	}
}
########################################################

######   ######   #######           #######  #     #  #######  
#     #  #     #  #                 #        ##   ##     #     
#     #  #     #  #                 #        # # # #     #     
######   ######   #####    #######  #####    #  #  #     #     
#        #   #    #                 #        #     #     #     
#        #    #   #                 #        #     #     #     
#        #     #  #######           #        #     #     # 

my $inpre=0;
my $inblock=0;
my $blocktype='none';
my $blockname='';

########################################################


 #####   #        #######  ######      #     #         #####   
#     #  #        #     #  #     #    # #    #        #     #  
#        #        #     #  #     #   #   #   #        #        
#  ####  #        #     #  ######   #     #  #         #####   
#     #  #        #     #  #     #  #######  #              #  
#     #  #        #     #  #     #  #     #  #        #     #  
 #####   #######  #######  ######   #     #  #######   #####   


for (@input){
	if (/^\.global ([^ ]*) (.*)/){
		$variables{$1}=$2;
	}
	elsif (/^\.interpret ([0-9)])/){
		$variables{"interpret"}=$1;
	}
}

for (keys %variables){
	inpush("{SET}$_ $variables{$_}");
}

########################################################

 #####   ###  ######   #######  #     #  #######  #######  #######  
#     #   #   #     #  #        ##    #  #     #     #     #        
#         #   #     #  #        # #   #  #     #     #     #        
 #####    #   #     #  #####    #  #  #  #     #     #     #####    
      #   #   #     #  #        #   # #  #     #     #     #        
#     #   #   #     #  #        #    ##  #     #     #     #        
 #####   ###  ######   #######  #     #  #######     #     ####### 
debug($GENERAL,"Test if a sidenote is present somewhere");
for (@input){
		if (/^\.side /){
			debug($SIDENOTE,"Sidenote found");
			$variables{'notes'}=$variables{'notes'} | 2;
		}
}
########################################################

#     #     #     ###  #     #         #        #######  #######  ######   
##   ##    # #     #   ##    #         #        #     #  #     #  #     #  
# # # #   #   #    #   # #   #         #        #     #  #     #  #     #  
#  #  #  #     #   #   #  #  #         #        #     #  #     #  ######   
#     #  #######   #   #   # #         #        #     #  #     #  #        
#     #  #     #   #   #    ##         #        #     #  #     #  #        
#     #  #     #  ###  #     #         #######  #######  #######  #       

debug($GENERAL,"Start the input processing");
for (@input){
	chomp;
	debug (128,"========================================================");
	debug (128, "== $_");
	debug (128,"========================================================");
	
	if (/^\.block/){
		debug ($TAGS,"Block-tag (was: $inblock)");

		if ($inblock==0){
	#		#close_alinea;
			$inblock=1;
			my $ch=0;
			if (/^.block ([a-z]+) ([a-z0-9A-Z]+)/){
				$blocktype=$1;
				$blockname=$2;
			}
			elsif (/^.block ([a-z]+)/){
				$blocktype=$1;
				if (exists $variables{"H1"} ){
					$ch=$variables{"H1"}
				}
				else {
					$ch=0;
				}
				$blockcount++;
				$blockname="inline.$ch.$blockcount";
			}
			else { 
				$blocktype='none';
				$blockname='none';
			}
			inpush("{BLOCKSTART}$blocktype $blockname");
		}
		else {
			if (/^.block format (.*)/){
				inpush ("{BLOCKFORMAT}$1");
			}
			else {
				$inblock=0;
				inpush ("{BLOCKEND}");
			}
		}
	}
	elsif (/^\.inline/){
		inline($_,' ');
	}
	elsif ($inblock>0){
		if ($blocktype eq 'pre'){
			inpush("{LITTERAL}$_");
		}
		else {
			inpush("{BLOCK $blocktype}$_");
		}
	}
	elsif (/^\.pre/){
		debug ($TAGS,"Pre-tag (was: $inpre)");
		if ($inpre==0){
			$inpre=1;
			close_alinea;
		}
		else {$inpre=0};
	}
	elsif (/^\`\`\`/){
		debug ($TAGS,"Pre-tag (was: $inpre)");
		if ($inpre==0){
			$inpre=1;
			close_alinea;
		}
		else {$inpre=0};
	}
	elsif ($inpre>0){
		inpush("{LITTERAL}$_");
	}
	elsif ((/^    /)&&($variables{"markdown"}>0)){
		s/^    //;
		inpush("{LITTERAL}$_");
	}
	elsif ((/^>/)&&($variables{"markdown"}>0)){
		s/^>//;
		inpush("{LITTERAL}$_");
	}
	elsif (/^\.$/){
		debug($TAGS,"Single dot.");
		close_alinea;
	}
	elsif (/^$/){
		debug($TAGS,"Empty line found");
		close_alinea;
	}
	elsif (/^([A-Za-z0-9 ]+)	(.*)/){
		debug($TAGS,"Line with leftnote found");
		$leftnote=$1;
		$bodytext=$2;
		close_alinea;
		$variables{'notes'}=$variables{'notes'}|1;
		# Do not use start_alinea, because it would give an empty leftnote.
		inpush("{ALINEA}$variables{'notes'}");
		inpush("{LEFTNOTE}$leftnote");
		inpush("{TEXTNORMAL}$bodytext");
		$inalinea=1;
	}
	elsif (/^====*$/) {
		if ($variables{"markdown"}>0){
			my $prevtxt=$in3[$#in3];
			if ($prevtxt=~/^{TEXTNORMAL}/){
				debug($MARKDOWN,"MD header 1 $prevtxt");
				$in3[$#in3]="{NOP}";
				$prevtxt=~s/^{TEXTNORMAL}//;
				close_alinea;
				inpush("{HEADER 1}$prevtxt");
				start_alinea;
			}
			else{
				debug($MARKDOWN,"MD: previous line is not a h1");
				close_alinea;
				inpush ("{LINE}");
				inpush ("{LINE}");
				start_alinea;
			}
		}
		else{
			close_alinea;
			inpush ("{LINE}");
			inpush ("{LINE}");
			start_alinea;
		}
	}
	elsif (/^----*$/) {
		if ($variables{"markdown"}>0){
			my $prevtxt=$in3[$#in3];
			if ($prevtxt=~/^{TEXTNORMAL}/){
				debug($MARKDOWN,"MD header 2 $prevtxt");
				$in3[$#in3]="{NOP}";
				$prevtxt=~s/^{TEXTNORMAL}//;
				close_alinea;
				inpush("{HEADER 2}$prevtxt");
				start_alinea;
			}
			else{
				debug($MARKDOWN,"MD: previous line is not a h2");
				close_alinea;
				inpush ("{LINE}");
				start_alinea;
			}
		}
		else{
			close_alinea;
			inpush ("{LINE}");
			start_alinea;
		}
	}
	elsif ((/^\+[ 	](.*)/) &&($variables{"markdown"}>0)){
		$bodytext=$1;
		debug($MARKDOWN,"MD: List item with +");
		$inlist=1;
		s/^\*/-/;
		push @thislist,$_;
	}
	elsif ((/^\*[ 	](.*)/) &&($variables{"markdown"}>0)){
		$bodytext=$1;
		debug($MARKDOWN,"MD: List item with *");
		$inlist=1;
		s/^\*/-/;
		push @thislist,$_;
	}
	elsif (/^-[ 	](.*)/) {
		$bodytext=$1;
		$inlist=1;
		push @thislist,$_;
	}
	elsif (/^	-[ 	](.*)/) {
		$bodytext=$1;
		$inlist=1;
		push @thislist,$_;
	}
	elsif ((/^[a-z]\.[ 	](.*)/)&&($variables{"markdown"}>0)) {
		$bodytext=$1;
		debug($MARKDOWN,"MD: alpha list item with a");
		s/^[a-z]\./@/;
		$inlist=1;
		push @thislist,$_;
	}
	elsif (/^\@[ 	](.*)/) {
		$bodytext=$1;
		$inlist=1;
		push @thislist,$_;
	}
	elsif (/^	\@[ 	](.*)/) {
		$bodytext=$1;
		$inlist=1;
		push @thislist,$_;
	}
	elsif (/^\#[ 	](.*)/) {
		$bodytext=$1;
		if ($variables{"markdown"}>0){
			if ($inlist==0){
				close_alinea;
				$bodytext=~s/#*$//;
				inpush("{HEADER 1}$bodytext");
				debug($TAGS,"Header line: $_");
				debug($MARKDOWN,"MD: Header 1 line with #");
				$variables{'notes'}=$variables{'notes'}&2;
			}
			else {
				push @thislist,$_;
			}
		}
		else {
			$inlist=1;
			push @thislist,$_;
		}
	}
	elsif ((/^[0-9][0-9]*\.[ 	](.*)/) &&($variables{"markdown"}>0)){
		$bodytext=$1;
		debug($MARKDOWN,"MD: num list with 1.");
		s/^[0-9][0-9]*\./#/;
		push @thislist,$_;
		$inlist=1;
	}
	elsif (/^	\#[ 	](.*)/) {
		$bodytext=$1;
		$inlist=1;
		push @thislist,$_;
	}
	elsif (/^	/){
		if ($intable==0){close_alinea;}
		$intable=1;
		push @thistable,$_;
	}
	elsif (/^\.appendix *(.*)/) {

		inpush("{APPENDIX}$1");
		$variables{"appendix"}=1;
	}
	elsif (/^\.author (.*)/) {
		inpush("{AUTHOR}$1");
	}
	elsif (/^\.br/) {
		inpush("{LINEBREAK}");
	}
	elsif (/^\.b (.*)/) {
		$bodytext=$1;
		debug($TAGS,"Bold text:$_");
		start_alinea;
		if ($inlist>0) {
			push @thislist,$_;
		}
		else {
			inpush("{TEXTBOLD}$bodytext");
		}
	}
	elsif (/^\.back/) {
		debug($TAGS,".back (end of leftnotes)");
		$variables{'notes'}=$variables{'notes'}&2;
	}
	elsif (/^\.cover (.+)/){
		inpush("{COVER}$1");
		debug($TAGS,".cover: set cover to $1");
	}
	elsif (/^\.date/) {
		debug($TAGS,".date");
		inpush ("{TEXTNORMAL}$datestring");
	}
	elsif (/^\.dumpvar/){
		inpush("{LINEBREAK}");
		for my $key (keys %variables){
			inpush ("{TEXTBOLD} DUMP: $key=$variables{$key}");
			inpush("{LINEBREAK}");
		}
	}
	elsif (/^\.global/){
	}
	elsif (/^\.headerlink/){
	}
	elsif (/^\.fix[ed]* *(.*)/){
		my $textbody=$1;
		debug ($TAGS,"Fixed request");
		start_alinea;
		if ($inlist>0) {
			push @thislist,$_;
		}
		else {
			inpush ("{TEXTFIX}$textbody");
		}
	}
	elsif (/^\.hr/){
		debug($TAGS,"Horizontal line");
		close_alinea;
		inpush ("{LINE}");
		start_alinea;
	}
	elsif (/^\.header/){
		inpush("{INCLUDE}header");
	}
	elsif (/^\.hu ([0-9]) (.*)/){
		my $level=$1;
		$bodytext=$2;
		close_alinea;
		inpush("{HEADUNNUM $level}$bodytext");
		debug($TAGS,"Header line: $_");
		$variables{'notes'}=$variables{'notes'}&2;
	
	}
	elsif (/^\.h([0-9]) (.*)/){
		$level=$1;
		$bodytext=$2;
		close_alinea;
		inpush("{HEADER $level}$bodytext");
		debug($TAGS,"Header line: $_");
		$variables{'notes'}=$variables{'notes'}&2;
	
	}
	elsif (/^\.h([0-9])/){
		$level=$1;
		$bodytext=$2;
		close_alinea;
		inpush("{HEADER $level}");
		debug($TAGS,"Header line: $_");
		$variables{'notes'}=$variables{'notes'}&2;
	
	}
	elsif (/^\.i (.*)/){
		my $textbody=$1;
		start_alinea;
		debug ($TAGS,"Italic request");
		if ($inlist>0) {
			push @thislist,$_;
		}
		else {
			inpush ("{TEXTITALIC}$textbody");
		}
	}
	elsif (/^\.img /) {
		debug($TAGS,"Image tag: $_");
		if ($inlist>0){
			push @thislist,$_;
		}
		else {
			s/^\.img *//;
			inpush("{IMAGE}$_");
		}
	}
	elsif (/^\.lang /){
		if (/^\.lang ([^ ]*)/){
			inpush ("{LANGUAGE}$1");
			debug ($TAGS,"Link: $1");
		}
	}
	elsif (/^\.link /){
		if (/^\.link ([^ ]*) (.*)/){
			inpush ("{LINK}$1 $2");
			debug ($TAGS,"Link: $1 $2");
		}
		elsif (/^\.link ([^ ]*)/){
			inpush ("{LINK}$1 $1");
			debug ($TAGS,"Link: $1 $1");
		}
		else { print STDERR "Unknown link command $_\n"; }
	}
	elsif (/^\.lst(.*)/){
		start_alinea;
		inpush ("{LST}$1");
		debug ($TAGS,"LST $1");
	}
	elsif (/^\.map ([^ ]+) +(.*)/){
		my $submap=$1;
		my $args=$2;
		if ($1 eq 'image') {$inmap=1; $mappict=$2;}
		elsif ($1 eq 'pic') {$inmap=1; $mappict=$2;}
		elsif ($1 eq 'picture') {$inmap=1; $mappict=$2;}
		elsif ($1 eq 'field') {$inmap=1; push @thismap,$2;}
		elsif ($1 eq 'link') {$inmap=1; push @thismap,$2;}
		else { print "ERROR-- UNKNOWN MAP $1 $2\n";}
	}
	elsif (/^\.note (.*)/){
		my $text=$1;
		debug ($TAGS,"Note: $text");
		inpush("{NOTE}$text");
	}
	elsif (/^\.page/){
		s/^.page //;
		inpush ("{PAGE}$_");
	}
	elsif (/^\.p/){
		debug ($TAGS,"Hard paragraph separator");
		inpush("{HARDPARAGRAPH}");
	}
	elsif (/^\.quote/){
		s/\.quote *//;
		debug ($TAGS,"Quote: $_");
		inpush("{QUOTE}$_");
	}
	elsif (/^\.u (.*)/){
		my $textbody=$1;
		start_alinea;
		if ($inlist>0) {
			push @thislist,$_;
		}
		else {
			inpush ("{TEXTUNDERLINE}$textbody");
		}

	}
	elsif (/^\.set ([^ ]+) (.*)/){
		$variables{$1}=$2;
		inpush("{SET}$1 $2");
	}
	elsif (/^\.side /){
		debug($SIDENOTE,"Sidenote line: $_");
		if (/^.side char (.*)/){
			$sidechar=$1;
		}
		elsif (/^.side separator (.*)/){
			$sideseparator=$1;
		}
		else {
			if ($inalinea==0){
				start_alinea;
				inpush("{TEXTNORMAL}");
			}
			my $i=0;
			while ( !($in3[$#in3-$i]=~/^{TEXT/) && ($i<5)){
				debug ($SIDENOTE,"Add $sidechar to line-$i line");
				$i++;
			}
			$in3[$#in3]="$in3[$#in3-$i]$sidechar";
			s/^\.side //;
			debug($TAGS,"Sidenote $_");
			$sidenote="$sidenote$sideseparator $_";
			$sidenote=~s/^$sideseparator//;
			debug($SIDENOTE,"Sidenote is now $sidenote");
		}
	}
	elsif (/^\.string ([^ ]) (.*)/){
		inpush("{STRING}$1 $2");
	}
	elsif (/^\.title (.*)/) {
		inpush("{TITLE}$1");
	}
	elsif (/^\.sub (.*)/) {
		inpush ("{SUBSCRIPT}$1");
	}
	elsif (/^\.subtitle (.*)/) {
		inpush("{SUBTITLE}$1");
	}
	elsif (/^\.sup (.*)/) {
		inpush ("{SUPERSCRIPT}$1");
	}
	elsif (/^\.toc([0-9]*) (.*)/){
		# Depricated 'toc' request
		my $level=$1;
		my $text=$2;
		debug ($TAGS,"Depricated .toc $level: $text");
		if ($level eq ''){
			if (/\.like/){}
			else {
				inpush("{HEADER 0}$text");
			}
		}
		elsif ($level==1){
			inpush("{TITLE}$text");
		}
		elsif ($level==2){
			inpush("{HEADUNNUM 0}$text");
		}
		elsif ($level==3){
			inpush("{SUBTITLE}$text");
		}
	}
	elsif(/^\. *\. *\. */){
		start_alinea;
		debug($TAGS,"Normal text $_");
		s/ *$//;
		inpush("{TEXTNORMAL}$_");
	}
	elsif(/^\./){
		print STDERR "Unknown request $_\n";
	}
	else {
		debug($TAGS,"Normal text $_");
		s/ *$//;
		if ($inlist>0){
			push @thislist,$_;
		}
		else {
			start_alinea;
			inpush("{TEXTNORMAL}$_");
		}
	}
}

close_alinea;

#################################################

#######  #     #  #######  ######   #     #  #######  
#     #  #     #     #     #     #  #     #     #     
#     #  #     #     #     #     #  #     #     #     
#     #  #     #     #     ######   #     #     #     
#     #  #     #     #     #        #     #     #     
#     #  #     #     #     #        #     #     #     
#######   #####      #     #         #####      #   

for (@in3){
	print "$_\n";
}

		

