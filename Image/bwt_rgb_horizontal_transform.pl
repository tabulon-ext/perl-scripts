#!/usr/bin/perl

# Author: Trizen
# Date: 05 April 2024
# Edit: 09 April 2024
# https://github.com/trizen

# Apply the Burrows-Wheeler transform on each row (RGB-wise) of an image.

use 5.036;
use GD;
use Getopt::Std       qw(getopts);
use Compression::Util qw(bwt_encode bwt_decode);

GD::Image->trueColor(1);

sub apply_bwt ($file) {

    my $image = GD::Image->new($file) || die "Can't open file <<$file>>: $!";
    my ($width, $height) = $image->getBounds();

    my $new_image = GD::Image->new($width + 3, $height);

    foreach my $y (0 .. $height - 1) {

        my (@R, @G, @B);
        foreach my $x (0 .. $width - 1) {
            my ($R, $G, $B) = $image->rgb($image->getPixel($x, $y));
            push @R, $R;
            push @G, $G;
            push @B, $B;
        }

        my ($R, $R_idx) = bwt_encode(pack('C*', @R));
        my ($G, $G_idx) = bwt_encode(pack('C*', @G));
        my ($B, $B_idx) = bwt_encode(pack('C*', @B));

        @R = unpack('C*', $R);
        @G = unpack('C*', $G);
        @B = unpack('C*', $B);

        $new_image->setPixel(0, $y, $R_idx);
        $new_image->setPixel(1, $y, $G_idx);
        $new_image->setPixel(2, $y, $B_idx);

        foreach my $x (0 .. $width - 1) {
            $new_image->setPixel($x + 3, $y, $new_image->colorAllocate($R[$x], $G[$x], $B[$x]));
        }
    }

    return $new_image;
}

sub undo_bwt ($file) {

    my $image = GD::Image->new($file) || die "Can't open file <<$file>>: $!";
    my ($width, $height) = $image->getBounds();

    my $new_image = GD::Image->new($width - 3, $height);

    foreach my $y (0 .. $height - 1) {

        my (@R, @G, @B);

        my $R_idx = $image->getPixel(0, $y);
        my $G_idx = $image->getPixel(1, $y);
        my $B_idx = $image->getPixel(2, $y);

        foreach my $x (3 .. $width - 1) {
            my ($R, $G, $B) = $image->rgb($image->getPixel($x, $y));
            push @R, $R;
            push @G, $G;
            push @B, $B;
        }

        @R = unpack 'C*', bwt_decode(pack('C*', @R), $R_idx);
        @G = unpack 'C*', bwt_decode(pack('C*', @G), $G_idx);
        @B = unpack 'C*', bwt_decode(pack('C*', @B), $B_idx);

        foreach my $x (0 .. $width - 3 - 1) {
            $new_image->setPixel($x, $y, $new_image->colorAllocate($R[$x], $G[$x], $B[$x]));
        }
    }

    return $new_image;
}

sub usage ($exit_code = 0) {

    print <<"EOT";
usage: $0 [options] [input.png] [output.png]

options:

    -d : decode the image
    -h : print this message and exit

EOT

    exit($exit_code);
}

getopts('dh', \my %opts);

my $input_file  = $ARGV[0] // usage(2);
my $output_file = $ARGV[1] // "output.png";

if (not -f $input_file) {
    die "Input file <<$input_file>> does not exist!\n";
}

my $img = $opts{d} ? undo_bwt($input_file) : apply_bwt($input_file);
open(my $out_fh, '>:raw', $output_file) or die "can't create output file <<$output_file>>: $!";
print $out_fh $img->png(9);
close $out_fh;
