#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 April 2026
# https://github.com/trizen

# Count the number of k-omega numbers <= n that have a given prime signature.

use 5.036;
use ntheory 0.74 qw(:all);

sub count_prime_signature_numbers($n, $prime_signature) {

    my $k = scalar(@$prime_signature);

    if ($k == 0) {
        return 1 if (1 <= $n);
        return 0;
    }

    my $count = 0;

    my $generate = sub ($m, $lo, $k, $P, $j = 0) {

        my $e = $P->[$k - 1];

        # Aggressive Math Pruning: Sum of all remaining exponents
        my $sum_e = 0;
        $sum_e += $_ for @{$P}[0 .. $k - 1];

        my $hi = rootint(divint($n, $m), $sum_e);

        if ($k == 1) {
            $count += prime_count($hi) - $j;
            return;
        }

        my $primes = primes($lo, $hi);
        my $e2     = $P->[$k - 2];

        if ($k == 2) {
            foreach my $p (@$primes) {
                my $t = mulint($m, powint($p, $e));
                my $u = rootint(divint($n, $t), $e2);

                # If current prime >= limit for next prime, break.
                last if ($p >= $u);

                $count += prime_count($u) - ++$j;
            }
            return;
        }

        # General recursive case for k > 2
        my $sum_e_next = $sum_e - $e;

        foreach my $p (@$primes) {
            my $t = mulint($m, powint($p, $e));
            my $u = rootint(divint($n, $t), $sum_e_next);

            last if ($p >= $u);

            __SUB__->($t, $p + 1, $k - 1, $P, ++$j);
        }
    };

    my %seen;
    forperm {
        my @perm = @{$prime_signature}[@_];
        if (!$seen{join(' ', @perm)}++) {
            $generate->(1, 2, scalar(@perm), \@perm);
        }
    } $k;

    return $count;
}

sub count_prime_signature_numbers_in_range($A, $B, $signature) {
    my $term_1 = count_prime_signature_numbers($A - 1, $signature);
    my $term_2 = count_prime_signature_numbers($B,     $signature);
    $term_2 - $term_1;
}

#
## Example
#
sub A395379($n) {
    my $A = powint((nth_prime($n - 1) || 1), 7);
    my $B = powint(nth_prime($n),            7) - 1;

    my $term_1 = count_prime_signature_numbers_in_range($A, $B, [7]);
    my $term_2 = count_prime_signature_numbers_in_range($A, $B, [3, 1]);
    my $term_3 = count_prime_signature_numbers_in_range($A, $B, [1, 1, 1]);

    $term_1 + $term_2 + $term_3;
}

join(' ', map { A395379($_) } 1 .. 9) eq join(' ', 15, 408, 16838, 167649, 4140037, 9474308, 74874018, 102945521, 527810589)
  or die "error";

my $prime_signature = [3, 2, 2];
my $n               = 10000;

count_prime_signature_numbers($n, $prime_signature) == 7                or die "error";
count_prime_signature_numbers_in_range(2e3, 1e4, $prime_signature) == 6 or die "error";
