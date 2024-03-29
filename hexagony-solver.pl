#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

#####
### Foreword: yes, towards the end, this code gets messy.
### That seems to be a natural part of writing a constraint
### solver in an ad-hoc fashion in very little time.
### WARNING: tons of copy/paste below
#####

my @NONE;

# Red points originally placed on the puzzle
my @RED_169 = (0, 6);
my @RED_0_1 = (8, 6);
my @RED_0_2 = (2, 8);
my @RED_POINTS = (\@RED_169, \@RED_0_1, \@RED_0_2);
my @GREEN_1 = (6, 8);

my $PRIMARY_BLACK_MIN   = 19;
my $SECONDARY_BLACK_MIN = 13;

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

    if($i < 4) {
        return $j - 1;
    } else {
        return $j;
    }
}

sub row_right_down($$) {
    my ($i, $j) = @_;

    if($i < 4) {
        return $j;
    } else {
        return $j + 1;
    }
}

sub row_left_down($$) {
    my ($i, $j) = @_;

    if($i <= 4) {
        return $j + 1;
    } else {
        return $j;
    }
}

sub row_left_up($$) {
    my ($i, $j) = @_;

    if($i <= 4) {
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
        } elsif (! is_occupied($i, $j2, @points)) {
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

        $j2 = row_right_up($i2, $j2);
        $i2++;
    }

    # Lower Right View
    $i2 = $i + 1;
    $j2 = row_right_down($i, $j);
    while(in_bound($i2, $j2)) {
        if(! is_occupied($i2, $j2, @points)) {
            $visible++;
        }

        $j2 = row_right_down($i2, $j2);
        $i2++;
    }

    # Upper Left View
    $i2 = $i - 1;
    $j2 = row_left_up($i2, $j);
    while(in_bound($i2, $j2)) {
        if(! is_occupied($i2, $j2, @points)) {
            $visible++;
        }

        $j2 = row_left_up($i2, $j2);
        $i2--;
    }

    # Lower Left View
    $i2 = $i - 1;
    $j2 = row_left_down($i2, $j);
    while(in_bound($i2, $j2)) {
        if(! is_occupied($i2, $j2, @points)) {
            $visible++;
        }

        $j2 = row_left_down($i2, $j2);
        $i2--;
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

        $j2 = row_right_up($i2, $j2);
        $i2++;
    }

    # Lower Right View
    $i2 = $i + 1;
    $j2 = row_right_down($i, $j);
    while(in_bound($i2, $j2)) {
        if($i2 == $i_target && $j2 == $j_target) {
            return 1;
        }

        $j2 = row_right_down($i2, $j2);
        $i2++;
    }

    # Upper Left View
    $i2 = $i - 1;
    $j2 = row_left_up($i2, $j);
    while(in_bound($i2, $j2)) {
        if($i2 == $i_target && $j2 == $j_target) {
            return 1;
        }

        $j2 = row_left_up($i2, $j2);
        $i2--;
    }

    # Lower Left View
    $i2 = $i - 1;
    $j2 = row_left_down($i2, $j);
    while(in_bound($i2, $j2)) {
        if($i2 == $i_target && $j2 == $j_target) {
            return 1;
        }

        $j2 = row_left_down($i2, $j2);
        $i2--;
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


### Check conditions for a specific point,
### specifically how many empty (red) hexes are visible,
### if specific points are visible, and if specific points
### are not visible.
#   Arguments: column, row, min empty hexes seen,
#              array ref of points that are occupied by non-red,
#              array ref of points that should be seen,
#              array ref of points that shouldn't be seen
sub check_rules($$$$$$) {
    my ($i, $j, $min_visibility, $points, $should_see, $shouldnt_see) = @_;

    if($min_visibility > 0 && get_empty_visibility($i, $j, @{$points}) < $min_visibility) {
        return 0;
    }

    for my $point (@{$should_see}) {
        my @point = @{$point};
        if(! is_visible_from($i, $j, $point[0], $point[1])) {
            return 0;
        }
    }

    for my $point (@{$shouldnt_see}) {
        my @point = @{$point};
        if(is_visible_from($i, $j, $point[0], $point[1])) {
            return 0;
        }
    }

    return 1;
}


sub is_viable_black_19($$@) {
    my ($black_row, $black_col, @points) = @_;

    my @occupied_points;
    push(@occupied_points, @points);
    push(@occupied_points, @RED_POINTS);
    if(is_occupied($black_row, $black_col, @occupied_points)) {
        return 0;
    }

    # If not visible to green 130,321, then skip
    my $green_point = $points[0]; # An array ref of (row, col) for the green 130,321
    my @should_see = ($green_point);

    # Can't be visible to Green 1 on board, or it wouldn't be a 1
    my @shouldnt_see = (\@GREEN_1);

    return check_rules($black_row, $black_col, $PRIMARY_BLACK_MIN, \@points, \@should_see, [\@GREEN_1]);
}


### See the @points array below, which is in order of
### green 130321, black 19, black 19, black 19, black 19,
### blue 169, green 169, black 13, black 13
### and make sure that the black points see enough blank hexes
### that we will be filling in as red in our final solution
sub check_points_visibility(@) {
    my (@points) = @_;

    for(my $i = 1; $i < scalar(@points); $i++) {
        # Skip the blue and green2
        if($i == 5) {
            $i = 6;
            next;
        }

        my @point = @{$points[$i]};
        my $visible_count = get_empty_visibility($point[0], $point[1], @points);

        if($i < 5) {
            if($visible_count < 19) {
                return 0;
            }
        } else {
            if($visible_count < $SECONDARY_BLACK_MIN) {
                return 0;
            }
        }
    }

    return 1;
}

####
#### Step 1: Find an arrangement of green 130321, and four black 19s.
####         Store these in the %candidates hash, sorting the 19s so
####         that we automatically remove permutations of the same 
####         candidates spaces for the 19s
####


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

            if(! is_viable_black_19($black1_row, $black1_col, @points)) {
                next;
            }
            
            my @black1 = ($black1_row, $black1_col);
            push(@points, \@black1);

            #### Try to place the third Black 19
            for(my $black2_row = 0; $black2_row <= 8; $black2_row++) {
                for(my $black2_col = ceiling($black2_row); $black2_col <= 8; $black2_col++) {

                    if(! is_viable_black_19($black2_row, $black2_col, @points)) {
                        next;
                    }

                    my @black2 = ($black2_row, $black2_col);
                    push(@points, \@black2);

                    #### Try to place the third Black 19
                    for(my $black3_row = 0; $black3_row <= 8; $black3_row++) {
                        for(my $black3_col = ceiling($black3_row); $black3_col <= 8; $black3_col++) {

                            if(! is_viable_black_19($black3_row, $black3_col, @points)) {
                                next;
                            }

                            my @black3 = ($black3_row, $black3_col);
                            push(@points, \@black3);

                            #### Try to place the fourth Black 19
                            for(my $black4_row = 0; $black4_row <= 8; $black4_row++) {
                                for(my $black4_col = ceiling($black4_row); $black4_col <= 8; $black4_col++) {

                                    if(! is_viable_black_19($black4_row, $black4_col, @points)) {
                                        next;
                                    }

                                    my @black4 = ($black4_row, $black4_col);
                                    push(@points, \@black4);


                                    ### Whew! If we've gotten this far, then we have laid out a 
                                    ### Green 130321, which is visible from four black 19s.
                                    ### Well, at least they were 19s or more when we last checked, so
                                    ### we better check them again now that more hexes have been set

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


my %final_candidates;

@points = ();
while(my ($green, $remainder) = each %candidates) {
    my @green_point = split(/,/, $green);
    push(@points, \@green_point);

    while(my ($black1, $remainder2) = each %{$remainder}) {
        my @black1_point = split(/,/, $black1);
        push(@points, \@black1_point);

        while(my ($black2, $remainder3) = each %{$remainder2}) {
            my @black2_point = split(/,/, $black2);
            push(@points, \@black2_point);

            while(my ($black3, $remainder4) = each %{$remainder3}) {
                my @black3_point = split(/,/, $black3);
                push(@points, \@black3_point);

                while(my ($black4, $nothing) = each %{$remainder4}) {
                    my @black4_point = split(/,/, $black4);
                    push(@points, \@black4_point);

                    
                    # For this Candidate set of 1 green and 4 black points
                    # try to find a spot for a blue 169 visible from the red 169
                    for(my $blue_row = 0; $blue_row <= 8; $blue_row++) {
                        for(my $blue_col = ceiling($blue_row); $blue_col <= 8; $blue_col++) {

                            my @occupied_points;
                            push(@occupied_points, @points);
                            push(@occupied_points, @RED_POINTS);

                            if(is_occupied($blue_row, $blue_col, @occupied_points)) {
                                next;
                            }

                            # If not visible to red 169, then skip
                            my @should_see = (\@RED_169);

                            # If is visible to green 130,321 then this won't work
                            my @shouldnt_see = (\@green_point);

                            if(! check_rules($blue_row, $blue_col, 0, \@points, \@should_see, \@shouldnt_see)) {
                                next;
                            }

                            my @blue_point = ($blue_row, $blue_col);
                            push(@points, \@blue_point);

                            if(check_points_visibility(@points)) {
                                # Okay! If the previous constraints are still met,
                                # then we need to place a green number visible from this blue
                                # number, but not visible from the black 19s
                                for(my $green2_row = 0; $green2_row <= 8; $green2_row++) {
                                    for(my $green2_col = ceiling($green2_row); $green2_col <= 8; $green2_col++) {

                                        my @occupied_points;
                                        push(@occupied_points, @points);
                                        push(@occupied_points, @RED_POINTS);

                                        if(is_occupied($green2_row, $green2_col, @occupied_points)) {
                                            next;
                                        }

                                        # If not visible to blue 169, then skip
                                        my @should_see = ([$blue_row, $blue_col]);

                                        # If is visible to any of the black 19s, then won't get to 169 product
                                        my @shouldnt_see = (\@black1_point, \@black2_point, \@black3_point, \@black4_point);

                                        if(! check_rules($blue_row, $blue_col, 0, \@points, \@should_see, \@shouldnt_see)) {
                                            next;
                                        }


                                        my @green2_point = ($green2_row, $green2_col);
                                        push(@points, \@green2_point);

                                        if(check_points_visibility(@points)) {
                                            for(my $black5_row = 0; $black5_row <= 8; $black5_row++) {
                                                for(my $black5_col = ceiling($black5_row); $black5_col <= 8; $black5_col++) {

                                                    my @occupied_points;
                                                    push(@occupied_points, @points);
                                                    push(@occupied_points, @RED_POINTS);

                                                    if(is_occupied($black5_row, $black5_col, @occupied_points)) {
                                                        next;
                                                    }

                                                    # If not visible to green 169, then skip
                                                    my @should_see = ([$green2_row, $green2_col]);

                                                    # If is visible to green 130,321 then this won't work
                                                    my @shouldnt_see = (\@green_point);

                                                    if(! check_rules($black5_row, $black5_col, $SECONDARY_BLACK_MIN, \@points, \@should_see, \@shouldnt_see)) {
                                                        next;
                                                    }

                                                    my @black5_point = ($black5_row, $black5_col);
                                                    push(@points, \@black5_point);

                                                    if(check_points_visibility(@points)) {
                                                        for(my $black6_row = 0; $black6_row <= 8; $black6_row++) {
                                                            for(my $black6_col = ceiling($black6_row); $black6_col <= 8; $black6_col++) {

                                                                my @occupied_points;
                                                                push(@occupied_points, @points);
                                                                push(@occupied_points, @RED_POINTS);

                                                                if(is_occupied($black6_row, $black6_col, @occupied_points)) {
                                                                    next;
                                                                }

                                                                # If not visible to green 169, then skip
                                                                my @should_see = ([$green2_row, $green2_col]);

                                                                # If is visible to green 130,321 then this won't work
                                                                my @shouldnt_see = (\@green_point);

                                                                if(! check_rules($black6_row, $black6_col, $SECONDARY_BLACK_MIN, \@points, \@should_see, \@shouldnt_see)) {
                                                                    next;
                                                                }
                                                               
                                                                my @black6_point = ($black6_row, $black6_col);
                                                                push(@points, \@black6_point);

                                                                if(check_points_visibility(@points)) {
                                                                    my @blacks;
                                                                    push(@blacks, $black5_row . "," . $black5_col);
                                                                    push(@blacks, $black6_row . "," . $black6_col);
                                                                    @blacks = sort { $a cmp $b } @blacks;

                                                                    $final_candidates{$green}{$black1}{$black2}{$black3}{$black4}{"$blue_row,$blue_col"}{"$green2_row,$green2_col"}{$blacks[0]}{$blacks[1]} = 1;

                                                                }

                                                                pop(@points);
                                                            }
                                                        }
                                                    }

                                                    pop(@points);
                                                }
                                            }
                                        }

                                        pop(@points);
                                    }
                                }
                            }

                            pop(@points);
                        }
                    }

                    pop(@points);
                }

                pop(@points);
            }

            pop(@points);
        }

        pop(@points);
    }

    pop(@points);
}

print "Key ordering: green 130321, black 19, black 19, black 19, black 19, blue 169, green 169, black 13, black 13\n";
print "Assume all other hexes are RED.\n";
print Dumper(\%final_candidates);

