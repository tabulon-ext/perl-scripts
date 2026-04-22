#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 March 2021
# https://github.com/trizen

# Generate k-omega primes in range [a,b]. (not in sorted order)

# Definition:
#   k-omega primes are numbers n such that omega(n) = k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function

# PARI/GP code:
#   omega_numbers(A, B, n) = A=max(A, vecprod(primes(n))); local(f); (f = (m, p, j) -> my(list=List()); forprime(q=p, sqrtnint(B\m, j), my(v=m*q); while(v <= B, if(j==1, if(v>=A, listput(list, v)), if(v*(q+1) <= B, list=concat(list, f(v, q+1, j-1)))); v *= q)); list); vecsort(Vec(f(1, 2, n)));

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub omega_prime_numbers ($A, $B, $k, $callback) {

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $p, $k) {

        my $s = rootint(divint($B, $m), $k);

        foreach my $q (@{primes($p, $s)}) {

            my $r = next_prime($q);

            for (my $v = mulint($m, $q); $v <= $B ; $v = mulint($v, $q)) {
                if ($k == 1) {
                    $callback->($v) if ($v >= $A);
                }
                elsif (mulint($v, $r) <= $B) {
                    __SUB__->($v, $r, $k - 1);
                }
            }
        }
    }->(1, 2, $k);
}

# Generate 5-omega primes in the range [3000, 10000]

my $k    = 5;
my $from = 3000;
my $upto = 10000;

my @arr;
omega_prime_numbers($from, $upto, $k, sub ($n) { push @arr, $n });

my @test = grep { prime_omega($_) == $k } $from .. $upto;    # just for testing
join(' ', sort { $a <=> $b } @arr) eq join(' ', @test) or die "Error: not equal!";

say join(', ', @arr);

# Run some tests

foreach my $k (1 .. 6) {

    my $from = pn_primorial($k) + int(rand(1e4));
    my $upto = $from + int(rand(1e5));

    say "Testing: $k with $from .. $upto";

    my @arr;
    omega_prime_numbers($from, $upto, $k, sub ($n) { push @arr, $n });

    my @test = grep { prime_omega($_) == $k } $from .. $upto;
    join(' ', sort { $a <=> $b } @arr) eq join(' ', @test) or die "Error: not equal!";
}
