#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 January 2020
# https://github.com/trizen

# Prove the primality of a number, using the Pocklington primality test recursively.

# See also:
#   https://en.wikipedia.org/wiki/Pocklington_primality_test
#   https://en.wikipedia.org/wiki/Primality_certificate
#   http://mathworld.wolfram.com/PrattCertificate.html

use 5.020;
use strict;
use warnings;
use experimental qw(signatures);

use List::Util qw(uniq);
use ntheory qw(is_prime is_prob_prime primes);
use Math::AnyNum qw(:overload isqrt prod is_coprime irand powmod);
use Math::Prime::Util::GMP qw(ecm_factor);

my $SMALL_PRIMES = primes(1000);

sub trial_factor ($n) {
    my @f;
    foreach my $p (@$SMALL_PRIMES) {
        while ($n % $p == 0) {
            push @f, $p;
            $n /= $p;
        }
    }
    push @f, $n;
    return @f;
}

sub pocklington_pratt_primality_test ($n, $lim = 2**64) {

    if ($n <= $lim or $n <= 2) {
        return is_prime($n);    # deterministic test for small n
    }

    is_prob_prime($n) || return 0;

    say ":: Proving primality of: $n";

    my $D = $n - 1;
    my @f = trial_factor($D);
    my $B = pop @f;
    my $S = isqrt($n);

    if (__SUB__->($B, $lim)) {
        push @f, $B;
        $B = 1;
    }

    for (; ;) {
        my $A = prod(@f);

        if ($A > $S and is_coprime($A, $B)) {

            foreach my $p (uniq(@f)) {
                for (; ;) {
                    my $a = irand(2, $D);
                    powmod($a, $D, $n) == 1 or return 0;
                    if (is_coprime(powmod($a, $D / $p, $n) - 1, $n)) {
                        say "a = $a ; p = $p";
                        last;
                    }
                }
            }

            return 1;
        }

        my @e = grep { __SUB__->($_, $lim) } ecm_factor($B);
        say "ECM: @e";
        push @f, @e;
        $B /= prod(@e);
    }
}

#say pocklington_pratt_primality_test(436038354884290791181179106723869598426480144441);
#say pocklington_pratt_primality_test(3791200232251482865919745722303442788615510538727);
say "Is prime: ", pocklington_pratt_primality_test(115792089237316195423570985008687907853269984665640564039457584007913129603823);

__END__
:: Proving primality of: 115792089237316195423570985008687907853269984665640564039457584007913129603823
:: Proving primality of: 57896044618658097711785492504343953926634992332820282019728792003956564801911
:: Proving primality of: 2848630210554880446022254608450222949126931851754251657020267
ECM: 22483
:: Proving primality of: 3201964079152361724098258636758155557
:: Proving primality of: 1202684276868524221513588244947
ECM: 192697
ECM: 5829139 59483944987587859
a = 1004391930947187995060952223673 ; p = 2
a = 212723275548288825078546728367 ; p = 3
a = 433055352886793533313912994772 ; p = 192697
a = 59501611958510681928135781904 ; p = 5829139
a = 313047848896182692131068137569 ; p = 59483944987587859
ECM: 51199 1202684276868524221513588244947
a = 1077890414311282312802388841419789456 ; p = 2
a = 1378743008603991259368286947398181525 ; p = 13
a = 3163454306117358480227370904607622726 ; p = 51199
a = 498575069738540952855690257533354172 ; p = 1202684276868524221513588244947
ECM: 100274029791527 3201964079152361724098258636758155557
a = 1301541577401580881745044998974757374446186273024821238782052 ; p = 2
a = 2308590994988511566791524437315219935595441852184377697816926 ; p = 7
a = 441513532933710036071278663530967305823472207874536313938188 ; p = 71
a = 2408504230486520368369162312370608098721291549554123612616758 ; p = 397
a = 82170722447079232083708665370086717384202672159702735913282 ; p = 22483
a = 1269100145282526138793340630966547521000629759601567960945000 ; p = 100274029791527
a = 633253093145390437918765845343457857323531134765144909809219 ; p = 3201964079152361724098258636758155557
ECM: 106969315701167 2848630210554880446022254608450222949126931851754251657020267
a = 15833670526659981131932279315587690110728176835099173392896026313499521451172 ; p = 2
a = 50446511321643521875414462529461979660013320644702225094174697632730124390752 ; p = 5
a = 8835958990708663867001440690902709128711054695554761696184777740553627461473 ; p = 19
a = 17385248476298993992421667114851470648122297717915209335276593256679481227384 ; p = 106969315701167
a = 20462484801084756593157480591301174620758741081932414121187018963324601850577 ; p = 2848630210554880446022254608450222949126931851754251657020267
a = 52155526697538352478961545820383726131532731489994275632094139405889214979377 ; p = 2
a = 97606398696266993000794136541426404909382548728914233117625208163629202411762 ; p = 57896044618658097711785492504343953926634992332820282019728792003956564801911
Is prime: 1
