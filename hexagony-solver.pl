#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

# For a given column, get the starting index of the row
sub ceiling($) {
    my ($i) = @_;
    return ($i >= 4) ? ($i - 4) : (4 - $i);
}

sub height($) {
    my ($i) = @_;
    return (($i > 4) ? (12 - $i) : (4 + $i));
}

sub row_right_up($$) {
    my ($i, $j) = @_;

    if($i <= 4) {
        return $j - 1;
    } else {
        return $j;
    }
}

sub row_right_down($$) {
    my ($i, $j) = @_;

    if($i <= 4) {
        return $j;
    } else {
        return $j + 1;
    }
}

sub row_left_down($$) {
    my ($i, $j) = @_;

    if($i < 4) {
        return $j + 1;
    } else {
        return $j;
    }
}

sub row_left_up($$) {
    my ($i, $j) = @_;

    if($i < 4) {
        return $j;
    } else {
        return $j - 1;
    }
}

# Determine if one of the already fixed non-red hexes
sub is_occupied($$) {
    my ($i, $j) = @_;

    if($i == 4 && $j == 0) {
        return 1;
    } elsif($i == 6 && $j == 8) {
        return 1;
    }

    return 0;
}

sub in_bound($$) {
    my ($i, $j) = @_;

    if($i < 0 || $j < ceiling($i) || $i > 8 || $j > 8) {
        return 0;
    }

    return 1;
}

# Precompute how many hexes are visible from each hex
my @visibility = ();
for(my $i = 0; $i < 9; $i++) {
    for(my $j = ceiling($i); $j < 9; $j++) {

        print "\n\nAT ($i, $j)\n";

        # Start with visible hexes of same column
        my $visible = 8 - ceiling($i);

        # Eliminate blue 130321 and green 1 from column counts if needed
        if($i == 4 || $i == 6) {
            $visible--;
        }

        print "$visible in column\n";

        # Upper Right View
        my $i2 = $i + 1;
        my $j2 = row_right_up($i, $j);
        while(in_bound($i2, $j2)) {
            if(! is_occupied($i2, $j2)) {
                print "1) See: $i2, $j2\n";
                $visible++;
            }

            $i2++;
            $j2 = row_right_up($i2, $j2);
        }

        # Lower Right View
        $i2 = $i + 1;
        $j2 = row_right_down($i, $j);
        while(in_bound($i2, $j2)) {
            if(! is_occupied($i2, $j2)) {
                print "2) See: $i2, $j2\n";
                $visible++;
            }

            $i2++;
            $j2 = row_right_down($i2, $j2);
        }

        # Upper Left View
        $i2 = $i - 1;
        $j2 = row_left_up($i2, $j);
        while(in_bound($i2, $j2)) {
            if(! is_occupied($i2, $j2)) {
                print "3) See: $i2, $j2\n";
                $visible++;
            }

            $i2--;
            $j2 = row_left_up($i2, $j2);
        }

        # Lower Left View
        $i2 = $i - 1;
        $j2 = row_left_down($i2, $j);
        while(in_bound($i2, $j2)) {
            if(! is_occupied($i2, $j2)) {
                print "4) See: $i2, $j2\n";
                $visible++;
            }

            $i2--;
            $j2 = row_left_down($i2, $j2);
        }

        push(@{$visibility[$i]}, $visible);
    }
}

print Dumper(\@visibility);

# Try green 130321 in center column first, that seems most likely
for(my $green_row = 1; $green_row <= 8; $green_row++) {

    for(my $black1_row = 0; $black1_row <= 8; $black1_row++) {
        for(my $black1_row = 0; $black1_row <= 8; $black1_row++) {
            
        }
    }

}
