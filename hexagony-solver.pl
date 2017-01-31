#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my @NONE;

# For a given column, get the starting index of the row
sub ceiling($) {
    my ($i) = @_;
    return ($i >= 4) ? ($i - 4) : (4 - $i);
}

# Return number of hexes in a column
sub height($) {
    my ($i) = @_;
    return (($i > 4) ? (12 - $i) : (4 + $i));
}

## Determine if a point has one of the already fixed non-red hexes or
## a user specified point in an array of points
#  Arguments: column, row, array of points that have been set
sub is_occupied($$@) {
    my ($i, $j, @points) = @_;

    if($i == 4 && $j == 0) {
        return 1;
    } elsif($i == 6 && $j == 8) {
        return 1;
    }

    if(@points) {
        for my $point (@points) {
            my ($i2, $j2) = @{$point};
            if($i2 == $i && $j2 == $j) {
                return 1;
            }
        }
    }

    return 0;
}



### The following four functions help in get_empty_visibility
# Arguments: column, row
# Returns: row number to use when travelling in specified direction

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

## Find how many empty (or red) hexes are visible from a point
#  Arguments: column, row, points occupied by non-red number
#                          (not including starting points)
sub get_empty_visibility($$@) {
    my ($i, $j, @points) = @_;

    # Start with visible hexes of same column
    my $visible = 0;

    for(my $j2 = 8; $j2 >= ceiling($i); $j2--) {
        if($j2 == $j) {
            next;
        } elsif (! is_occupied($i, $j2)) {
            $visible++;
        }
    }

    # Upper Right View
    my $i2 = $i + 1;
    my $j2 = row_right_up($i, $j);
    while(in_bound($i2, $j2)) {
        if(! is_occupied($i2, $j2, @points)) {
            $visible++;
        }

        $i2++;
        $j2 = row_right_up($i2, $j2);
    }

    # Lower Right View
    $i2 = $i + 1;
    $j2 = row_right_down($i, $j);
    while(in_bound($i2, $j2)) {
        if(! is_occupied($i2, $j2, @points)) {
            $visible++;
        }

        $i2++;
        $j2 = row_right_down($i2, $j2);
    }

    # Upper Left View
    $i2 = $i - 1;
    $j2 = row_left_up($i2, $j);
    while(in_bound($i2, $j2)) {
        if(! is_occupied($i2, $j2, @points)) {
            $visible++;
        }

        $i2--;
        $j2 = row_left_up($i2, $j2);
    }

    # Lower Left View
    $i2 = $i - 1;
    $j2 = row_left_down($i2, $j);
    while(in_bound($i2, $j2)) {
        if(! is_occupied($i2, $j2, @points)) {
            $visible++;
        }

        $i2--;
        $j2 = row_left_down($i2, $j2);
    }

    return $visible;
}

## Determine if a point is visible from another point
## This is mostly a copy and paste of get_empty_visibility, which is ugly
#  Arugments: column1, row1, column2, row2
sub is_visible_from($$$$) {
    my ($i, $j, $i_target, $j_target) = @_;

    if($i == $i_target) {
        return 1;
    }

    # Upper Right View
    my $i2 = $i + 1;
    my $j2 = row_right_up($i, $j);
    while(in_bound($i2, $j2)) {
        if($i2 == $i_target && $j2 == $j_target) {
            return 1;
        }

        $i2++;
        $j2 = row_right_up($i2, $j2);
    }

    # Lower Right View
    $i2 = $i + 1;
    $j2 = row_right_down($i, $j);
    while(in_bound($i2, $j2)) {
        if($i2 == $i_target && $j2 == $j_target) {
            return 1;
        }

        $i2++;
        $j2 = row_right_down($i2, $j2);
    }

    # Upper Left View
    $i2 = $i - 1;
    $j2 = row_left_up($i2, $j);
    while(in_bound($i2, $j2)) {
        if($i2 == $i_target && $j2 == $j_target) {
            return 1;
        }

        $i2--;
        $j2 = row_left_up($i2, $j2);
    }

    # Lower Left View
    $i2 = $i - 1;
    $j2 = row_left_down($i2, $j);
    while(in_bound($i2, $j2)) {
        if($i2 == $i_target && $j2 == $j_target) {
            return 1;
        }

        $i2--;
        $j2 = row_left_down($i2, $j2);
    }

    return 0;

}
## Determines if a point is in bounds of the game
#  Arguments: column, row
sub in_bound($$) {
    my ($i, $j) = @_;

    if($i < 0 || $j < ceiling($i) || $i > 8 || $j > 8) {
        return 0;
    }

    return 1;
}

# # Precompute how many hexes are visible from each hex
# my @visibility = ();
# for(my $i = 0; $i < 9; $i++) {
#     for(my $j = ceiling($i); $j < 9; $j++) {
#         push(@{$visibility[$i]}, get_empty_visibility($i, $j, @NONE));
#     }
# }
# 
# print Dumper(\@visibility);


# Points array that expands/shrinks as we add and remove candidates
my @points;
my %candidates;

# Try green 130321 in center column first, that seems most likely
my $green_row = 4;
for(my $green_col = 1; $green_col <= 8; $green_col++) {
    my @green = ($green_row, $green_col);
    push(@points, \@green);

    for(my $black1_row = 0; $black1_row <= 8; $black1_row++) {
        for(my $black1_col = ceiling($black1_row); $black1_col <= 8; $black1_col++) {

            # Early exit if this is an impossible spot for a black 19
            if(get_empty_visibility($black1_row, $black1_col, @points) < 19) {
                next;
            } elsif ($black1_row == $green_row && $black1_col == $green_col) {
                next;
            } elsif (! is_visible_from($black1_row, $black1_col, $green_row, $green_col)) {
                next;
            }
            
            my @black1 = ($black1_row, $black1_col);
            push(@points, \@black1);

            for(my $black2_row = 0; $black2_row <= 8; $black2_row++) {
                for(my $black2_col = ceiling($black2_row); $black2_col <= 8; $black2_col++) {

                    # Early exit if this is an impossible spot for a black 19
                    if(get_empty_visibility($black2_row, $black2_col, @points) < 19) {
                        next;
                    } elsif ($black2_row == $green_row && $black2_col == $green_col) {
                        next;
                    } elsif (! is_visible_from($black2_row, $black2_col, $green_row, $green_col)) {
                        next;
                    }

                    # Skip to next row/col if collision
                    if($black2_row == $black1_row && $black2_col == $black1_col) {
                        next;
                    }

                    my @black2 = ($black2_row, $black2_col);
                    push(@points, \@black2);

                    for(my $black3_row = 0; $black3_row <= 8; $black3_row++) {
                        for(my $black3_col = ceiling($black2_row); $black3_col <= 8; $black3_col++) {

                            # Early exit if this is an impossible spot for a black 19
                            if(get_empty_visibility($black3_row, $black3_col, @points) < 19) {
                                next;
                            } elsif ($black3_row == $green_row && $black3_col == $green_col) {
                                next;
                            }

                            # Skip to next row/col if collision
                            if($black3_row == $black1_row && $black3_col == $black1_col) {
                                next;
                            } elsif($black3_row == $black2_row && $black3_col == $black2_col) {
                                next;
                            } elsif (! is_visible_from($black3_row, $black3_col, $green_row, $green_col)) {
                                next;
                            }

                            my @black3 = ($black3_row, $black3_col);
                            push(@points, \@black3);

                            for(my $black4_row = 0; $black4_row <= 8; $black4_row++) {
                                for(my $black4_col = ceiling($black2_row); $black4_col <= 8; $black4_col++) {

                                    # Early exit if this is an impossible spot for a black 19
                                    if(get_empty_visibility($black4_row, $black4_col, @points) < 19) {
                                        next;
                                    } elsif ($black4_row == $green_row && $black4_col == $green_col) {
                                        next;
                                    } elsif (! is_visible_from($black4_row, $black4_col, $green_row, $green_col)) {
                                        next;
                                    }

                                    # Skip to next row/col if collision
                                    if($black4_row == $black1_row && $black4_col == $black1_col) {
                                        next;
                                    } elsif($black4_row == $black2_row && $black4_col == $black2_col) {
                                        next;
                                    } elsif($black4_row == $black3_row && $black4_col == $black3_col) {
                                        next;
                                    }

                                    my @black4 = ($black4_row, $black4_col);
                                    push(@points, \@black4);


                                    ### Whew! If we've gotten this far, then we have laid out a 
                                    ### Green 130321, which is visible from four black 19s,
                                    ### at least they were 19s or more when we last checked, so
                                    ### we better check them again

                                    my $good = 1;
                                    for(my $i = 1; $i < scalar(@points); $i++) {
                                        my @point = @{$points[$i]};
                                        my $visible_count = get_empty_visibility($point[0], $point[1], @points);

                                        # print "$i : $visible_count\n";

                                        if($visible_count < 19) {
                                            $good = 0;
                                            last;
                                        }
                                    }

                                    if($good) {
                                        my $green = $points[0];
                                        my @green = @{$green};
                                        my $key = $green[0] . "," . $green[1];

                                        my @keys;
                                        for(my $i = 1; $i < scalar(@points); $i++) {
                                            my @point = @{$points[$i]};
                                            push(@keys, $point[0] . "," . $point[1]);
                                        }

                                        @keys = sort { $a cmp $b } @keys;

                                        $candidates{$key}{$keys[0]}{$keys[1]}{$keys[2]}{$keys[3]} = 1;
                                    }

                                    # Remove this black point (4)
                                    pop(@points);
                                }
                            }

                            # Remove this black point (3)
                            pop(@points);
                        }
                    }

                    # Remove this black point (2)
                    pop(@points);
                }
            }

            # Remove this black point (1)
            pop(@points);
        }
    }

    # Remove this green point (1)
    pop(@points);
}

print Dumper(\%candidates) , "\n\n";
