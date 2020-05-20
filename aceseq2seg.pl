#!/usr/bin/env perl

use strict;
use warnings; 
use Getopt::Long;
use Scalar::Util;

my $usage = "  perl $0\t-f [comma separated input file list - REQUIRED]\n\t\t\t-n [comma separated sample names - OPTIONAL]\n\t\t\t-l [log base, either 2 or 'given' - OPTIONAL]\n\n";

my @files = ();  # list of files
my @names = ();  # list of sample names [optional]
my $log_base="given"; # GISTIC requires input to be in log space, expecting log-base-2 but log-base-ploidy is appropiate for non diploids [optional]

GetOptions ("files=s"   => \@files,     # string
            "names=s"   => \@names,     # string
            "logBase=s" => \$log_base)  # string
  or die("ERROR: error in command line arguments\n\n$usage");

#############################
## CHECK @files and @names ##
#############################

die("\nERROR: file list too small (\"$files[0]\")\n\n$usage") if (length($files[0])<1);

@files = split(/,/,join(',',@files));

if (length($names[0])>1){
  # use names if defined
  @names = split(/,/,join(',',@names));
} else {
  # else use filenames as names
  @names = @files;
}

my $num_files = scalar @files;
my $num_names = scalar @names;

die("\nERROR: number of names ($num_names) does not match number of files ($num_files). Please check input parameters\n\n$usage") if ($num_files ne $num_names);  

warn "\nNumber of input files: $num_files\n";
warn "SAMPLE\tFILE\n";
for (0..($num_files-1)){
  warn "$names[$_]\t$files[$_]\n"
}

#############################
## CHECK log base for conv ##
#############################

if (Scalar::Util::looks_like_number($log_base)){
  warn "\nLog base '$log_base' looks like a number\n";
} else {
  warn "\nLog base '$log_base' DOES NOT look like a number... forcing to 'given'\n";
  $log_base = "given";
}

die("\nERROR: log base ($log_base) cannot be less than 1\n\n$usage") if ($log_base < 1);


warn "\nLog base to use: '$log_base' (should be 2 or 'given'. Other values used at your own risk!)\n";
