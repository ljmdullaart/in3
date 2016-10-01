#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3

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
	$what='';
	for (@ARGV){
		if ($what eq ''){
			if (1==0){}
			elsif (/^-d([0-9]+)/){ $variables{"DEBUG"}=$1; }
			elsif (/^-d$/){$what='debug';}
			elsif (/^-c([0-9]+)/){ $variables{"H1"}=$1;}
			elsif (/^-c$/){$what='chapter';}
			elsif (/^-i([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^-i$/){$what='interpret';}
			elsif (/^-+h/){ hellup; }
			elsif (/^-/){ print STDERR "$_ is not known as a flag; ignored.\n";}
			else {
				$file=$_;
				if ($file=~/^([0-9]+)_/){$ch=$1;} else {$ch=-1;}
				if (open(IN,$file)){
					if ($ch>0){
						push @input,".set H1 $ch";
					}
					while (<IN>){
						push @input,$_;
					}
					close IN;
				}
				else {print STDERR "Cannot open $_; ignored.\n";}
			}
		}
		elsif ($what eq 'debug'){
			if (/([0-9]+)/){ $variables{"H1"}=$1;}
			else {print STDERR "Can't find a numeric value for 'DEBUG' in $_; ignored the debug set.\n";}
			$what='';
		}
		elsif ($what eq 'H1'){
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
	push @in3,$line;
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
		my @types;
		for (@thislist){
			debug ($LISTS,"list line: $_");
			# Determine target list-level and the type
			if (/^-[ 	]/){ $target=1; $types[1]='-';}
			elsif (/^	-[ 	]/){ $target=2; $types[2]='-';}
			elsif (/^		-[ 	]/){ $target=3; $types[3]='-';}
			elsif (/^\#[ 	]/){ $target=1; $types[1]='#';}
			elsif (/^	\#[ 	]/){ $target=2; $types[2]='#';}
			elsif (/^		\#[ 	]/){ $target=3; $types[3]='#';}
			elsif (/^\@[ 	]/){ $target=1; $types[1]='@';}
			elsif (/^	\@[ 	]/){ $target=2; $types[2]='@';}
			elsif (/^		\@[ 	]/){ $target=3; $types[3]='@';}
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
			s/^[-#@	 ]*//;
			if ($types[$listlevel] eq '-'){ inpush("{LISTDASHITEM}$_");}
				elsif ($types[$listlevel] eq '#'){ inpush("{LISTNUMITEM}$_");}
				elsif ($types[$listlevel] eq '@'){ inpush("{LISTALPHAITEM}$_");}
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
	debug ($FUNCTIONS,"Close table ($intable)");
	if ($intable>0){
		inpush("{TABLESTART}");
		for (@thistable){
			chomp;
			s/^	//;
			@line=split('	',$_);
			$x=0;
			for (@line){
				my $txt=$_;
				if (/<cs=([0-9]*)>/){
					my $span=$1;
					for (my $i=0;$i<$span;$i++){
						$output_table[$x+$i][$y]='<HSPAN>';
					}
					$output_table[$x][$y]=$txt;
					
				}
				if (/<rs=([0-9]*)>/){
					my $span=$1;
					for (my $i=0;$i<$span;$i++){
						$output_table[$x][$y+$i]='<VSPAN>';
					}
					$output_table[$x][$y]=$txt;
				}
				if ($output_table[$x][$y] eq '<VSPAN>'){$x++;}
				if ($output_table[$x][$y] eq '<HSPAN>'){$x++;}
				$output_table[$x][$y]=$txt;
				$x++; if($x>$maxx){$maxx=$x;}
			}
			$y++;if($y>$maxy){$maxy=$y;}
		}
			
		for ($y=0; $y<$maxy; $y++){
			inpush( "{TABLEROW}");
			for ($x=0; $x<$maxx;$x++){
				inpush("{TABLECEL}$output_table[$x][$y]");
			}
			inpush( "{TABLEROWEND}");
		}
		inpush("{TABLEEND}");
	}
	undef @thistable;
	$intable=0;
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
	if (/^\.pre/){
		debug ($TAGS,"Pre-tag (was: $inpre)");
		if ($inpre==0){$inpre=1;}
		else {$inpre=0};
	}
	elsif ($inpre>0){
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
		$inlist=1;
		push @thislist,$_;
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
		inpush("{TEXTBOLD}$bodytext");
	}
	elsif (/^\.back/) {
		debug($TAGS,".back (end of leftnotes)");
		$variables{'notes'}=$variables{'notes'}&2;
	}
	elsif (/^\.global/){
	}
	elsif (/^\.fix (.*)/){
		my $textbody=$1;
		start_alinea;
		debug ($TAGS,"Fixed request");
		inpush ("{TEXTFIX}$textbody");
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
		$level=$1;
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
	elsif (/^\.i (.*)/){
		my $textbody=$1;
		start_alinea;
		debug ($TAGS,"Italic request");
		inpush ("{TEXTITALIC}$textbody");
	}
	elsif (/^\.img /) {
		debug($TAGS,"Image tag: $_");
		s/^\.img *//;
		inpush "{IMAGE}$_";
	}
	elsif (/^\.link ([^ ]*) (.*)/){
		inpush ("{LINK}$1 $2");
		debug ($TAGS,"Link: $1 $2");
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
		$text=$1;
		debug ($TAGS,"Note: $text");
		inpush("{NOTE}$text");
	}
	elsif (/^\.u (.*)/){
		my $textbody=$1;
		start_alinea;
		debug ($TAGS,"Underline request");
		inpush ("{TEXTUNDERLINE}$textbody");
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
		start_alinea;
		debug($TAGS,"Normal text $_");
		s/ *$//;
		inpush("{TEXTNORMAL}$_");
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

		
