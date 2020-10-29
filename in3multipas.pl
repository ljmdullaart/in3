#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3multipass

use File::Basename;
use strict;
use warnings;

my $otrace=0;
my $DEBUG=0;

# __     __         _       _     _
# \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___
#  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
#   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
#    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
#

my %variables;
	$variables{'leftnotechar'}='';
	$variables{'sidesep'}=';';
	$variables{'sideref'}='';
	$variables{'sidechar'}='*';
	$variables{'sidenumber'}=0;
	$variables{'title'}='';
	$variables{'subtitle'}='';
	$variables{'cover'}='';
	$variables{'author'}='';
	$variables{'appendix'}=0;
	$variables{'back'}=0;
	$variables{'keywords'}='';
	$variables{'notenumber'}=0;
	$variables{'notestring'}='(%NUM)';
	$variables{'blocknumber'}=0;
	$variables{'H1'}=0;
	$variables{'H2'}=0;
	$variables{'H3'}=0;
	$variables{'H4'}=0;
	$variables{'H5'}=0;
	$variables{'H6'}=0;
	$variables{'H7'}=0;
	$variables{'H8'}=0;
	$variables{'H9'}=0;
	$variables{'markdown'}=0;
	$variables{'inlineemp'}=0;
	$variables{'filename'}='stdin';
	$variables{'blockname'}=$variables{'filename'};


my @passin;
my @passout;
my @inlinenr;
my @outlinenr;
my $passname='none';
my $inline=0;

my $progchar='-';

my $progressindicator=0;
sub progress {
	if ($progressindicator>0){
		if ($progchar eq '-'){$progchar='/'; }
		elsif ($progchar eq '/'){$progchar='|'; }
		elsif ($progchar eq '|'){$progchar='\\'; }
		elsif ($progchar eq '\\'){$progchar='-'; }
		print STDERR "$progchar\r";
	}
}

#  ___                   _                                       _
# |_ _|_ __  _ __  _   _| |_   _ __  _ __ ___   ___ ___  ___ ___(_)_ __   __ _
#  | || '_ \| '_ \| | | | __| | '_ \| '__/ _ \ / __/ _ \/ __/ __| | '_ \ / _` |
#  | || | | | |_) | |_| | |_  | |_) | | | (_) | (_|  __/\__ \__ \ | | | | (_| |
# |___|_| |_| .__/ \__,_|\__| | .__/|_|  \___/ \___\___||___/___/_|_| |_|\__, |
#           |_|               |_|                                        |___/

my @input;
my @realin;
my $lineindex=0;
if ($#ARGV<0){
	$variables{'filename'}='stdin';
	while (<>){
		push @realin,$_;
		push @passin,$_;
		push @inlinenr,"$variables{'filename'}:$lineindex";
		$lineindex++;
	}
}
else {
	my $what='';
	for (@ARGV){
		if ($otrace>0){ print STDERR "ARGUMENT: $_\n";}
		if ($what eq ''){
			if (/^--$/){ while (<STDIN>){push @input,$_;}}
			elsif (/^--debug([0-9]+)/){ $variables{"DEBUG"}=$1; }
			elsif (/^--debug=([0-9]+)/){ $variables{"DEBUG"}=$1; }
			elsif (/^-d$/){$what='debug';}
			elsif (/^--debug$/){$what='debug';}
			elsif (/^-c([0-9]+)/){ $variables{"H1"}=$1-1;}
			elsif (/^--chapter([0-9]+)/){ $variables{"H1"}=$1-1;}
			elsif (/^--chapter=([0-9]+)/){ $variables{"H1"}=$1-1;}
			elsif (/^-c$/){$what='chapter';}
			elsif (/^--chapter$/){$what='chapter';}
			elsif (/^-i([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^--interpret([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^--interpret=([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^-i$/){$what='interpret';}
			elsif (/^--interpret$/){$what='interpret';}
			elsif (/^-m/){$variables{"markdown"}=1;}
			elsif (/^--markdown/){$variables{"markdown"}=1;}
			elsif (/^-+h/){ hellup(); }
			elsif (/^-p/){ $progressindicator=1;}
			elsif (/^-/){ print STDERR "$_ is not known as a flag; ignored.\n";}
			else {
				my $file=$_;
				$variables{'filename'}=$file;
				if ($otrace>0){ print "Processing $file\n";}
				my $ch;	# Chapter number from filename
				if ($file=~/^([0-9]+)_/){$ch=$1-1;} else {$ch=0;}
				if (open(my $IN,'<',$file)){
					if ($ch>0){
						if ($otrace>0){ print "Chapter:$ch\n";}
						push @passin,".set H1 $ch";
						push @passin,'';
						$variables{"H1"}=$ch;
						push @inlinenr,"-1";
						push @inlinenr,"-1";
					}
					while (<$IN>){
						chomp;
						push @realin,$_;
						push @passin,$_;
						push @inlinenr,"$variables{'filename'}:$lineindex";
						if ($otrace>0){ print "READ LINE FROM $file: $_\n";}
						$lineindex++;
					}
					push @realin,'';
					push @passin,$_;
					push @inlinenr,"$variables{'filename'}:$lineindex";
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
}


if ($otrace>0){
	for (my $i=0; $i<+$#passin;$i++){
		print "INPUT: $inlinenr[$i] '$passin[$i]'\n";
	}
}
#                                   _   _                         _
#  ___ _   _ _ __  _ __   ___  _ __| |_(_)_ __   __ _   ___ _   _| |__  ___
# / __| | | | '_ \| '_ \ / _ \| '__| __| | '_ \ / _` | / __| | | | '_ \/ __|
# \__ \ |_| | |_) | |_) | (_) | |  | |_| | | | | (_| | \__ \ |_| | |_) \__ \
# |___/\__,_| .__/| .__/ \___/|_|   \__|_|_| |_|\__, | |___/\__,_|_.__/|___/
#           |_|   |_|                           |___/

sub pushout {
	(my $txt)=@_;
	$txt='' unless defined $txt;
	push @passout,$txt;
	push @outlinenr,$inlinenr[$lineindex];
	if ($otrace>0){
		my $i=0;
		#print "$passname: $txt\n";
		if ($inlinenr[$lineindex]=~/:([0-9]*)/){$i=$1;}
		my $t1=$realin[$i];
		my $t2=$txt;
		$t1=~s/	/    /g;
		$t2=~s/	/    /g;
		printf("TRACE-%s-%s  %-50.50s | %-20.20s |%-50.50s\n",$variables{'filename'},$passname,$t1,$inlinenr[$i],$t2);
	}
}

sub debug {
	if ($DEBUG>0){
		for (@_){
			print "$passname: $_\n";
		}
	}
}

sub endpass {
	undef @passin;
	undef @inlinenr;
	@passin=@passout;
	@inlinenr=@outlinenr;
	undef @passout;
	undef @outlinenr;
	$lineindex=-1;
}




sub varset{
	(my $line)=@_;
	$line='' unless defined $line;
	if ($line=~/^\.title *(.*)/){
		$variables{'title'}=$1;
	}
	elsif ($line=~/^\.subtitle *(.*)/){
		$variables{'subtitle'}=$1;
	}
	elsif ($line=~/^\.cover *(.*)/){
		$variables{'cover'}=$1;
	}
	elsif ($line=~/^\.author *(.*)/){
		$variables{'author'}=$1;
	}
	elsif ($line=~/^\.keywords *(.*)/){
		$variables{'keywords'}=$1;
	}
	elsif ($line=~/^\.appendix/){
		$variables{'appendix'}=1;
	}
	elsif ($line=~/^\.back/){
		$variables{'back'}=1;
	}
	elsif ($line=~/^\.set *([\w]+) *(.*)/){
		$variables{$1}=$2;
	}
	if ($inlinenr[$lineindex]=~/(.*):/){$variables{'filename'}=$1;}
}
sub varpush{
	(my $var,my $val)=@_;
	pushout('<set>');
	pushout('<variable>');
	pushout($var);
	pushout('</variable>');
	pushout('<value>');
	pushout($val);
	pushout('</value>');
	pushout('</set>');
}

#      _                               _   _
#   __| | ___ _ __  _ __ ___  ___ __ _| |_(_) ___  _ __  ___
#  / _` |/ _ \ '_ \| '__/ _ \/ __/ _` | __| |/ _ \| '_ \/ __|
# | (_| |  __/ |_) | | |  __/ (_| (_| | |_| | (_) | | | \__ \
#  \__,_|\___| .__/|_|  \___|\___\__,_|\__|_|\___/|_| |_|___/
#            |_|
sub depricatepass{
	$passname='depricatepass';
	foreach (@passin){
		$lineindex++;
		varset($_);
		chomp;
		if (/^\.$/){	#deprecated . to separate paragraphs
			pushout ('');
		}
		elsif (/^\.[Pp]$/){	#deprecated .p to separate paragraphs
			pushout ('');
		}
		elsif (/^\.h[0-9]$/){	#deprecated header without blankline before
			pushout ('');
			pushout ($_);
		}
		else {
			pushout ($_);
		}
	}
	endpass();
}
#                  _       _     _
# __   ____ _ _ __(_) __ _| |__ | | ___  ___   _ __   __ _ ___ ___
# \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __| | '_ \ / _` / __/ __|
#  \ V / (_| | |  | | (_| | |_) | |  __/\__ \ | |_) | (_| \__ \__ \
#   \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/ | .__/ \__,_|___/___/
#                                             |_|
# Extract variables from the document and fill-in dumpvars                                             
sub varpass{
	$passname='varpass';
	for (@passin){
		$lineindex++;
		if (/^\.title *(.*)/){ varpush('title',$1); }
		elsif (/^\.subtitle *(.*)/){ varpush('subtitle',$1); }
		elsif (/^\.keywords *(.*)/){ varpush('keywords',$1); }
		elsif (/^\.cover *(.*)/){ varpush('cover',$1); }
		elsif (/^\.author *(.*)/){ varpush('author',$1); }
		elsif (/^\.appendix *(.*)/){ varpush('appendix',1); }
		elsif (/^\.back *(.*)/){ varpush('back',1); }
		elsif (/^\.set *([\w]+) *(.*)/){ varpush($1,$2); }
		elsif (/^\.dumpvar (.*)/){ pushout($variables{$1});}
		elsif (/^\.dumpvar/){
			pushout('<block>');
			pushout('<type>');
			pushout('"lst"');
			pushout('</type>');
			pushout('<-- dumpvar -->');
			pushout('<text>');
			for (keys %variables){
				pushout("\"$_=$variables{$_}\"");
			}
			pushout('</text>');
			pushout('</text>');
			pushout('</block>');
		}
		else { pushout($_); }
	}
	endpass();
}

#  _            _           _
# (_)_ __   ___| |_   _  __| | ___
# | | '_ \ / __| | | | |/ _` |/ _ \
# | | | | | (__| | |_| | (_| |  __/
# |_|_| |_|\___|_|\__,_|\__,_|\___|
#
sub includepass {
	$passname='includepass';
	for (@passin){
		$lineindex++;
		$_='' unless defined $_;
		varset($_);
		if (/^\.header/){
			pushout('<header>');
			pushout('</header>');
		}
		else { pushout($_); }
	}
	endpass();
}

#                       _       _
#  _ __ ___   __ _ _ __| | ____| | _____      ___ __
# | '_ ` _ \ / _` | '__| |/ / _` |/ _ \ \ /\ / / '_ \
# | | | | | | (_| | |  |   < (_| | (_) \ V  V /| | | |
# |_| |_| |_|\__,_|_|  |_|\_\__,_|\___/ \_/\_/ |_| |_|
#
#   __                            _   _   _
#  / _| ___  _ __ _ __ ___   __ _| |_| |_(_)_ __   __ _
# | |_ / _ \| '__| '_ ` _ \ / _` | __| __| | '_ \ / _` |
# |  _| (_) | |  | | | | | | (_| | |_| |_| | | | | (_| |
# |_|  \___/|_|  |_| |_| |_|\__,_|\__|\__|_|_| |_|\__, |
#                                                 |___/

sub mdformatpass {
	$passname='mdformatpass';
	for (@passin){
		my $line=$_;
		chomp;
		varset($_);
		$lineindex++;
		my $mx=0;
		my @mdline1;
		my @mdline2;
		push @mdline1,$line;
		if ($variables{'markdown'}+$variables{'inlineemp'}>0){
			my $repl=1;
			while ($repl>0){
				$repl=0;
				for (@mdline1){
					if (/^(.*) \*([^*]+)\* (.*)/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<bold>';
						push @mdline2,$2;
						push @mdline2,'</bold>';
						push @mdline2,$3;
					}
					elsif (/^\*([^*]+)\* (.*)/){
						$repl++;
						push @mdline2,'<bold>';
						push @mdline2,$1;
						push @mdline2,'</bold>';
						push @mdline2,$2;
					}
					elsif (/^(.*) \*([^*]+)\*$/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<bold>';
						push @mdline2,$2;
						push @mdline2,'</bold>';
					}
					elsif (/^(.*) _([^_]+)_ (.*)/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<underline>';
						push @mdline2,$2;
						push @mdline2,'</underline>';
						push @mdline2,$3;
					}
					elsif (/^_([^_]+)_ (.*)/){
						$repl++;
						push @mdline2,'<underline>';
						push @mdline2,$1;
						push @mdline2,'</underline>';
						push @mdline2,$2;
					}
					elsif (/^(.*) _([^_]+)_/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<underline>';
						push @mdline2,$2;
						push @mdline2,'</underline>';
					}
					elsif (/^(.*) \/\/([^\/]+)\/\/ (.*)/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<italic>';
						push @mdline2,$2;
						push @mdline2,'</italic>';
						push @mdline2,$3;
					}
					elsif (/^\/\/([^\/]+)\/\/ (.*)/){
						$repl++;
						push @mdline2,'<italic>';
						push @mdline2,$1;
						push @mdline2,'</italic>';
						push @mdline2,$2;
					}
					elsif (/^(.*) \/\/([^\/]+)\/\//){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<italic>';
						push @mdline2,$2;
						push @mdline2,'</italic>';
					}
					else {
						push @mdline2,$_;
					}
				} #end md format loop
				undef @mdline1;
				@mdline1=@mdline2;
				undef @mdline2;
			} # while replaced loop
			for (@mdline1){
				pushout($_);
			}
		}
		else {
			pushout($line);
		}
	}
	endpass();
}

#                       _       _
#  _ __ ___   __ _ _ __| | ____| | _____      ___ __
# | '_ ` _ \ / _` | '__| |/ / _` |/ _ \ \ /\ / / '_ \
# | | | | | | (_| | |  |   < (_| | (_) \ V  V /| | | |
# |_| |_| |_|\__,_|_|  |_|\_\__,_|\___/ \_/\_/ |_| |_|
#
#                      _                   _
#   ___ ___  _ __  ___| |_ _ __ _   _  ___| |_ ___
#  / __/ _ \| '_ \/ __| __| '__| | | |/ __| __/ __|
# | (_| (_) | | | \__ \ |_| |  | |_| | (__| |_\__ \
#  \___\___/|_| |_|___/\__|_|   \__,_|\___|\__|___/
#
sub markdownpass {
	$passname='markdownpass';
	for (@passin){
		my $line=$_;
		$line='' unless defined $line;
		chomp;
		varset($_);
		$lineindex++;
		my $mx=0;
		if ($variables{'markdown'}>0){
			debug ("markdown=1 for '$line'");
			$mx=$#passout;
			#ATX headings
			if (/^ {0,3}# /){ s/^ {0,3}#/.h1/;s/ *#$//; pushout($_); debug ('atx h1');}
			elsif (/^ {0,3}## /){ s/^ {0,3}##/.h2/;s/ *##$//; pushout($_); debug ('atx h2');}
			elsif (/^ {0,3}### /){ s/^ {0,3}###/.h3/;s/ *###$//; pushout($_); debug ('atx h3');}
			elsif (/^ {0,3}#### /){ s/^ {0,3}####/.h4/;s/ *####$//; pushout($_); debug ('atx h4');}
			elsif (/^ {0,3}##### /){ s/^ {0,3}#####/.h5/;s/ *#####$//; pushout($_); debug ('atx h5');}
			elsif (/^ {0,3}###### /){ s/^ {0,3}######/.h6/;s/ *######$//; pushout($_); debug ('atx h6');}
			# Setex heading and thematic breaks
			elsif (/^ {0,3}===/){
				debug ('setex h1');
				if ($passout[$mx]=~/^\./){ pushout($line);}
				elsif ($passout[$mx]=~/^\-/){ pushout($line);}
				elsif ($passout[$mx]=~/^$/){ pushout($line);}
				else { $passout[$mx]=".h1 $passout[$mx]";}
			}
			elsif (/^ {0,3}---/){
				debug ('setex h2');
				if ($passout[$mx]=~/^\./){ pushout('.hr');}
				elsif ($passout[$mx]=~/^\-/){ pushout('.hr');}
				elsif ($passout[$mx]=~/^$/){ pushout('.hr');}
				else { $passout[$mx]=".h2 $passout[$mx]";}
			}
			# pre-formatted blocks
			elsif (/^```/){ pushout('.pre');debug ('pre');}
			#elsif (/^>(.*)/){ pushout(".lst $1");debug ('lst');} # interferes with Liliypond
			# lists
			elsif (/^(\t)*[0-9]+\.[ 	](.*)/){  pushout("$1# $2"); debug ('numlist');}
			elsif (/^(\t)*[a-z]\.[ 	](.*)/){  pushout("$1@ $2"); debug ('alphalist');}
			elsif (/^(\t*)-[ 	](.*)/){  pushout("$1- $2"); debug ('dashlist');}
			else { pushout($line); debug ('rest output'); }
		}
		else { pushout($line);debug ("markdown=0 for $line");}
	}
	endpass();
}

		


#  _ __ ___   __ _ _ __  
# | '_ ` _ \ / _` | '_ \ 
# | | | | | | (_| | |_) |
# |_| |_| |_|\__,_| .__/ 
#                 |_|
#

sub mappass {
	$passname='mappass';
	my $inmap=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if ($inmap==0){
			if (/^\.map/){
				pushout('<map>');
				$inmap=1;
				if (/^\.map image (.*)/){
					pushout('<file>');
					pushout($1);
					pushout('</file>');
				}
				elsif (/^\.map field ([^ ]+) ([,0123456789]+)/){
					pushout('<field>');
					pushout('<target>');
					pushout($1);
					pushout('</target>');
					pushout('<coord>');
					pushout($2);
					pushout('</coord>');
					pushout('</field>');
				}
			}
			else { pushout($_); }
		}
		else {
			if (/^\.map image (.*)/){
				pushout('<file>');
				pushout($1);
				pushout('</file>');
			}
			elsif (/^\.map field ([^ ]+) ([,0123456789]+)/){
				pushout('<field>');
				pushout('<target>');
				pushout($1);
				pushout('</target>');
				pushout('<coord>');
				pushout($2);
				pushout('</coord>');
				pushout('</field>');
			}
			else {
				pushout('</map>');
				pushout($_);
				$inmap=0;
			}
		}
	}
	endpass();
}





#  _     _            _
# | |__ | | ___   ___| | _____
# | '_ \| |/ _ \ / __| |/ / __|
# | |_) | | (_) | (__|   <\__ \
# |_.__/|_|\___/ \___|_|\_\___/
#
sub blockpass {
	$passname='blockpass';
	my $inblk=0;
	my $inpre=0;
	my @thisblock;
	my $blockname='';
	for (@passin){
		varset($_);
		$lineindex++;
		my $line=$_;
		$line='' unless defined $line;
		if ($inblk+$inpre==0){
			if ($line=~/^\.block (.*)/){
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				$blockname="$variables{'filename'}.$variables{'blocknumber'}";
				progress();
				pushout("<block>");
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout("\"$1\""); pushout("</type>");
				$inblk=1;
				undef @thisblock;
			}
			elsif ($line=~/^\.pre/){
				$blockname="$variables{'filename'}.$variables{'blocknumber'}";
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				$blockname="$variables{'filename'}.$variables{'blocknumber'}";
				pushout("<block>");
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout('"pre"'); pushout("</type>");
				$inpre=1;
				undef @thisblock;
			}
			else { pushout($line); }
		}
		elsif ($inpre==1){
			if ($line=~/^\.pre/){
				pushout("<text>");
				for (@thisblock){
					pushout("\"$_\"");
				}
				pushout("</text>");
				pushout("</block>");
				$inpre=0;
			}
			else { push @thisblock,$line; }
		}
		elsif ($inblk==1){
			if (/^\.block format (.*)/){
				pushout("<format>"); pushout("\"$1\""); pushout("</format>");
			}
			elsif (/^\.block/){
				pushout("<text>");
				for (@thisblock){
					pushout("\"$_\"");
				}
				pushout("</text>");
				pushout("</block>");
				$inblk=0;
			}
			else { push @thisblock,$line; }
		}
	}
	endpass();
}
#  _             _ _              _     _            _        
# (_)_ __       | (_)_ __   ___  | |__ | | ___   ___| | _____ 
# | | '_ \ _____| | | '_ \ / _ \ | '_ \| |/ _ \ / __| |/ / __|
# | | | | |_____| | | | | |  __/ | |_) | | (_) | (__|   <\__ \
# |_|_| |_|     |_|_|_| |_|\___| |_.__/|_|\___/ \___|_|\_\___/
# 
sub inlinepass {
	$passname='inlinepass';
	for (@passin){
		varset($_);
		$lineindex++;
		chomp;
		if (/^\.inline ([a-z]+) (.*)/){
			$variables{'blocknumber'}=$variables{'blocknumber'}+1;
			my $blockname="$variables{'filename'}.$variables{'blocknumber'}";
			progress();
			pushout("<block>");
			pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
			pushout("<type>");
			pushout("\"$1\"");
			pushout("</type>");
			pushout("<text>");
			pushout("\"$2\"");
			pushout("</text>");
			pushout("</block>");
		}
		else { pushout($_); }
	}
	endpass();
}

#  _                    _ _                 
# | |__   ___  __ _  __| (_)_ __   __ _ ___ 
# | '_ \ / _ \/ _` |/ _` | | '_ \ / _` / __|
# | | | |  __/ (_| | (_| | | | | | (_| \__ \
# |_| |_|\___|\__,_|\__,_|_|_| |_|\__, |___/
#                                 |___/   
# (chapter section paragraph)                                 
sub headingpass {
	$passname='headingpass';
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.h([0-9]) (.*)/){
			my $level=$1;
			my $text=$2;
			$variables{"H$level"}++;
			my $seq='';
			for (my $i=1;$i<=$level;$i++){$seq=$seq.$variables{"H$i"}.'.';}
			for (my $i=$level+1;$i<10;$i++){$variables{"H$i"}=0;}
			pushout("<heading>");
			pushout("<level>");
			pushout("\"$level\"");
			pushout("</level>");
			pushout("<seq>");
			pushout("\"$seq\"");
			pushout("</seq>");
			pushout("<text>");
			pushout("\"$text\"");
			pushout("</text>");
			pushout("</heading>");
			pushout("");
		}
		else { pushout($_); }
	}
	endpass();
}
#  _   _            _                _        _   _ _            
# | | | | ___  _ __(_)_______  _ __ | |_ __ _| | | (_)_ __   ___ 
# | |_| |/ _ \| '__| |_  / _ \| '_ \| __/ _` | | | | | '_ \ / _ \
# |  _  | (_) | |  | |/ / (_) | | | | || (_| | | | | | | | |  __/
# |_| |_|\___/|_|  |_/___\___/|_| |_|\__\__,_|_| |_|_|_| |_|\___|
# 
sub hrpass {
	$passname='hrpass';
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.hr/){
			pushout("<hr>");
			pushout("</hr>");
		}
		elsif (/^\.P/){
			pushout("<blank>");
			pushout("</blank>");
		}
		else {
			pushout($_);
		}
	}
	endpass();
}

#  _
# | |_ ___   ___
# | __/ _ \ / __|
# | || (_) | (__
#  \__\___/ \___|
#
sub tocpass {
	$passname='tocpass';
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.toc[0-9]* (.*)/){
			pushout("<toc>");
			pushout($1);
			pushout("</toc>");
		}
		elsif (/^\.toc/){
			pushout("<toc>");
			pushout("</toc>");
		}
		else {
			pushout($_);
		}
	}
	endpass();
}

#  _ _     _       
# | (_)___| |_ ___ 
# | | / __| __/ __|
# | | \__ \ |_\__ \
# |_|_|___/\__|___/
# 
sub listpass {
	$passname='listpass';
	my $listlevel=0;
	my $newlevel=0;
	my $content='';
	for (@passin){
		varset($_);
		$content=$_;
		$lineindex++;
		if (/^(\t*)([-@#])[ 	]+(.*)/){
			if ( defined $2){
				$newlevel=length("$1.$2")-1;
			}
			else { $newlevel=$listlevel; }
			my $content=$3;
			my $listtype;
			if ($2 eq '-'){ $listtype='dash';}
			elsif ($2 eq '#'){ $listtype='num';}
			elsif ($2 eq '@'){ $listtype='alpha';}
			if ($newlevel>$listlevel){
				pushout("<list>");
				pushout("<type>");
				pushout("\"$listtype\"");
				pushout("</type>");
				$listlevel=$newlevel;
			}
			elsif($newlevel<$listlevel){
				pushout("</list>");
				$listlevel=$newlevel;
			}
			pushout("<item>");
			if ($content=~/%\\n/){
				my @cellines=split /%\\n/ , $content;
				for (@cellines){pushout($_);}
				undef @cellines;
			}
			else { pushout($content);}
			pushout("</item>");
		}
		elsif (/^$/){      #not a list-initiator
			while ($listlevel >0){
				pushout('</list>');
				$listlevel--;
			}
			$listlevel=0;
			$newlevel=0;
			 
			pushout($_);
		}
		else {   # not a list initiator, and not an empty line
			if ($listlevel>0){
				my $max=$#passout;
				pop @passout;
				$inline=1;
				if ($content=~/%\\n/){
					my @cellines=split /%\\n/ , $content;
					for (@cellines){pushout($_);}
					undef @cellines;
				}
				else { pushout($content);}
				$content='';
				pushout("</item>");
				$inline=0;
			}
			else {
				pushout($_);
			}
		}

	}
	endpass();
}


#  _____     _     _           
# |_   _|_ _| |__ | | ___  ___ 
#   | |/ _` | '_ \| |/ _ \/ __|
#   | | (_| | |_) | |  __/\__ \
#   |_|\__,_|_.__/|_|\___||___/
# 
sub tablepass {
	$passname='tablepass';
	my $intable=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^	/){
			if ($intable==0){
				pushout("<table>");
				$intable=1;
			}
			s/^	//;
			my @row=split '	';
			pushout("<row>");
			my $cellopen='';
			for (@row) {
				my $content=$_;
				$cellopen='<cell';
				if ($content=~/<rs=([0-9]+)>/){
					$cellopen="$cellopen rowspan=$1";
				}
				if ($content=~/<cs=([0-9]+)>/){
					$cellopen="$cellopen colspan=$1";
				}
				$content=~s/<[rc]s=[0-9]+>//;
				pushout ("$cellopen>");
				if ($content=~/%\\n/){
					my @cellines=split /%\\n/ , $content;
					for (@cellines){pushout($_);}
					undef @cellines;
				}
				else { pushout($content);}
				pushout ("</cell>");
			}
			pushout("</row>");
		}
		else {
			if ($intable==1){
				pushout("</table>");
				$intable=0;
			}
			pushout($_);
		}
	}
	endpass();
}

#                _       __ _ _      
#   ___ ___   __| | ___ / _(_) | ___ 
#  / __/ _ \ / _` |/ _ \ |_| | |/ _ \
# | (_| (_) | (_| |  __/  _| | |  __/
#  \___\___/ \__,_|\___|_| |_|_|\___|
# 
sub codefilepass {
	$passname='codefilepass';
	my $inlst=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.codefile (.*)/){
			if (open (my $CODEFILE,'<',$1)){
				pushout("<block>");
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				my $blockname="$variables{'filename'}.$variables{'blocknumber'}";
				progress();
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout('"lst"'); pushout("</type>");
				pushout("<text>");
				while (<$CODEFILE>){
					chomp;
					pushout("\"$_\"");
				}
				pushout("</text>");
				pushout("</block>");
			}
			else {
				pushout("FILE: $1");
			}
		}
		else {
			pushout($_);
		}

	}
	endpass();
}



#  _ _     _   _                 
# | (_)___| |_(_)_ __   __ _ ___ 
# | | / __| __| | '_ \ / _` / __|
# | | \__ \ |_| | | | | (_| \__ \
# |_|_|___/\__|_|_| |_|\__, |___/
#                      |___/ 

sub lstpass {
	$passname='lstpass';
	my $inlst=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.lst/){
			if ($inlst==0){
				pushout("<block>");
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				my $blockname="$variables{'filename'}.$variables{'blocknumber'}";
				progress();
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout('"lst"'); pushout("</type>");
				pushout("<text>");
			}
			$inlst=1;
			s/^\.lst//;  # in two substitute, because of empty ,lst lines
			s/^ //;
			pushout("\"$_\"");
		}
		else {

			if ($inlst>0){
				pushout("</text>");
				pushout("</block>");
			}
			$inlst=0;
			pushout($_);
		}

	}
	endpass();
}
#                                              _         
#  _ __   __ _ _ __ __ _  __ _ _ __ __ _ _ __ | |__  ___ 
# | '_ \ / _` | '__/ _` |/ _` | '__/ _` | '_ \| '_ \/ __|
# | |_) | (_| | | | (_| | (_| | | | (_| | |_) | | | \__ \
# | .__/ \__,_|_|  \__,_|\__, |_|  \__,_| .__/|_| |_|___/
# |_|                    |___/          |_|  
#
sub parapass{
	$passname='parapass';
	my $construct='';
	my @parablock;
	my @leftnote;
	my @sidenote;
	my $inpara=0;
	my $level=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if ($inpara==0){
			if (/^<(.*)>$/){	# Anything that is already handled is seen as a 
								# stand-alone construct. That may be a problem for 
								# inline's at the beginning of a paragaph.
				my $match=$1;
				if ($level==0){
					$construct=$match;
					$level++;
					pushout($_);
				}
				elsif ("$construct" eq $match){
					$level++;
					pushout($_);
				}
				elsif ("/$construct" eq $match){
					$level--;
					if ($level<=0){
						$construct='';
					}
					pushout($_);
				}
				else {
					pushout($_);
				}
			} #end  <> in the inputline
			elsif (/^$/){
					pushout($_);
				}
			else {
				if ($level==0){
					$inpara=1;
					push @parablock,$_;
				}
				else {
					$inpara=0;
					pushout($_);
				}
			}
		}
		else { 							# Inpara==1 ; we've detected a paragraph block 
			if (/^[ 	]*$/){			# Empty line marks the end of a paragraph
				if ($#parablock>=0){	# paragraph-block is not empty
					# Collect all side and left notes from the paragraph block
					for (@parablock){
						if (/^([\w?,. ;:]+)\t.*/){
							push @leftnote,$1;
							s/^([\w?,. ;:]+)\t//;
						}
						if (/^\.side (.*)/){
							push @sidenote,$1;
						}
					}
					pushout('<paragraph>');
					if ($#leftnote>=0){
						pushout('<leftnote>');
						for (@leftnote){ pushout($_);}
						pushout('</leftnote>');
					}
					if ($#sidenote>=0){
						pushout('<sidenote>');
						for (my $i=0; $i<=$#sidenote;$i++){
							my $ref=$variables{'sideref'};
							my $j=$i+1;
							my $a=('a' .. 'z' )[$i];
							my $A=('A' .. 'Z' )[$i];
							$ref=~s/%NUM/$j/;
							$ref=~s/%alpha/$a/;
							$ref=~s/%ALPHA/$A/;
							pushout("$ref$sidenote[$i]$variables{'sidesep'}");
						}
						pushout('</sidenote>');
					}
					pushout('<text>');
					my $j=1;
					for (@parablock){
						my $mx=$#passout;
						if (/^\w+\t(.*)/){
							pushout($1);
						}
						elsif (/^\.side (.*)/){
							my $ref=$variables{'sidechar'};
							my $a=('a' .. 'z' )[$j-1];
							my $A=('A' .. 'Z' )[$j-1];
							$ref=~s/%NUM/$j/;
							$ref=~s/%alpha/$a/;
							$ref=~s/%ALPHA/$A/;
							$j=$j+1;
							$passout[$mx]="$passout[$mx]$ref";
						}
						else {
							pushout($_);
						}
					}
					pushout('</text>');
					pushout('</paragraph>');
					undef @parablock;
					undef @sidenote;
					undef @leftnote;
					$inpara=0;
				}
				else {		# In paragraph, end of paragraph block, but the block is empty?
							# This should not happen.
					pushout("");
				}
			}
			else {			# In paragraph block, not an end-of-paragraph (not ^$)
				push @parablock,$_;
			}
		}
	}
	endpass();
}
#                                           _       
#   ___ ___  _ __ ___  _ __ ___   ___ _ __ | |_ ___ 
#  / __/ _ \| '_ ` _ \| '_ ` _ \ / _ \ '_ \| __/ __|
# | (_| (_) | | | | | | | | | | |  __/ | | | |_\__ \
#  \___\___/|_| |_| |_|_| |_| |_|\___|_| |_|\__|___/
#
sub commentpass {
	$passname='commentpass';
	if ($passin[0]=~/#!(.*)/){
		$passin[0]="<!-- $1 -->";
	}
	for (@passin){
		my $line=$_;
		varset($line);
		$lineindex++;
		if (/^#--(.*)/){
			pushout("<!-- $1 -->");
		}
		else {
			pushout($_);
		}
	}
	endpass();
}
#  _             _                       __                            _   
# (_)_ __       | |_ _   _ _ __   ___   / _| ___  _ __ _ __ ___   __ _| |_ 
# | | '_ \ _____| __| | | | '_ \ / _ \ | |_ / _ \| '__| '_ ` _ \ / _` | __|
# | | | | |_____| |_| |_| | |_) |  __/ |  _| (_) | |  | | | | | | (_| | |_ 
# |_|_| |_|      \__|\__, | .__/ \___| |_|  \___/|_|  |_| |_| |_|\__,_|\__|
#                    |___/|_| 
sub formatpass {
	$passname='formatpass';
	for (@passin){
		my $line=$_;
		varset($line);
		$lineindex++;
		if (/^\.fix (.*)/){pushout('<fixed>'); pushout($1); pushout('</fixed>'); }
		elsif ($line=~/^\.fixed (.*)/){pushout('<fixed>'); pushout($1); pushout('</fixed>'); }
		elsif ($line=~/^\.center (.*)/){pushout('<center>'); pushout($1); pushout('</center>'); }
		elsif ($line=~/^\.underline (.*)/){pushout('<underline>'); pushout($1); pushout('</underline>'); }
		elsif ($line=~/^\.u (.*)/){pushout('<underline>'); pushout($1); pushout('</underline>'); }
		elsif ($line=~/^\.bold (.*)/){pushout('<bold>'); pushout($1); pushout('</bold>'); }
		elsif ($line=~/^\.b (.*)/){pushout('<bold>'); pushout($1); pushout('</bold>'); }
		elsif ($line=~/^\.i (.*)/){pushout('<italic>'); pushout($1); pushout('</italic>'); }
		elsif ($line=~/^\.italic (.*)/){pushout('<italic>'); pushout($1); pushout('</italic>'); }
		elsif ($line=~/^\.sub (.*)/){pushout('<subscript>'); pushout($1); pushout('</subscript>'); }
		elsif ($line=~/^\.sup (.*)/){pushout('<superscript>'); pushout($1); pushout('</superscript>'); }
		elsif ($line=~/^\.br/){pushout('<break>'); pushout('</break>'); }
		elsif ($line=~/^\.link (\S*) (.*)/){
			pushout('<link>');
			pushout('<target>');
			pushout("\"$1\"");
			pushout('</target>');
			pushout('<text>');
			pushout("\"$2\"");
			pushout('</text>');
			pushout('</link>');
		}
		elsif ($line=~/^\.link ([^ ]*)/){
			pushout('<link>');
			pushout('<target>');
			pushout("\"$1\"");
			pushout('</target>');
			pushout('</link>');
		}
		elsif ($line=~/^\.img ([^ ]*)/){
			pushout('<image>');
			pushout('<file>');
			pushout("\"$1\"");
			pushout('</file>');
			pushout('</image>');
		}
		elsif ($line=~/^\.video ([^ ]*)/){
			pushout('<video>');
			pushout('<file>');
			pushout("\"$1\"");
			pushout('</file>');
			pushout('</video>');
		}
		else { pushout($_);}
	}
	endpass();
}
#   __             _               _            
#  / _| ___   ___ | |_ _ __   ___ | |_ ___  ___ 
# | |_ / _ \ / _ \| __| '_ \ / _ \| __/ _ \/ __|
# |  _| (_) | (_) | |_| | | | (_) | ||  __/\__ \
# |_|  \___/ \___/ \__|_| |_|\___/ \__\___||___/
#  
sub footnotepass {
	$passname='footnotepass';
	for (@passin){
		my $line=$_;
		varset($line);
		$lineindex++;
		if (/^\.note (.*)/){
			my $content=$1;
			my $mx=$#passout;
			my $ref=$variables{'notestring'};
			$variables{'notenumber'}++;
			my $j=$variables{'notenumber'};
			my $a=('a' .. 'z' )[$j-1];
			my $A=('A' .. 'Z' )[$j-1];
			$ref=~s/%NUM/$j/;
			$ref=~s/%alpha/$a/;
			$ref=~s/%ALPHA/$A/;
			$passout[$mx]="$passout[$mx]$ref";
			pushout('<note>');
			pushout($ref);
			if ($content=~/%\\n/){
				my @cellines=split /%\\n/ , $content;
				for (@cellines){pushout($_);}
				undef @cellines;
			}
			else { pushout($content);}
			pushout('</note>');
		}
		else { pushout($_);}
	}
	endpass();
}

#      _                  _       _
#  ___| |_ __ _ _ __   __| | __ _| | ___  _ __   ___
# / __| __/ _` | '_ \ / _` |/ _` | |/ _ \| '_ \ / _ \
# \__ \ || (_| | | | | (_| | (_| | | (_) | | | |  __/
# |___/\__\__,_|_| |_|\__,_|\__,_|_|\___/|_| |_|\___|
#
sub standalonepass {	# make images, videos or blocks that occupy a 
	 					# complete paragraph stand-alone
	$passname='standalonepass';
	my @parablock;
	my $inpara=0;
	my $inblk=0;
	my $invideo=0;
	my $inimg=0;
	my $dontstrip=0;
	my $line;
	for (@passin){
		$line=$_;
		varset($line);
		$lineindex++;
		if (/^<paragraph>$/){
			$inpara=1;
			push @parablock,$line;
		}
		elsif ($inpara>0){
			if (/^<\/paragraph>$/){
				push @parablock,$line;
				for (@parablock){
					if (/^<paragraph>/){}
					elsif (/^<.paragraph>/){}
					elsif (/^<text>/){}
					elsif (/^<.text>/){}
					elsif (/^<block>/){ $inblk=1; }
					elsif (/^<.block>/){ $inblk=0; }
					elsif (/^<image>/){ $inimg=1; }
					elsif (/^<.image>/){ $inimg=0; }
					elsif (/^<video>/){ $invideo=1; }
					elsif (/^<.video>/){ $invideo=0; }
					elsif ($inimg+$inblk+$invideo>0){ }
					else {
						$dontstrip=1;
				   	}
				}
				if ($dontstrip==0){
					for (@parablock){
						if (/^<paragraph>/){}
						elsif (/^<.paragraph>/){}
						elsif (/^<text>/){if ($inimg+$inblk+$invideo>0){ pushout($_);}}
						elsif (/^<.text>/){if ($inimg+$inblk+$invideo>0){ pushout($_);}}
						elsif (/^<block>/){ $inblk=1; pushout($_);}
						elsif (/^<.block>/){ $inblk=0; pushout($_);}
						elsif (/^<image>/){ $inimg=1; pushout($_);}
						elsif (/^<.image>/){ $inimg=0; pushout($_);}
						elsif (/^<video>/){ $invideo=1; pushout($_);}
						elsif (/^<.video>/){ $invideo=0; pushout($_);}
						elsif ($inimg+$inblk+$invideo>0){ pushout($_);}
						else { $dontstrip=1; print STDERR "MEUH? dontstrip==0, but 1 anyway?\n";}
					}
				}
				else {
					for (@parablock){
						pushout($_);
					}
				}
				undef @parablock;
				$inpara=0;
				$inblk=0;
				$invideo=0;
				$inimg=0;
				$dontstrip=0;
			}
			else {
				push @parablock,$line;
			}
		}
		else {
			pushout($line);
		}
	}
	endpass();
}

#                  _          _     _            _    
#  _ __ ___   __ _| | _____  | |__ | | ___   ___| | __
# | '_ ` _ \ / _` | |/ / _ \ | '_ \| |/ _ \ / __| |/ /
# | | | | | | (_| |   <  __/ | |_) | | (_) | (__|   < 
# |_| |_| |_|\__,_|_|\_\___| |_.__/|_|\___/ \___|_|\_\
#                                                     
#                  _             _   
#   ___ ___  _ __ | |_ ___ _ __ | |_ 
#  / __/ _ \| '_ \| __/ _ \ '_ \| __|
# | (_| (_) | | | | ||  __/ | | | |_ 
#  \___\___/|_| |_|\__\___|_| |_|\__|
#  
sub blockmakepass {
	$passname='blockmakepass';
	my $inblock=0;
	my $intype=0;
	my $intext=0;
	my $informat=0;
	my $inname=0;
	my $type;
	my @thisblock;
	for (@passin){
		my $blk="block/$variables{'filename'}.$variables{'blocknumber'}";
		my $baseblk="$variables{'blockname'}.$variables{'blocknumber'}";
		my $line=$_;
		varset($line);
		if ($inblock>0){
			if ($inname>0){
				if ($line=~/^<\/name>/) {$inname=0;}
				else {
					$blk=$_;
					$baseblk=basename($blk);
				}
			}
			elsif ($informat>0){
				if ($line=~/^<\/format>/) {$informat=0;}
			}
			elsif ($intype>0){
				if ($line=~/^<\/type>/) {$intype=0;}
				else { $type=$line; $type=~s/^"//; $type=~s/"$//; $type=~s/ .*//; }
			}
			elsif ($intext>0){
				if ($line=~/^<\/text>/) {$intext=0;}
				else { 
					my $t=$line;
					if ($t=~/^"/){
						$t=~s/^"//;
						$t=~s/"$//;
					}
					push @thisblock, $t;
				}
			}
			elsif ($line=~/^<type>/){$intype=1;}
			elsif ($line=~/^<text>/){$intext=1;}
			elsif ($line=~/^<format>/){$informat=1;}
			elsif ($line=~/^<name>/){$inname=1;}
			elsif ($line=~/^<\/block>/){
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				if ($#thisblock>=0){
					if (open (my $BLOCK,'>',"$blk.blk")){
						for (@thisblock){
							print $BLOCK "$_\n";
						}
						close $BLOCK;
					}
					else {
						print STDERR "Cannot open $blk.blk\n";
						$type='none';
					}
				}
				else {
					print STDERR "Block $variables{'blocknumber'} has empty text\n";
					$type='empty';
				}
				if ($type eq 'pre'){
					system ("pango-view --font=mono -qo $blk.png $blk.blk\n");
					pushout('<image>');
					pushout("$blk.png ");
					pushout('</image>');
				}
				elsif ($type eq 'lst'){
					system ("pango-view --font=mono -qo $blk.png $blk.blk\n");
					pushout('<image>');
					pushout("$blk.png ");
					pushout('</image>');
				}
				elsif ($type=~/^class/){
					system ("pango-view --font=mono -qo $blk.png $blk.blk\n");
					pushout('<image>');
					pushout("$blk.png ");
					pushout('</image>');
				}
			    elsif ($type eq 'eqn'){
					my $density=1000;
					if (open my $EQN, '>',"$blk.eqn"){
						print $EQN ".EQ\n";
						for (@thisblock){
							print $EQN "$_\n";
						}
						print $EQN ".EN\n";
						close $EQN;
						system ("eqn $blk.eqn > $blk.groff");
						system ("groff $blk.groff > $blk.ps");
						system ("ps2pdf $blk.ps $blk.pdf");
						system ("convert -trim -density $density $blk.pdf $blk.png");
						pushout('<image>');
						pushout("$blk.png ");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.eqn\n"; }

				}
			    elsif ($type eq 'pic'){
					my $density=1000;
					if (open my $PIC, '>',"$blk.pic"){
						print $PIC ".PS\n";
						for (@thisblock){
							print $PIC "$_\n";
						}
						print $PIC ".PE\n";
						close $PIC;
						system ("pic $blk.pic > $blk.groff");
						system ("groff $blk.groff > $blk.ps");
						system ("ps2pdf $blk.ps $blk.pdf");
						system ("convert -trim -density $density $blk.pdf $blk.png");
						pushout('<image>');
						pushout("$blk.png ");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.pic\n"; }

				}
			    elsif ($type eq 'gnuplot'){
					if (open (my $GNUPLOT, '>',"$blk.gnuplot")){
						print $GNUPLOT "set terminal png size 800,800 enhanced font \"Helvetica,8\"";
						print $GNUPLOT "\nset output '$blk.png'\n";
						for (@thisblock){
							print $GNUPLOT "$_\n";
						}
						close $GNUPLOT;
						system("gnuplot $blk.gnuplot");
						pushout('<image>');
						pushout("$blk.png");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.gnuplot\n"; }


				}
			    elsif ($type eq 'music'){
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
						for (@thisblock){
							print $MUSIC "$_\n";
						}
						print $MUSIC "}\n";
						close $MUSIC;
						system ("lilypond --png  -dresolution=500  $blk.ly");
						system ("cp $baseblk.png $blk.png");
						system ("convert -trim $blk.png $blk.tmp.png");
						system ("mv $blk.tmp.png $blk.png");
						pushout('<image>');
						pushout("$blk.png");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.ly\n"; }
				}
			    elsif ($type eq 'texeqn'){
					my $density='1000x1000';
					if (open (my $TEXEQN,'>',"$blk.tex")){
						print $TEXEQN "\\documentclass{article}\n";
						print $TEXEQN "\\usepackage{amsmath}\n";
						print $TEXEQN "\\usepackage{amssymb}\n";
						print $TEXEQN "\\usepackage{algorithm2e}\n";
						print $TEXEQN "\\begin{document}\n";
						print $TEXEQN "\\begin{titlepage}\n";
						print $TEXEQN "\\begin{equation*}\n";
						for (@thisblock){
							print $TEXEQN "$_\n";
						}
						print $TEXEQN "\\end{equation*}\n";
						print $TEXEQN "\\end{titlepage}\n";
						print $TEXEQN "\\end{document}\n";
						close $TEXEQN;
						system("cd block; echo '' | latex $baseblk.tex > /dev/null 2>/dev/null");
						#system("convert  -trim  -density $density $blk.dvi $blk.png");
						system("dvipng -o $blk.png -D $density  $blk.dvi ");
						pushout('<image>');
						pushout("$blk.png");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.tex\n";}
				}
				else {
					print STDERR "Unhandled block type='$type':\n";
					# for (@thisblock){
					# print STDERR "    $_\n";
					# }
				}
				undef @thisblock;
				$inblock=0;
				$type='none';
			}
			pushout($line);
		}
		elsif ($line=~/^<block>/){			
			pushout($line);
			$inblock=1;
			$type='pre';
			undef @thisblock;
		}
		else {
			pushout($line);
		}
	}
	endpass();
}



$lineindex=-1;
includepass();
depricatepass();
markdownpass(); progress;
blockpass(); progress;
inlinepass(); progress;
listpass(); progress;
tablepass(); progress;
blockpass(); progress;
inlinepass(); progress;
lstpass(); progress;
headingpass(); progress;
codefilepass(); progress;
mappass(); progress;
parapass(); progress;
hrpass(); progress;
tocpass(); progress;
footnotepass(); progress;
mdformatpass(); progress;
formatpass(); progress;

varpass(); progress;
standalonepass(); progress;
commentpass(); progress;
# blockmakepass();
print "<in3xml>\n";
for (@passin){
	print "$_\n";
}
print "</in3xml>\n";

