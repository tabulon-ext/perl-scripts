#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 09 November 2018
# Edit: 30 March 2025
# https://github.com/trizen

# A new generalized algorithm with O(sqrt(n)) complexity for computing the partial-sums of the `sigma_j(k)` function:
#
#   Sum_{k=1..n} sigma_j(k)
#
# for any integer j >= 0.

# See also:
#   https://en.wikipedia.org/wiki/Divisor_function
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula
#   https://en.wikipedia.org/wiki/Bernoulli_polynomials
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.036;
use ntheory      qw(divisors);
use Math::AnyNum qw(faulhaber_sum bernoulli sum isqrt ipow);

sub sigma_partial_sum_faulhaber ($n, $m = 1) {    # using Faulhaber's formula

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    my $sum = 0;

    foreach my $k (1 .. $s) {
        $sum += $k * (faulhaber_sum(int($n / $k), $m) - faulhaber_sum(int($n / ($k + 1)), $m));
    }

    foreach my $k (1 .. $u) {
        $sum += ipow($k, $m) * int($n / $k);
    }

    return $sum;
}

sub sigma_partial_sum_dirichlet ($n, $m = 1) {    # using the Dirichlet hyperbola method

    my $total = 0;
    my $s     = isqrt($n);

    for my $k (1 .. $s) {
        $total += faulhaber_sum(int($n / $k), $m);
        $total += ipow($k, $m) * int($n / $k);
    }

    $total -= $s * faulhaber_sum($s, $m);

    return $total;
}

sub sigma_partial_sum_bernoulli ($n, $m = 1) {    # using Bernoulli polynomials

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    my $sum = 0;

    foreach my $k (1 .. $s) {
        $sum += $k * (bernoulli($m + 1, 1 + int($n / $k)) - bernoulli($m + 1, 1 + int($n / ($k + 1)))) / ($m + 1);
    }

    foreach my $k (1 .. $u) {
        $sum += ipow($k, $m) * int($n / $k);
    }

    return $sum;
}

sub sigma_partial_sum_test ($n, $m = 1) {    # just for testing
    sum(
        map {
            sum(map { ipow($_, $m) } divisors($_))
          } 1 .. $n
       );
}

foreach my $m (0 .. 10) {

    my $n = int(rand(1000));

    my $t1 = sigma_partial_sum_test($n, $m);
    my $t2 = sigma_partial_sum_faulhaber($n, $m);
    my $t3 = sigma_partial_sum_bernoulli($n, $m);
    my $t4 = sigma_partial_sum_dirichlet($n, $m);

    say "Sum_{k=1..$n} sigma_$m(k) = $t2";

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);
    die "error: $t1 != $t4" if ($t1 != $t4);
}

__END__
Sum_{k=1..198} sigma_0(k) = 1084
Sum_{k=1..657} sigma_1(k) = 355131
Sum_{k=1..933} sigma_2(k) = 325914283
Sum_{k=1..905} sigma_3(k) = 181878297343
Sum_{k=1..402} sigma_4(k) = 2191328841200
Sum_{k=1..967} sigma_5(k) = 139059243381760868
Sum_{k=1..320} sigma_6(k) = 50042081613053611
Sum_{k=1..168} sigma_7(k) = 81561359789498529
Sum_{k=1..977} sigma_8(k) = 90713993807165413835362083
Sum_{k=1..219} sigma_9(k) = 25985664184393953943010
Sum_{k=1..552} sigma_10(k) = 133190310787744370768676943091
