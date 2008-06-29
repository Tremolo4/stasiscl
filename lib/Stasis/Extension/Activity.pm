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

package Stasis::Extension::Activity;

use strict;
use warnings;

our @ISA = "Stasis::Extension";

sub start {
    my $self = shift;
    $self->{actors} = {};
    
    # No damage for this long will end a DPS span.
    $self->{_dpstimeout} = 5;
    
    # When a DPS span is closed, add this amount of buffer time.
    $self->{_dpsaddclose} = 5;
}

sub process {
    my ($self, $entry) = @_;
    
    if( grep $entry->{action} eq $_, qw(ENVIRONMENTAL_DAMAGE SWING_DAMAGE SWING_MISSED RANGE_DAMAGE RANGE_MISSED SPELL_DAMAGE DAMAGE_SPLIT SPELL_MISSED SPELL_PERIODIC_DAMAGE SPELL_PERIODIC_MISSED DAMAGE_SHIELD DAMAGE_SHIELD_MISSED) ) {
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
        
        # Create an empty hash if it does not exist yet.
        $self->{actors}{ $actor } ||= {
            start => 0,
            end => 0,
            time => 0,
        };
        
        my $adata = $self->{actors}{ $actor };
        
        # Track overall DPS time (independent of particular targets)
        if( !$adata->{start} ) {
            # This is the first DPS action, so mark the start of a span.
            $adata->{start} = $entry->{t};
            $adata->{end} = $entry->{t};
        } elsif( $adata->{end} + $self->{_dpstimeout} < $entry->{t} ) {
            # The last span ended, add it.
            $adata->{time} += ( $adata->{end} - $adata->{start} + $self->{_dpsaddclose} );
        
            # Reset the start and end times to the current time.
            $adata->{start} = $entry->{t};
            $adata->{end} = $entry->{t};
        } else {
            # The last span is continuing.
            $adata->{end} = $entry->{t};
        }
    }
}

sub finish {
    my $self = shift;
    
    # We need to close up all the un-closed dps spans.
    my $actor;
    foreach $actor (keys %{ $self->{actors} }) {
        # Close total DPS time.
        if( $self->{actors}{$actor}{start} ) {
            $self->{actors}{$actor}{time} += $self->{actors}{$actor}{end} - $self->{actors}{$actor}{start};
        }
    }
}

1;