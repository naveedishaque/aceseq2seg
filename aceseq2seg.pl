#!/usr/bin/env perl

## BEHAVIOUR
##
## Converts ACEseq files into seg files used by GISTIC
## convests whole total copy number (TCN) values into log spac
## log base is determined as the sample ploidy (or 2 if you assume diploid)
## homozygous deletions are set at a low number (-5)
## homozygous deletions are determined when the TCN < 0.25
## regions with less than 3 SNPs (i.e ACEseq cannot determine the TCN) are set to base ploidy

###############
## LIBRARIES ##
###############

use strict;
use warnings; 
use Getopt::Long;
use Scalar::Util;

###############
##   USAGE   ##
###############

my $usage = "
  perl $0
\t-f [comma separated input file list - REQUIRED]
\t-n [comma separated sample names - DEFAULT: input file list]
\t-l [log base, either 2 or 'given' - DEFAULT: given]
\t-o [output file - DEFAULT: STDOUT]
\n";

###############
##  PARAMS   ##
###############

## INPUT variables
my @files = ();  # list of files
my @names = ();  # list of sample names [optional]
my $log_base="given"; # GISTIC requires input to be in log space, expecting log-base-2 but log-base-ploidy is appropiate for non diploids [optional]
my $output = "STDOUT";

## Parameters
my $homo_del = -5;
my $homo_del_threshold = 0.3;
my $snp_threshold = 5;
my $chr_idx = 0;
my $str_idx = 1,
my $end_idx = 2;
my $tcn_idx = 5;
my $snp_idx = 13;

################
## PARSE OPTS ##
################

GetOptions ("files=s"   => \@files,
            "names=s"   => \@names,
            "logBase=s" => \$log_base,
            "output=s"  => \$output) 
  or die("ERROR: error in command line arguments\n$usage");

## CHECK @files and @names

die("\nERROR: file list too small (\"$files[0]\")\n$usage") if (length($files[0])<1);

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

die("\nERROR: number of names ($num_names) does not match number of files ($num_files). Please check input parameters\n$usage") if ($num_files ne $num_names);  

warn "\nNumber of input files: $num_files\n";
warn "SAMPLE\tFILE\n";
for (0..($num_files-1)){
  warn "$names[$_]\t$files[$_]\n";
  die("\nERROR: file '$files[$_]' not found\n$usage") unless (-e $files[$_]);
}

## CHECK log base for conv ##

if (Scalar::Util::looks_like_number($log_base)){
  warn "\nLog base '$log_base' looks like a number\n";
} else {
  warn "\nLog base '$log_base' DOES NOT look like a number... forcing to 'given'\n";
  $log_base = "given";
}

die("\nERROR: log base ($log_base) cannot be less than 1\n$usage") if (($log_base < 1) && ($log_base ne "given"));

warn "\nLog base to use: '$log_base' (should be 2 or 'given'. Other values used at your own risk!)\n\n";

#####################
## PROCESS SAMPLES ##
#####################

## EXPECTED FILE HEADER

#tcc:1
#ploidy:3.94
#roundPloidy:4
#fullPloidy:4
#quality:0.99834736077127
#assumed sex:male
#0:chromosome 1:start 2:end 3:length 4:covRatio 5:TCN 6:SV.Type 7:c1Mean 8:c2Mean 9:dhEst 10:dhSNPs 11:genotype 12:CNA.type 13:NbrOfHetsSNPs 14:minStart 15:maxStart 16:minStop 17:maxStop

print "sample\tchromosome\tstart_position\tend_position\tnum_markers\tlog2_seg_CN-1\n";

foreach my $sample_idx (0..($num_files-1)){
  my $file = $files[$sample_idx];
  my $name = $names[$sample_idx];
  my $sex = "female";
  
  my $fh;
  open $fh, $file or die "ERROR: could not open $file : $!\n$usage";

  my $round_ploidy;
  my $line;
  
  while($line = <$fh>) {
    if ($line =~ m/\#roundPloidy:(.*?)$/){
      $round_ploidy = $1;
      chomp($round_ploidy);
      warn "$name\tploidy:$round_ploidy\tlog_base:$log_base\n";
      # reset round_ploidy to defined log_base, unless sample sepcific ploidy are the log_base
      $round_ploidy = $log_base unless ($log_base eq "given")
    }
    if ($line =~ m/\#assumed sex:(.*?)$/){
      $sex = $1;
    }
    unless ($line =~ m/^\#/){
      my @line_split = split('\t', $line);
      my ($chr, $str, $end, $tcn, $num_snps) = ($line_split[$chr_idx], $line_split[$str_idx], $line_split[$end_idx], $line_split[$tcn_idx], $line_split[$snp_idx]);

      # covert TCN into log space, or set to base_ploidy for low snps, or low for homodel
      my $tcn_log = 0;
      if ($num_snps < $snp_threshold){
        $tcn_log = 0; 
      } 
      elsif ($tcn < $homo_del_threshold ) {
        $tcn_log = $homo_del;
      }
      else {
        $tcn_log = log($tcn)/log($round_ploidy) - 1;
        $tcn_log = log($tcn*2)/log($round_ploidy) - 1 if (($chr eq "Y"||$chr eq "X"||$chr eq "chrY"||$chr eq "chrX") && ($sex eq "male"));
      }
      $tcn_log = (int($tcn_log*1000))/1000; 

      print "$name\t$chr\t$str\t$end\t$num_snps\t$tcn_log\n";
    }
  }

  close $fh;
}
