#!/usr/bin/perl

# Adds auto tags to MP3 audio files from a directory and it's subdirectories
# Coded by Trizen under the GPL.
# First release on 15 August 2011
# Contact email: <trizenx[@]gmail.com>

use strict 'refs';
use warnings;
use File::Find ('find');

my @dirs = grep { -d $_ } @ARGV;

die "Usage: $0 <dir>\n" unless @dirs;

require MP3::Tag;

my @mp3_files;

find(\&wanted_files, @dirs);

sub wanted_files {
    my $file = $File::Find::name;
    push @mp3_files, $file if $file =~ /\.mp3$/io;
}

foreach my $filename (@mp3_files) {

    my $mp3 = 'MP3::Tag'->new($filename);

    $mp3->config(write_v24 => 1);
    $mp3->autoinfo;
    $mp3->update_tags;
}
