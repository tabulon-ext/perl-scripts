#~ #!/usr/bin/perl

# Author: Daniel Șuteu (trizen)
# Date: 15 July 2026
# https://github.com/trizen

# Concatenate multiple files from a given directory (and its subdirectories), that have a given extension.

use 5.036;
use File::Find qw(find);
use open IO => ':utf8', ':std';
use Getopt::Long qw(GetOptions);

my $ext = 'pod';

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [directory]

options:

    --ext=s  : concatenate files with these extensions (comma-separated)

EOT

    exit($exit_code);
}

GetOptions('extensions=s' => \$ext,
           'h|help'       => sub { usage(0) },)
  or die("Error in command line arguments\n");

my $dir = shift(@ARGV) // die usage(2);

my $ext_regex = join('|', map { quotemeta($_) } map { split(/\s*,\s*/, $_) } split(' ', $ext));
$ext_regex = qr/\.(?:$ext_regex)\z/o;

find(
    {
     wanted => sub {
         if (-f $_ and $_ =~ /$ext_regex/) {
             open my $fh, '<', $_ or return;
             while (defined(my $line = <$fh>)) {
                 print $line;
             }
             close $fh;
             print "\n";
         }
     },
     no_chdir => 1
    },
    $dir
);
