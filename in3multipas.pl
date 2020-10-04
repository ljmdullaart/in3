#!/usr/bin/perl
#


my @input=<>;

my @passin;
my @passout;


for (@input){
	chomp;
	if (/^\.$/){	#deprecated
		push @passin,'';
	}
	else {
		push @passin,$_;
	}
}

sub endpass {
	undef @passin;
	@passin=@passout;
	undef @passout;
}
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



sub varset{
	(my $line)=@_;
	if (/^\.title *(.*)/){
		$variables{'title'}=$1;
	}
	elsif (/^\.subtitle *(.*)/){
		$variables{'subtitle'}=$1;
	}
	elsif (/^\.cover *(.*)/){
		$variables{'cover'}=$1;
	}
	elsif (/^\.author *(.*)/){
		$variables{'author'}=$1;
	}
	elsif (/^\.keywords *(.*)/){
		$variables{'keywords'}=$1;
	}
	elsif (/^\.appendix/){
		$variables{'appendix'}=1;
	}
	elsif (/^\.back/){
		$variables{'back'}=1;
	}
	elsif (/^\.set *([\w]+) *(.*)/){
		$variables{$1}=$2;
	}
}
sub varpush{
	(my $var,my $val)=@_;
	push @passout,'<set>';
	push @passout,'<variable>';
	push @passout,$var;
	push @passout,'</variable>';
	push @passout,'<value>';
	push @passout,$val;
	push @passout,'</value>';
	push @passout,'</set>';
}

sub varpass{
	for (@passin){
		if (/^\.title *(.*)/){ varpush('title',$1); }
		elsif (/^\.subtitle *(.*)/){ varpush('subtitle',$1); }
		elsif (/^\.keywords *(.*)/){ varpush('keywords',$1); }
		elsif (/^\.cover *(.*)/){ varpush('cover',$1); }
		elsif (/^\.author *(.*)/){ varpush('author',$1); }
		elsif (/^\.appendix *(.*)/){ varpush('appendix',1); }
		elsif (/^\.back *(.*)/){ varpush('back',1); }
		elsif (/^\.set *([\w]+) *(.*)/){ varpush($1,$2); }
		elsif (/^\.dumpvar (.*)/){ push @passout,$variables{$1};}
		elsif (/^\.dumpvar/){
			push @passout,'<block>';
			push @passout,'<type>';
			push @passout,'"lst"';
			push @passout,'</type>';
			push @passout,'<text>';
			for (keys %variables){
				push @passout,"$_=$variables{$_}"
			}
			push @passout,'</text>';
			push @passout,'</block>';
		}
		else { push @passout,$_; }
	}
	endpass();
}

sub mappass {
	my $inmap=0;
	for (@passin){
		varset($_);
		if ($inmap==0){
			if (/^\.map/){
				push @passout,'<map>';
				$inmap=1;
				if (/^\.map image (.*)/){
					push @passout,'<file>';
					push @passout,$1;
					push @passout,'</file>';
				}
				elsif (/^\.map field ([^ ]+) ([,0123456789]+)/){
					push @passout,'<field>';
					push @passout,'<target>';
					push @passout,$1;
					push @passout,'</target>';
					push @passout,'<coord>';
					push @passout,$2;
					push @passout,'</coord>';
					push @passout,'</field>';
				}
			}
			else { push @passout,$_; }
		}
		else {
			if (/^\.map image (.*)/){
				push @passout,'<file>';
				push @passout,$1;
				push @passout,'</file>';
			}
			elsif (/^\.map field ([^ ]+) ([,0123456789]+)/){
				push @passout,'<field>';
				push @passout,'<target>';
				push @passout,$1;
				push @passout,'</target>';
				push @passout,'<coord>';
				push @passout,$2;
				push @passout,'</coord>';
				push @passout,'</field>';
			}
			else {
				push @passout,'</map>';
				push @passout,$_;
				$inmap=0;
			}
		}
	}
	endpass();
}





# pass: blocks
sub blockpass {
	my $inblk=0;
	my $inpre=0;
	my @thisblock;
	for (@passin){
		varset($_);
		my $line=$_;
		if ($inblk+$inpre==0){
			if ($line=~/^\.block (.*)/){
				push @passout,"<block>";
				push @passout,"<type>"; push @passout,"\"$1\""; push @passout,"</type>";
				$inblk=1;
				undef @thisblock;
			}
			elsif ($line=~/^\.pre/){
				push @passout,"<block>";
				push @passout,"<type>"; push @passout,'"pre"'; push @passout,"</type>";
				$inpre=1;
				undef @thisblock;
			}
			else { push @passout,$line; }
		}
		elsif ($inpre==1){
			if ($line=~/^\.pre/){
				push @passout,"<text>";
				for (@thisblock){
					push @passout,"\"$_\"";
				}
				push @passout,"</text>";
				push @passout,"</block>";
				$inpre=0;
			}
			else { push @thisblock,$line; }
		}
		elsif ($inblk==1){
			if (/^\.block format (.*)/){
				push @passout,"<format>"; push @passout,"\"$1\""; push @passout,"</format>";
			}
			elsif (/^\.block/){
				push @passout,"<text>";
				for (@thisblock){
					push @passout,"\"$_\"";
				}
				push @passout,"</text>";
				push @passout,"</block>";
				$inblk=0;
			}
			else { push @thisblock,$line; }
		}
	}
	endpass();
}

sub inlinepass {
	for (@passin){
		varset($_);
		if (/^\.inline ([a-z]+) (.*)/){
			push @passout,"<block>";
			push @passout,"<type>";
			push @passout,"\"$1\"";
			push @passout,"</type>";
			push @passout,"<text>";
			push @passout,"\"$2\"";
			push @passout,"</text>";
			push @passout,"</block>";
		}
		else { push @passout,$_; }
	}
	endpass();
}


sub headingpass {
	for (@passin){
		varset($_);
		if (/^\.h([0-9]) (.*)/){
			push @passout,"<heading>";
			push @passout,"<level>";
			push @passout,"\"$1\"";
			push @passout,"</level>";
			push @passout,"<text>";
			push @passout,"\"$2\"";
			push @passout,"</text>";
			push @passout,"</heading>";
			push @passout,"";
		}
		else { push @passout,$_; }
	}
	endpass();
}

sub hrpass {
	for (@passin){
		varset($_);
		if (/^\.hr/){
			push @passout,"<hr>";
			push @passout,"</hr>";
		}
		elsif (/^\.P/){
			push @passout,"<blank>";
			push @passout,"</blank>";
		}
		else {
			push @passout,$_;
		}
	}
	endpass();
}

sub tocpass {
	for (@passin){
		varset($_);
		if (/^\.toc[0-9]* (.*)/){
			push @passout,"<toc>";
			push @passout,$1;
			push @passout,"</toc>";
		}
		elsif (/^\.toc/){
			push @passout,"<toc>";
			push @passout,"</toc>";
		}
		else {
			push @passout,$_;
		}
	}
	endpass();
}


sub listpass {
	my $listlevel=0;
	my $newlevel=0;
	for (@passin){
		varset($_);
		if (/^(	*)([-@#])[ 	]+(.*)/){
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
				push @passout,"<list>";
				push @passout,"<type>";
				push @passout,"\"$listtype\"";
				push @passout,"</type>";
				$listlevel=$newlevel;
			}
			elsif($newlevel<$listlevel){
				push @passout,"</list>";
				$listlevel=$newlevel;
			}
			push @passout,"<item>";
			if ($content=~/%\\n/){
				my @cellines=split /%\\n/ , $content;
				for (@cellines){push @passout,$_;}
				undef @cellines;
			}
			else { push @passout,$content;}
			push @passout,"</item>";
		}
		elsif (/^$/){
			while ($listlevel >0){
				push @passout,'</list>';
				$listlevel--;
			}
			$listlevel=0;
			$newlevel=0;
			 
			push @passout,$_;
		}
		else {
			if ($listlevel>0){
				my $max=$#passout;
				pop @passout;
				if ($content=~/%\\n/){
					my @cellines=split /%\\n/ , $content;
					for (@cellines){push @passout,$_;}
					undef @cellines;
				}
				else { push @passout,$content;}
				push @passout,"</item>";
			}
			else {
				push @passout,$_;
			}
		}

	}
	endpass();
}





sub tablepass {
	my $intable=0;
	for (@passin){
		varset($_);
		if (/^	/){
			if ($intable==0){
				push @passout,"<table>";
				$intable=1;
			}
			s/^	//;
			my @row=split '	';
			push @passout,"<row>";
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
				push  @passout,"$cellopen>";
				if ($content=~/%\\n/){
					my @cellines=split /%\\n/ , $content;
					for (@cellines){push @passout,$_;}
					undef @cellines;
				}
				else { push @passout,$content;}
				push  @passout,"</cell>";
			}
			push @passout,"</row>";
		}
		else {
			if ($intable==1){
				push @passout,"</table>";
				$intable=0;
			}
			push @passout,$_;
		}
	}
	endpass();
}


sub codefilepass {
	my $inlst=0;
	for (@passin){
		varset($_);
		if (/^\.codefile (.*)/){
			if (open (my $CODEFILE,'<',$1)){
				push @passout,"<block>";
				push @passout,"<type>"; push @passout,'"lst"'; push @passout,"</type>";
				push @passout,"<text>";
				while (<$CODEFILE>){
					chomp;
					push @passout,"\"$_\"";
				}
				push @passout,"</text>";
				push @passout,"</block>";
			}
			else {
				push @passout,"FILE: $1";
			}
		}
		else {
			push @passout,$_;
		}

	}
	endpass();
}





sub lstpass {
	my $inlst=0;
	for (@passin){
		varset($_);
		if (/^\.lst/){
			if ($inlst==0){
				push @passout,"<block>";
				push @passout,"<type>"; push @passout,'"lst"'; push @passout,"</type>";
				push @passout,"<text>";
			}
			$inlst=1;
			s/^\.lst//;
			s/^ //;
			push @passout,"\"$_\"";
		}
		else {

			if ($inlst>0){
				push @passout,"</text>";
				push @passout,"</block>";
			}
			$inlst=0;
			push @passout,$_;
		}

	}
	endpass();
}

sub parapass{
	my $construct='';
	my @parablock;
	my @leftnote;
	my @sidenote;
	my $inpara=0;
	for (@passin){
		varset($_);
		if ($inpara==0){
			if (/^<(.*)>$/){
				if ($construct eq ''){
					$construct=$1;
					push @passout,$_;
				}
				elsif ("/$construct" eq $1){
					$construct='';
					push @passout,$_;
				}
				else {
					push @passout,$_;
				}
			}
			elsif (/^$/){
					push @passout,$_;
				}
			else {
				if ($construct eq ''){
					$inpara=1;
					push @parablock,$_;
				}
				else {
					$inpara=0;
					push @passout,$_;
				}
			}
		}
		else {
			if (/^$/){
				for (@parablock){
					if (/^(\w+)\t.*/){
						push @leftnote,$1;
					}
					if (/^\.side (.*)/){
						push @sidenote,$1;
					}
				}
				if ($#parablock>=0){
					push @passout,'<paragraph>';
					if ($#leftnote>=0){
						push @passout,'<leftnote>';
						for (@leftnote){ push @passout,$_;}
						push @passout,'</leftnote>';
					}
					if ($#sidenote>=0){
						push @passout,'<sidenote>';
						for (my $i=0; $i<=$#sidenote;$i++){
							my $ref=$variables{'sideref'};
							my $j=$i+1;
							my $a=('a' .. 'z' )[$i];
							my $A=('A' .. 'Z' )[$i];
							$ref=~s/%NUM/$j/;
							$ref=~s/%alpha/$a/;
							$ref=~s/%ALPHA/$A/;
							push @passout,"$ref$sidenote[$i]$variables{'sidesep'}";
						}
						push @passout,'</sidenote>';
					}
					if ($#parablock>=0){
						push @passout,'<text>';
						my $j=1;
						for (@parablock){
							my $mx=$#passout;
							if (/^\w+\t(.*)/){
								push @passout,$1;
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
								push @passout,$_;
							}
						}
						push @passout,'</text>';
					}
					push @passout,'</paragraph>';
					undef @parablock;
					undef @sidenote;
					undef @leftnote;
					$inpara=0;
				}
				else {
					push @passout,"";
				}
			}
			else { push @parablock,$_;}
		}
	}
	endpass();
}

sub formatpass {
	for (@passin){
		my $line=$_;
		varset($line);
		if (/^\.fix (.*)/){push @passout,'<fixed>'; push @passout,$1; push @passout,'</fixed>'; }
		elsif ($line=~/^\.fixed (.*)/){push @passout,'<fixed>'; push @passout,$1; push @passout,'</fixed>'; }
		elsif ($line=~/^\.center (.*)/){push @passout,'<center>'; push @passout,$1; push @passout,'</center>'; }
		elsif ($line=~/^\.underline (.*)/){push @passout,'<underline>'; push @passout,$1; push @passout,'</underline>'; }
		elsif ($line=~/^\.u (.*)/){push @passout,'<underline>'; push @passout,$1; push @passout,'</underline>'; }
		elsif ($line=~/^\.bold (.*)/){push @passout,'<bold>'; push @passout,$1; push @passout,'</bold>'; }
		elsif ($line=~/^\.b (.*)/){push @passout,'<bold>'; push @passout,$1; push @passout,'</bold>'; }
		elsif ($line=~/^\.i (.*)/){push @passout,'<italic>'; push @passout,$1; push @passout,'</italic>'; }
		elsif ($line=~/^\.italic (.*)/){push @passout,'<italic>'; push @passout,$1; push @passout,'</italic>'; }
		elsif ($line=~/^\.sub (.*)/){push @passout,'<subscript>'; push @passout,$1; push @passout,'</subscript>'; }
		elsif ($line=~/^\.sup (.*)/){push @passout,'<superscript>'; push @passout,$1; push @passout,'</superscript>'; }
		elsif ($line=~/^\.br/){push @passout,'<break>'; push @passout,'</break>'; }
		elsif ($line=~/^\.link ([^ ]*) (.*)/){
			push @passout,'<link>';
			push @passout,'<target>';
			push @passout,"\"$1\"";
			push @passout,'</target>';
			push @passout,'<text>';
			push @passout,"\"$2\"";
			push @passout,'</text>';
			push @passout,'</link>';
		}
		elsif ($line=~/^\.link ([^ ]*)/){
			push @passout,'<link>';
			push @passout,'<target>';
			push @passout,"\"$1\"";
			push @passout,'</target>';
			push @passout,'</link>';
		}
		elsif ($line=~/^\.img ([^ ]*)/){
			push @passout,'<image>';
			push @passout,'<file>';
			push @passout,"\"$1\"";
			push @passout,'</file>';
			push @passout,'</image>';
		}
		elsif ($line=~/^\.video ([^ ]*)/){
			push @passout,'<video>';
			push @passout,'<file>';
			push @passout,"\"$1\"";
			push @passout,'</file>';
			push @passout,'</video>';
		}
		else { push @passout,$_;}
	}
	endpass();
}

sub footnotepass {
	for (@passin){
		if (/^\.note (.*)/){
			my $content=$1;
			my $mx=$#passout;
			my $ref=$variables{'notestring'};
			$variables{'notenumber'}++;
			my $j=$variables{'notenumber'};
			my $ref=$variables{'sidechar'};
			my $a=('a' .. 'z' )[$j-1];
			my $A=('A' .. 'Z' )[$j-1];
			$ref=~s/%NUM/$j/;
			$ref=~s/%alpha/$a/;
			$ref=~s/%ALPHA/$A/;
			$passout[$mx]="$passout[$mx]$ref";
			push @passout,'<note>';
			push @passout,$ref;
			if ($content=~/%\\n/){
				my @cellines=split /%\\n/ , $content;
				for (@cellines){push @passout,$_;}
				undef @cellines;
			}
			else { push @passout,$content;}
			push @passout,'</note>';
		}
		else { push @passout,$_;}
	}
	endpass();
}

sub standalonepass {	# make images, videos or blocks that occupy a 
	 					# complete paragraph stand-alone
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
						elsif (/^<text>/){}
						elsif (/^<.text>/){}
						elsif (/^<block>/){ $inblk=1; push @passout,$_;}
						elsif (/^<.block>/){ $inblk=0; push @passout,$_;}
						elsif (/^<image>/){ $inimg=1; push @passout,$_;}
						elsif (/^<.image>/){ $inimg=0; push @passout,$_;}
						elsif (/^<video>/){ $invideo=1; push @passout,$_;}
						elsif (/^<.video>/){ $invideo=0; push @passout,$_;}
						elsif ($inpara+$inblk+$invideo>0){ push @passout,$_;}
						else { $dontstrip=1; print STDERR "MEUH? dontstrip==0, but 1 anyway?\n";}
					}
				}
				else {
					for (@parablock){
						push @passout,$_;
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
			push @passout,$line;
		}
	}
	endpass();
}





blockpass();
listpass();
tablepass();
blockpass();
lstpass();
headingpass();
codefilepass();
mappass();
parapass();
hrpass();
tocpass();
footnotepass();
inlinepass();
formatpass();

varpass();
standalonepass;

for (@passin){
	print "$_\n";
}
