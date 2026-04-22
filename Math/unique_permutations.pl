#!/usr/bin/perl

# Generate only the unique permutations of a given array.

# Optimized Unique Permutation DFS without explicit key tracking
# Recursively branches unique factors only at each depth.

use 5.036;

sub unique_permutations($array, $callback) {
    sub ($items, $current_perm) {

        if (!@$items) {
            $callback->($current_perm);
            return;
        }

        my %level_seen;
        for my $i (0 .. $#$items) {
            my $item = $items->[$i];

            # Skip iterations for duplicate elements in the same level
            next if $level_seen{$item}++;

            my @new_items = @$items;
            splice(@new_items, $i, 1);

            my @new_perm = (@$current_perm, $item);
            __SUB__->(\@new_items, \@new_perm);
        }
    }->($array, []);
}

unique_permutations(
    [3, 2, 2, 3],
    sub ($perm) {
        say "(@$perm)";
    }
);

__END__
(3 2 2 3)
(3 2 3 2)
(3 3 2 2)
(2 3 2 3)
(2 3 3 2)
(2 2 3 3)
