#!/usr/bin/perl -w

# USAGE: 
# perl generate.latex.dirtree.perl <desired directory>

use strict;
use File::Find;
 
my $top = shift @ARGV;
die "specify top directory\n" unless defined $top;
chdir $top or die "cannot chdir to $top: $!\n";
 
find(sub {
            local $_ = $File::Find::name;
                my @F = split '/';
                    printf ".%d %s.\n", scalar @F, @F==1 ? $top : $F[-1];
                }, '.');
