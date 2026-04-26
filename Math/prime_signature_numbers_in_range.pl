#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 April 2026
# https://github.com/trizen

# Generate all the k-omega numbers in range [A,B] that have a given prime signature.

use 5.036;
use ntheory 0.74 qw(:all);

sub rootint_ceil($n, $k) {
    return rootint($n, $k) + (is_power($n, $k) ? 0 : 1);
}

sub prime_signature_numbers_in_range($A, $B, $prime_signature) {

    my @list;
    my $k = scalar(@$prime_signature);

    if ($k == 0) {
        push(@list, 1) if ($A <= 1 and 1 <= $B);
        return @list;
    }

    # The smallest possible number with k distinct prime factors
    $A = vecmax(pn_primorial($k), $A);

    my $generate = sub ($m, $lo, $k, $P) {

        my $e = $P->[$k - 1];

        # AGGRESSIVE: Sum all remaining exponents for a tight upper bound
        my $sum_e = 0;
        $sum_e += $_ for @{$P}[0 .. $k - 1];

        my $hi = rootint(divint($B, $m), $sum_e);

        # Base case
        if ($k == 1) {

            # Tighten the lower bound based on A
            my $lo_tight = vecmax($lo, rootint_ceil(cdivint($A, $m), $e));

            if ($lo_tight <= $hi) {
                foreach my $p (@{primes($lo_tight, $hi)}) {
                    push @list, mulint($m, powint($p, $e));
                }
            }
            return;
        }

        # Recursive case
        my $sum_e_next = $sum_e - $e;
        foreach my $p (@{primes($lo, $hi)}) {
            my $t = mulint($m, powint($p, $e));

            # TIGHT LOOKAHEAD: Calculate max possible value for the next prime
            my $u = rootint(divint($B, $t), $sum_e_next);

            # Since p_next must be > p, we stop if p is already too large
            last if ($p >= $u);

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

    return sort { $a <=> $b } @list;
}

# Example
my $prime_signature = [3, 2, 2];
my $A               = 2000;
my $B               = 10000;

my @arr = prime_signature_numbers_in_range($A, $B, $prime_signature);
say "Generated: @arr";

my @bf = grep {
    join(' ', prime_signature($_)) eq join(' ', sort { $b <=> $a } @$prime_signature)
} vecmax(pn_primorial(scalar(@$prime_signature)), $A) .. $B;

"@arr" eq "@bf" or die "Mismatch detected!";
