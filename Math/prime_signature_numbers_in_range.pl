#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 April 2026
# https://github.com/trizen

# Generate all the k-omega numbers in range [A,B] that have a given prime signature.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_signature

use 5.036;
use ntheory 0.74 qw(:all);

sub rootint_ceil($n, $k) {
    if (is_power($n, $k)) {
        return rootint($n, $k);
    }
    return 1 + rootint($n, $k);
}

sub prime_signature_numbers_in_range($A, $B, $prime_signature) {

    my @list;
    my $k = scalar(@$prime_signature);

    # Handle empty prime signature
    if ($k == 0) {
        push(@list, 1) if ($A <= 1 and 1 <= $B);
        return @list;
    }

    $A = vecmax(pn_primorial($k), $A);

    my $generate = sub ($m, $lo, $k, $P) {

        my $e  = $P->[$k - 1];
        my $hi = rootint(divint($B, $m), ($k > $e ? $k : $e));

        if ($k == 1) {

            $lo = vecmax($lo, rootint_ceil(cdivint($A, $m), $e));

            if ($lo > $hi) {
                return;
            }

            foreach my $p (@{primes($lo, $hi)}) {
                push @list, mulint($m, powint($p, $e));
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {
            my $t = mulint($m, powint($p, $e));
            my $u = rootint(divint($B, $t), $P->[$k - 2]);
            last if ($p + 1 > $u);
            __SUB__->($t, $p + 1, $k - 1, $P);
        }
    };

    my %seen;
    forperm {
        my @perm = @{$prime_signature}[@_];
        if (!$seen{join(' ', @perm)}++) {
            $generate->(1, 2, scalar(@perm), \@perm);
        }
    } $k;

    sort { $a <=> $b } @list;
}

my $prime_signature = [3, 2, 2];

my $A = 2000;
my $B = 10000;

my @arr = prime_signature_numbers_in_range($A, $B, $prime_signature);
say "@arr";

# Brute-force check
my @bf = grep { join(' ', prime_signature($_)) eq join(' ', @$prime_signature) } vecmax(pn_primorial(scalar(@$prime_signature)), $A) .. $B;
say "@bf";

"@arr" eq "@bf" or die "error";
