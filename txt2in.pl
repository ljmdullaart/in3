#!/usr/bin/perl
#INSTALL@ /usr/local/bin/txt2in

$side=0;
$poem=0;
$text=0;


for (@ARGV){
	chomp;
      $arg=$_;
	if ($arg =~ /^-*h/){
		print "txt2in: convert txt file to a .in file                \n";
		print "txt2in [-h] [-p] [-s] file                                      \n";
		print " Txt2in tries to guess the type of text as well as possible.    \n";
	}
	elsif (/^-*p.*/) { $poem=1; }
	elsif (/^-*s.*/) { $side=1; }
	elsif (/^-/) { print "Unknown argument $arg \n";}
	else {
		if (open(my $FILE,"<","$arg")){
			@input=<$FILE>;
			close $FILE;
		}
	}
}


for (@input){
	if (/^\.poem/){$poem++;}
}

$innote=0;
$nl=0;

for (@input){
	s/^ *//;
	s/(\{[^}]*\})\./.$1/;
	if (/^$/){
		if ($innote==1){ $innote=0; }
		else { $nl=1; }
	}
	elsif(/^\.note/){
		print;
		$innote=1;
		$nl=0;
	}
	else {
		if ($nl>0){
			print "\n";
		}
		$nl=0;
		s/__/	/g;
		while (/\{/){
			s/\{/
.side /;
			s/\}/
/;
		}	
		print;
	}

}

print "\n";
print "\n";
