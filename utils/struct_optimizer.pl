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

sub strip_classes {
    my ($ref) = @_;

    foreach my $item (@{$ref}) {
        if (not exists $item->{self}) {
            foreach my $class (keys %{$item}) {
                $ref = strip_classes($item->{$class});
            }
        }
    }

    return $ref;
}

sub class_optimizer {
    my ($hash) = @_;

    if (not exists $hash->{self}) {
        foreach my $class (keys %{$hash}) {
            $hash->{$class} = strip_classes($hash->{$class});
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
pp class_optimizer($struct);
