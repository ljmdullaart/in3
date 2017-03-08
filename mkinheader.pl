#!/usr/bin/perl
#INSTALL@ /usr/local/bin/mkinheader
use strict;
use warnings;

use Cwd qw();

sub hellup {
print "
mkinheader: make header/index file for in3
--help           This help
-h  --header     create an includebla header
-i  --index      create an index-file
-t               Don't include the total
-v               increase verbosity
";
}


my $VERBOSE=0;

my $type='header';		# Type of output to produce
my $do_total=1;			# Include the "total" file in the header/index
my $WD = Cwd::cwd();		# Basename of the current working directory
$WD=~s/.*\///;
my $all_in;				# A space-separated list of al .in files
my @in;				# all relevant lines from the in-files

for (@ARGV){
	chomp;
	if (/^$/){ $type='header';}
	elsif (/--help/){
		hellup;
	}
	elsif (/--header/){
		$type='header';
	}
	elsif (/-h/){
		$type='header';
	}
	elsif (/--index/){
		$type='index';
	}
	elsif (/-i/){
		$type='index';
	}
	elsif (/-t/){
		$do_total=0;
	}
	elsif (/-v/){$VERBOSE++;}
	else { print "$_; Unknown option $_.\n";}
}
	
if ($VERBOSE > 0){ print "######## type=$type\n";}
if ($do_total==1){
	$all_in=`ls *.in| sort -n | paste -sd ' '`;
}
else{
	$all_in=`ls *.in|egrep -v 'total.in' | sort -n| paste -sd ' '`;
}
chomp $all_in;

if ($VERBOSE > 0){ print "########all_in=$all_in=\n";}

if (open(IN,"egrep '^\.h[123] |\.toc|^.author|^.title|^.subtitle' $all_in  |")){
	@in=<IN>;
	close IN;
}
else {
	die 'Cannot grep .in-files';
}

my $tot_title='';
my $sub_title='';
my $author='';

for (@in){
	if (/in:.title (.*)/){ $tot_title=$1; }
	if (/in:.subtitle (.*)/){ $sub_title="$sub_title<br>$1"; }
	if (/in:.author (.*)/){ $author=$1;}
}

if ($type eq 'header'){
#	if ($tot_title ne 'Index' ){print "<h1>$tot_title</h1>\n";}
#	if ($sub_title ne '' ){print "<h2>$sub_title</h2>\n";}
#	if ($author ne ''){print "<h3>$author</h3>\n";}
}
elsif ($type eq 'index'){
	if (( -d 'pdf' ) && ($do_total==1)) {
		print ".link total.pdf (pdf)\n";
	}
	if (( -d 'epub' ) && ($do_total==1)){
		print ".link $WD.epub (epub)\n";
	}
	if (( -d 'www' ) && ($do_total==1)){
		print ".link total.html (1 page)\n";
	}
	if ($tot_title ne '' ){print ".title $tot_title\n";}
	if ($sub_title ne '' ){print ".subtitle $sub_title\n";}
	if ($author ne ''){print ".author $author\n";}
	if ( -f "index.top"){
		if (open(IT,"index.top")){
			while (<IT>){print;}
			close IT;
		}
	}
}

if ($type eq 'header'){print "<table CLASS=\"toc\">\n";}
if ($type eq 'header'){print "	<tr class=toc><td colspan=3><a href=\"index.html\"><span CLASS=toc>Index</span></a></td></tr>\n"; }
my $prev_c=0;
my $s=0;
my $p=0;
for (@in){
	chomp;
	if ($type eq 'header'){
		s/  /&nbsp;&nbsp/g;
		s/û/&ucirc;/g;
		s/<p.*>/<p>/g;
		s/\&nbsp\;/ /g;
		s/[«]/"/g;
		s/[»]/"/g;
		s/""/"/g;
		s/’/'/g;
		s/Ã/&Acirc;/g;
		s/À/&Agrave;/g;
		s/â/&acirc;/g;
		s/à/&agrave;/g;
		s/Ç/&Ccedil;/g;
		s/ç/&ccedil;/g;
		s/É/&Eacute;/g;
		s/È/&Egrave;/g;
		s/Ê/&Ecirc;/g;
		s/é/&eacute;/g;
		s/è/&egrave;/g;
		s/ê/&ecirc;/g;
		s/ë/&euml;/g;
		s/î/&icirc;/g;
		s/ï/&iuml;/g;
		s/œ/&oelig;/g;
		s/Ô/&Ocirc;/g;
		s/ô/&ocirc;/g;
		s/Û/&Ucirc;/g;
		s/Ù/&Ugrave;/g;
		s/ù/&ugrave;/g;
		s/û/&uuml;/g;
		s/±/&plusmn;/g;
	}
	my $c;
	if (/^index/){ $prev_c=0;}
	if (/^total/){ $prev_c=0;}
	elsif (/^([0-9]*)_(.*).in:.h([123]) (.*)/){
		$c=$1;
		my $file="$1_$2.html";
		my $pdf="$1_$2.pdf";
		my $level=$3;
		my $title=$4;
if ($VERBOSE>0){print "#chapter:$c file:$file level:$level title:$title\n";}
		if ($c != $prev_c){ $s=0; $p=0; $prev_c=$c; }
		if ($level==1){
			if ($type eq 'header'){
 				print "	<tr class=toc><td colspan=3><a href=\"$file#a$c\">";
				print "<span CLASS=toc> $c $title</span></a></td></tr>\n";
			}
			if ($type eq 'index'){print "\n.br\n.link $file#a$c. $c $title\n";}
		}
		elsif ($level==2){
			$s++; $p=0;
#			if ($type eq 'header'){ print "	<tr class=toc><td>&nbsp;</td><td colspan=2><a href=\"$file#a$c.$s\"><span CLASS=toc>$c.$s $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print "\n.br\n.link $file#a$c.$s. $c.$s $title\n";}
		}
		elsif ($level==3){
			$p++;
#			if ($type eq 'header'){ print "	<tr class=toc><td>&nbsp;</td><td>&nbsp;</td><td><a href=\"$file#a$c.$s.$p\"><span CLASS=toc>$c.$s.$p $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print "\n.br\n.link $file#a$c.$s.$p. $c.$s.$p $title\n";}
		}
	}
	elsif (/(.*).in:\.h([123]) (.*)/){
		my $file="$1.html";
		my $level=$2;
		my $title=$3;
		if ($level==1){
			$c++;
			if ($c != $prev_c){ $s=0; $p=0; $prev_c=$c; }
			if ($type eq 'header'){ print "	<tr class=toc><td colspan=3><a href=\"$file#a$c\"><span CLASS=toc> $c $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print "\n.br\n.link $file#a$c $c $title\n";}
		}
		elsif ($level==2){
			$s++; $p=0;
			if ($type eq 'index'){print "\n.br\n.link $file#a$c.$s $c.$s $title\n";}
		}
		elsif ($level==3){
			$p++;
			if ($type eq 'index'){print "\n.br\n.link $file#a$c.$s.$p $c.$s.$p $title\n";}
		}
	}
	elsif (/.in:\.toc([123])/){
		my $level=$1;
		s/.*\.toc.//;
		if  ($type eq 'index') {
		 	print "\n.hu $level $_\n";
		}
	}
	elsif (/.in:\.toc /){
		s/.*\.toc *//;
		if ($type eq 'index'){
			print "\n$_\n";
		}
	}
}
if ($type eq 'header'){
	print "</table>\n";
}
else {
	if ( -f "index.bottom"){
		if (open(IT,"index.bottom")){
			while (<IT>){print;}
			close IT;
		}
	}
	
}
