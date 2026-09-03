#!/usr/bin/perl

# Inverse of Carmichael lambda function.

use 5.036;
use strict;
use warnings;

use Math::GMPz;
use Math::Prime::Util qw(divisors factor_exp);

sub _cook_carmichael_lambda($N) {

    my $p = Math::GMPz->new(0);
    my $v = Math::GMPz->new(0);

    my %L;
    my @D = divisors($N);

    foreach my $d (@D) {

        # Check if d + 1 is prime
        Math::Prime::Util::GMP::is_prime(Math::Prime::Util::GMP::addint("$d", 1)) || next;

        Math::GMPz::Rmpz_set_str($p, "$d", 10);
        Math::GMPz::Rmpz_add_ui($p, $p, 1);

        if (Math::GMPz::Rmpz_cmp_ui($p, 2) == 0) {
            my $t = Math::GMPz::Rmpz_remove($v, $N, $p);

            push @{$L{2}}, [Math::GMPz->new(1), Math::GMPz->new(2)];    # e=1

            if ($t >= 1) {
                push @{$L{2}}, [Math::GMPz->new(2), Math::GMPz->new(4)];    # e=2
            }

            foreach my $k (3 .. $t + 2) {                                   # e=k: x = 2^(k-2), y = 2^k
                my $x = Math::GMPz->new(0);
                my $y = Math::GMPz->new(0);
                Math::GMPz::Rmpz_ui_pow_ui($x, 2, $k - 2);
                Math::GMPz::Rmpz_ui_pow_ui($y, 2, $k);
                push @{$L{2}}, [$x, $y];
            }
            next;
        }

        my $t = Math::GMPz::Rmpz_remove($v, $N, $p);

        push @{$L{"$p"}}, map {
            my $x = Math::GMPz->new(0);
            my $y = Math::GMPz->new(0);

            Math::GMPz::Rmpz_pow_ui($v, $p, $_ - 1);
            Math::GMPz::Rmpz_pow_ui($y, $p, $_);
            Math::GMPz::Rmpz_sub_ui($x, $p, 1);
            Math::GMPz::Rmpz_mul($x, $x, $v);

            [$x, $y]
        } 1 .. $t + 1;
    }

    return [values %L];
}

sub _lcm_coverage_blocks($N, $L) {

    my @qf = factor_exp($N);
    my $r  = scalar(@qf);

    my @qz  = map { Math::GMPz->new("$_->[0]") } @qf;
    my $tmp = Math::GMPz->new(0);

    my @blocks_by_prime;

    foreach my $group (@$L) {
        my @blocks;
        foreach my $pair (@$group) {
            my ($x, $y) = @$pair;
            my $mask = 0;
            for my $j (0 .. $r - 1) {
                my $val = Math::GMPz::Rmpz_remove($tmp, $x, $qz[$j]);
                $mask |= (1 << $j) if $val == $qf[$j][1];
            }
            push @blocks, [$mask, $y];
        }
        push @blocks_by_prime, \@blocks;
    }

    return ($r, \@blocks_by_prime);
}

sub _dynamic_preimage_lcm($N, $L) {

    my ($r, $blocks_by_prime) = _lcm_coverage_blocks($N, $L);
    my $full_mask = (1 << $r) - 1;

    my %R = (0 => [Math::GMPz->new(1)]);

    foreach my $blocks (@$blocks_by_prime) {
        my %t;

        foreach my $block (@$blocks) {
            my ($bmask, $y) = @$block;

            foreach my $mask (keys %R) {
                my $nm = $mask | $bmask;

                push @{$t{$nm}}, map {
                    my $w = Math::GMPz->new(0);
                    Math::GMPz::Rmpz_mul($w, $_, $y);
                    $w;
                } @{$R{$mask}};
            }
        }

        foreach my $k (keys %t) {
            push @{$R{$k}}, @{delete $t{$k}};
        }
    }

    return $R{$full_mask} // [];
}

sub _dynamic_preimage_lcm_len_bigint($N, $L) {

    my ($r, $blocks_by_prime) = _lcm_coverage_blocks($N, $L);
    my $full_mask = (1 << $r) - 1;

    my %R = (0 => Math::GMPz->new(1));

    foreach my $blocks (@$blocks_by_prime) {
        my %t;

        foreach my $block (@$blocks) {
            my $bmask = $block->[0];

            foreach my $mask (keys %R) {
                my $nm = $mask | $bmask;
                $t{$nm} //= Math::GMPz->new(0);
                Math::GMPz::Rmpz_add($t{$nm}, $t{$nm}, $R{$mask});
            }
        }

        foreach my $k (keys %t) {
            $R{$k} //= Math::GMPz->new(0);
            Math::GMPz::Rmpz_add($R{$k}, $R{$k}, $t{$k});
        }
    }

    return exists($R{$full_mask}) ? Math::GMPz::Rmpz_get_str($R{$full_mask}, 10) : 0;
}

sub _dynamic_preimage_lcm_len($N, $L) {

    my ($r, $blocks_by_prime) = _lcm_coverage_blocks($N, $L);
    my $full_mask = (1 << $r) - 1;

    my %R = (0 => 1);

    foreach my $blocks (@$blocks_by_prime) {
        my %t;

        foreach my $block (@$blocks) {
            my $bmask = $block->[0];

            foreach my $mask (keys %R) {
                $t{$mask | $bmask} += $R{$mask};
            }
        }

        foreach my $k (keys %t) {
            $R{$k} += $t{$k};
        }
    }

    my $r_val = $R{$full_mask} // 0;
    ($r_val < ~0) || return _dynamic_preimage_lcm_len_bigint($N, $L);
    return $r_val;
}

sub _dynamic_preimage_lcm_minmax($N, $L, %opt) {

    my ($r, $blocks_by_prime) = _lcm_coverage_blocks($N, $L);
    my $full_mask = (1 << $r) - 1;
    my $min       = $opt{min};

    my %R = (0 => Math::GMPz->new(1));
    my $w = Math::GMPz->new(0);

    foreach my $blocks (@$blocks_by_prime) {
        my %t;

        foreach my $block (@$blocks) {
            my ($bmask, $y) = @$block;

            foreach my $mask (keys %R) {
                my $nm = $mask | $bmask;

                Math::GMPz::Rmpz_mul($w, $R{$mask}, $y);

                if (
                    !exists($t{$nm})
                    or (
                        $min
                        ? Math::GMPz::Rmpz_cmp($w, $t{$nm}) < 0
                        : Math::GMPz::Rmpz_cmp($w, $t{$nm}) > 0
                       )
                  ) {
                    $t{$nm} = Math::GMPz->new($w);
                }
            }
        }

        foreach my $k (keys %t) {
            if (
                !exists($R{$k})
                or (
                    $min
                    ? Math::GMPz::Rmpz_cmp($t{$k}, $R{$k}) < 0
                    : Math::GMPz::Rmpz_cmp($t{$k}, $R{$k}) > 0
                   )
              ) {
                $R{$k} = $t{$k};
            }
        }
    }

    return $R{$full_mask};
}

sub inverse_carmichael_lambda($n) {
    $n = Math::GMPz->new("$n");

    if (Math::GMPz::Rmpz_sgn($n) <= 0) {
        return [Math::GMPz->new(0)] if !Math::GMPz::Rmpz_sgn($n);
        return [];
    }

    my $result = _dynamic_preimage_lcm($n, _cook_carmichael_lambda($n));
    return [sort { Math::GMPz::Rmpz_cmp($a, $b) } @$result];
}

sub inverse_carmichael_lambda_len($n) {
    $n = Math::GMPz->new("$n");

    if (Math::GMPz::Rmpz_sgn($n) <= 0) {
        return 1 if !Math::GMPz::Rmpz_sgn($n);
        return 0;
    }

    return _dynamic_preimage_lcm_len($n, _cook_carmichael_lambda($n));
}

sub inverse_carmichael_lambda_min($n) {
    $n = Math::GMPz->new("$n");

    if (Math::GMPz::Rmpz_sgn($n) <= 0) {
        return Math::GMPz->new(0) if !Math::GMPz::Rmpz_sgn($n);
        return undef;
    }

    return _dynamic_preimage_lcm_minmax($n, _cook_carmichael_lambda($n), min => 1);
}

sub inverse_carmichael_lambda_max($n) {
    $n = Math::GMPz->new("$n");

    if (Math::GMPz::Rmpz_sgn($n) <= 0) {
        return Math::GMPz->new(0) if !Math::GMPz::Rmpz_sgn($n);
        return undef;
    }

    return _dynamic_preimage_lcm_minmax($n, _cook_carmichael_lambda($n), min => 0);
}

my $val = 12;
print "Carmichael Lambda Inverse for $val:\n";

my $inverses = inverse_carmichael_lambda($val);
print "  Values: ", join(", ", @$inverses), "\n";

print "  Count:  ", inverse_carmichael_lambda_len($val), "\n";
print "  Min:    ", inverse_carmichael_lambda_min($val), "\n";
print "  Max:    ", inverse_carmichael_lambda_max($val), "\n";
