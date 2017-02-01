#!/usr/bin/perl
#INSTALL@ /usr/local/bin/mkinheader
$VERBOSE=0;

$type='header';

for (@ARGV){
	chomp;
	if (/^$/){ $type='header';}
	elsif (/-h/){
		$type='header';
	}
	elsif (/-i/){
		$type='index';
	}
	elsif (/-v/){$VERBOSE++;}
	else { print "$_; only -h(eader) and -i(ndex.html) allowed.\n";}
}
	
if ($VERBOSE > 0){ print "######## type=$type\n";}


if (open(IN,"egrep '^\.h[123] |\.toc|^.author|^.title|^.subtitle' `ls *.in| sort -n` |")){
	@in=<IN>;
	close IN;
}
else {
	die 'Cannot grep .in-files';
}

$tot_title='Index';
$sub_title='';
$author='';

for (@in){
	if (/in:.title (.*)/){ $tot_title=$1; }
	if (/in:.subtitle (.*)/){ $sub_title="$subtitle<br>$1"; }
	if (/in:.author (.*)/){ $author=$1;}
}

if ($type eq 'header'){
	if ($tot_title ne 'Index' ){print "<h1>$tot_title</h1>\n";}
	if ($sub_title ne '' ){print "<h2>$sub_title</h2>\n";}
	if ($author ne ''){print "<h3>$author</h3>\n";}
}
elsif ($type eq 'index'){
	print ".link total.pdf (pdf)\n";
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
$prev_c=0;
$s=0;
$p=0;
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

	if (/^index/){ $prev_c=0;}
	if (/^total/){ $prev_c=0;}
	elsif (/^([0-9]*)_(.*).in:.h([123]) (.*)/){
		my $c=$1;
		my $file="$1_$2.html";
		my $pdf="$1_$2.pdf";
		my $level=$3;
		my $title=$4;
if ($VERBOSE>0){print "#chapter:$c file:$file level:$level title:$title\n";}
		if ($c != $prev_c){ $s=0; $p=0; $prev_c=$c; }
		if ($level==1){
			if ($type eq 'header'){ print "	<tr class=toc><td colspan=3><a href=\"$file#a$c\"><span CLASS=toc> $c $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print "\n.br\n.link $file#a$c $c $title\n.link $pdf (pdf)";}
		}
		elsif ($level==2){
			$s++; $p=0;
#			if ($type eq 'header'){ print "	<tr class=toc><td>&nbsp;</td><td colspan=2><a href=\"$file#a$c.$s\"><span CLASS=toc>$c.$s $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print "\n.br\n.link $file#a$c.$s $c.$s $title\n";}
		}
		elsif ($level==3){
			$p++;
#			if ($type eq 'header'){ print "	<tr class=toc><td>&nbsp;</td><td>&nbsp;</td><td><a href=\"$file#a$c.$s.$p\"><span CLASS=toc>$c.$s.$p $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print "\n.br\n.link $file#a$c.$s.$p $c.$s.$p $title\n";}
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
		$level=$1;
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
	print "\n.br\n.link total.pdf PDF\n";
	if ( -f "index.bottom"){
		if (open(IT,"index.bottom")){
			while (<IT>){print;}
			close IT;
		}
	}
	
}
