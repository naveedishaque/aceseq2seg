# aceseq2seg

A script to convert the output files from ACEseq to the seg format used as input for GISTIC.

 - converts ACEseq files into seg files used by GISTIC
 - convests whole total copy number (TCN) values into log space
 - [Dorett Odoni] gistic2 requires the segment copy number (seg.CN) to be given as log2(seg.CN) - 1. To account for varying base ploidies across a cohort, as well as still adjusting the numbers to be what Gistic2 expects, the seg.CN for the Gistic2 input file is calculated as:
   - $tcn_log = log( log($ploidy^($tcn/$ploidy), $ploidy) *2, 2) - 1
 - homozygous deletions are set at a low number (-5)
 - homozygous deletions are determined when the TCN < 0.25
 - regions with less than 5 SNPs (i.e ACEseq cannot determine the TCN) are set to base ploidy
 - chrX/Y for males are corrected (using double observed ploidy)

## Prerequisites

- Developed using perl 5, version 26, subversion 1 (v5.26.1) built for x86_64-linux-gnu-thread-multi

## Usage

```
  perl aceseq2seg.pl
        -f [comma separated input file list - REQUIRED]
        -n [comma separated sample names - DEFAULT: input file list]
        -l [log base, either 2 or 'given' - DEFAULT: given]
        -o [output file - DEFAULT: STDOUT]
```

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

Naveed Ishaque

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

Dorett I Odoni
