#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date 15 May 2014
# http://github.com/trizen/sidef

# Sidef structure optimizer - under development...

use utf8;
use 5.010;
use strict;
use warnings;

use Data::Dump qw(pp);

sub flatten {
    my ($arr) = @_;

    foreach my $item (@{$arr}) {
        if (ref $item eq 'ARRAY') {
            return flatten($item);
        }
    }

    return $arr;
}

sub class_optimizer {
    my ($hash) = @_;

    if (not exists $hash->{self}) {
        foreach my $class (keys %{$hash}) {
            $hash = $hash->{$class} //= [];
            foreach my $i (0 .. $#{$hash}) {
                $hash->[$i] = class_optimizer($hash->[$i]);
            }
        }
    }

    return $hash;
}

sub optimize {
    my ($hash) = @_;

    if (exists $hash->{self}) {
        if (not exists $hash->{ind} and not exists $hash->{call} and ref($hash->{self}) eq 'HASH') {
            $hash = optimize($hash->{self});
        }
    }
    else {
        my @keys = keys %{$hash};
        foreach my $key (@keys) {
            foreach my $expr (@{$hash->{$key}}) {
                $expr = optimize($expr);
            }
        }
    }

    return $hash;
}

#<<<
my $struct = {
  main => [
    {
      self => {
        main => [
          {
            self => {
              main => [
                {
                  self => {
                    main => [
                      {
                        self => {
                          main => [
                            {
                              self => {
                                main => [
                                  {
                                    self => "BINGO_1",
                                  },
                                  {
                                    self => "BINGO_2",
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
};
#>>>

pp optimize($struct);
pp flatten(class_optimizer($struct));
