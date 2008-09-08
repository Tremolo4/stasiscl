# Copyright (c) 2008, Gian Merlino
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package Stasis::Extension::Damage;

use strict;
use warnings;
use Carp;
use Stasis::Extension qw(ext_copy ext_sum);

our @ISA = "Stasis::Extension";

sub start {
    my $self = shift;
    $self->{actors} = {};
    $self->{targets} = {};
}

sub actions {
    return qw(ENVIRONMENTAL_DAMAGE SWING_DAMAGE SWING_MISSED RANGE_DAMAGE RANGE_MISSED SPELL_DAMAGE DAMAGE_SPLIT SPELL_MISSED SPELL_PERIODIC_DAMAGE SPELL_PERIODIC_MISSED DAMAGE_SHIELD DAMAGE_SHIELD_MISSED);
}

sub process {
    my ($self, $entry) = @_;
    
    # This was a damage event, or an attempted damage event.
    
    # We are going to take some liberties with environmental damage and white damage in order to get them
    # into the neat actor > spell > target framework. Namely an abuse of actor IDs and spell IDs (using
    # "0" as an actor ID for the environment and using "0" for the spell ID to signify a white hit). These
    # will both fail to look up in Index, but that's okay.
    my $actor;
    my $spell;
    if( $entry->{action} eq "ENVIRONMENTAL_DAMAGE" ) {
        $actor = 0;
        $spell = 0;
    } elsif( $entry->{action} eq "SWING_DAMAGE" || $entry->{action} eq "SWING_MISSED" ) {
        $actor = $entry->{actor};
        $spell = 0;
    } else {
        $actor = $entry->{actor};
        $spell = $entry->{extra}{spellid};
    }
    
    # Get the spell hash.
    my $ddata = ($self->{actors}{ $actor }{ $spell }{ $entry->{target} } ||= {});
    
    # Add to targets.
    $self->{targets}{ $entry->{target} }{ $spell }{ $actor } ||= $ddata;
    
    # Check if this was a hit or a miss.
    if( $entry->{extra}{amount} ) {
        # HIT
        # Classify the damage WWS-style as a "hit", "crit", or "tick".
        my $type;
        if( $entry->{action} eq "SPELL_PERIODIC_DAMAGE" ) {
            $type = "tick";
        } elsif( $entry->{extra}{critical} ) {
            $type = "crit";
        } else {
            $type = "hit";
        }
        
        # Add the damage to the total for this spell.
        $ddata->{count} += 1;
        $ddata->{total} += $entry->{extra}{amount};
        
        # Add the damage to the total for this type of hit (hit/crit/tick).
        $ddata->{"${type}Count"} += 1;
        $ddata->{"${type}Total"} += $entry->{extra}{amount};
        
        # Update min/max hit size.
        $ddata->{"${type}Min"} = $entry->{extra}{amount}
            if( 
                !$ddata->{"${type}Min"} ||
                $entry->{extra}{amount} < $ddata->{"${type}Min"}
            );

        $ddata->{"${type}Max"} = $entry->{extra}{amount}
            if( 
                !$ddata->{"${type}Max"} ||
                $entry->{extra}{amount} > $ddata->{"${type}Max"}
            );
        
        # Add any mods.
        if( $entry->{extra}{blocked} ) {
            $ddata->{partialBlockCount} ++;
            $ddata->{partialBlockTotal} += $entry->{extra}{blocked};
        }
        
        if( $entry->{extra}{resisted} ) {
            $ddata->{partialResistCount} ++;
            $ddata->{partialResistTotal} += $entry->{extra}{resisted};
        }
        
        if( $entry->{extra}{absorbed} ) {
            $ddata->{partialAbsorbCount} ++;
            $ddata->{partialAbsorbTotal} += $entry->{extra}{absorbed};
        }
        
        $ddata->{crushing}++ if $entry->{extra}{crushing};
        $ddata->{glancing}++ if $entry->{extra}{glancing};
    } elsif( $entry->{extra}{misstype} ) {
        # MISS
        $ddata->{count} += 1;
        $ddata->{ lc( $entry->{extra}{misstype} ) . "Count" }++;
    }
}

sub sum {
    my $self = shift;
    my %params = @_;
    
    $params{actor} ||= [];
    $params{spell} ||= [];
    $params{target} ||= [];
    $params{expand} ||= [];
    
    # Filter the expand list.
    my @expand = map { $_ eq "actor" || $_ eq "spell" || $_ eq "target" ? $_ : () } @{$params{expand}};
    
    # Measure the size of our inputs.
    my ( $asz, $ssz, $tsz ) = ( scalar( @{$params{actor}} ), scalar( @{$params{spell}} ), scalar( @{$params{target}} ) );
    
    # We'll eventually return this.
    my %ret;
    
    # We can start with actors or targets. Start with the one we need less from.
    my $start = $tsz && (!$asz || $tsz < $asz) ? $self->{targets} : $self->{actors};
    my $list1 = $tsz && (!$asz || $tsz < $asz) ? $params{target} : $params{actor};
    my $list2 = $tsz && (!$asz || $tsz < $asz) ? $params{actor} : $params{target};

    foreach my $k1 (scalar @$list1 ? @$list1 : keys %$start) {
        my $v1 = $start->{$k1} or next;

        foreach my $kspell ($ssz ? @{$params{spell}} : keys %$v1) {
            my $vspell = $v1->{$kspell} or next;
            
            foreach my $k2 (scalar @$list2 ? @$list2 : keys %$vspell) {
                my $v2 = $vspell->{$k2} or next;
                
                my $ref = \%ret;
                foreach (@expand) {
                    my $key;
                    if( $_ eq "spell" ) {
                        $key = $kspell;
                    } elsif( $_ eq "target" ) {
                        $key = $start == $self->{targets} ? $k1 : $k2;
                    } else {
                        # actor
                        $key = $start == $self->{actors} ? $k1 : $k2;
                    }
                    
                    $ref = $ref->{$key} ||= {};
                }
                
                ext_sum( $ref, $v2 );
            }
        }
    }
    
    return \%ret;
}

1;
