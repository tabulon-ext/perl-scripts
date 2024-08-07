#!/usr/bin/perl

# Author: Trizen
# Date: 15 June 2023
# Edit: 02 May 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Move-to-front transform (MTF) + ZRLE + LZHD compression.

# References:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ
#
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use List::Util        qw(max uniq);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'BWLZ3',
    VERSION => '0.01',
    FORMAT  => 'bwlz3',

    CHUNK_SIZE => 1 << 17,    # higher value = better compression
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

sub usage {
    my ($code) = @_;
    print <<"EOH";
usage: $0 [options] [input file] [output file]

options:
        -e            : extract
        -i <filename> : input filename
        -o <filename> : output filename
        -r            : rewrite output

        -v            : version number
        -h            : this message

examples:
         $0 document.txt
         $0 document.txt archive.${\FORMAT}
         $0 archive.${\FORMAT} document.txt
         $0 -e -i archive.${\FORMAT} -o document.txt

EOH

    exit($code // 0);
}

sub version {
    printf("%s %s\n", PKGNAME, VERSION);
    exit;
}

sub valid_archive {
    my ($fh) = @_;

    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        $sig eq SIGNATURE || return;
    }

    return 1;
}

sub main {
    my %opt;
    getopts('ei:o:vhr', \%opt);

    $opt{h} && usage(0);
    $opt{v} && version();

    my ($input, $output) = @ARGV;
    $input  //= $opt{i} // usage(2);
    $output //= $opt{o};

    my $ext = qr{\.${\FORMAT}\z}io;
    if ($opt{e} || $input =~ $ext) {

        if (not defined $output) {
            ($output = basename($input)) =~ s{$ext}{}
              || die "$0: no output file specified!\n";
        }

        if (not $opt{r} and -e $output) {
            print "'$output' already exists! -- Replace? [y/N] ";
            <STDIN> =~ /^y/i || exit 17;
        }

        decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub compression ($chunk, $out_fh) {

    my $lzb = do {
        local $Compression::Util::LZ_MIN_LEN = 512;
        lzb_compress($chunk);
    };

    my @chunk_bytes = unpack('C*', $lzb);
    my $data        = rle4_encode(\@chunk_bytes, scalar(@chunk_bytes));

    my ($bwt,       $idx)      = bwt_encode_symbolic($data);
    my ($enc_bytes, $alphabet) = mtf_encode($bwt);

    $enc_bytes = zrle_encode($enc_bytes);

    print $out_fh pack('N', $idx);
    print $out_fh encode_alphabet($alphabet);
    print $out_fh lz77_compress_symbolic($enc_bytes);
}

sub decompression ($fh, $out_fh) {

    my $idx      = bytes2int($fh, 4);
    my $alphabet = decode_alphabet($fh);

    my $symbols = lz77_decompress_symbolic($fh);

    $symbols = zrle_decode($symbols);
    $symbols = mtf_decode($symbols, $alphabet);

    print $out_fh lzb_decompress(symbols2string(rle4_decode(bwt_decode_symbolic($symbols, $idx))));
}

# Compress file
sub compress_file ($input, $output) {

    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    my $header = SIGNATURE;

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    # Print the header
    print $out_fh $header;

    # Compress data
    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        compression($chunk, $out_fh);
    }

    # Close the output file
    close $out_fh;
}

# Decompress file
sub decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        decompression($fh, $out_fh);
    }

    # Close the files
    close $fh;
    close $out_fh;
}

main();
exit(0);
