# Stasis/Parser.pm #

The parser is a perl module reads both 2.3 and 2.4 logs, line by line. It must be told in advance whether the log will be 2.3 or 2.4 by setting a "version" tag to "1" or "2". It exposes the two methods parse($line), which returns a hash corresponding to a single log line, and toString($hashref) which returns a more human readable string corresponding to such a hash.

One thing that is important to note is that the 2.3 parser is not localized and currently only works on English logs. Each log line is converted into a Perl hash that can be used for analysis or printed with an included toString function. The hash will be a member of the class `Stasis::Event` and will always have the following keys:

  * **action**: an integer that corresponds to a constant in `Stasis::Event`. SPELL\_DAMAGE, SWING\_MISS, UNIT\_DIED, etc
  * **t**: standard UNIX timestamp (seconds since epoch) but preserving the millisecond accuracy
  * **actor**: a string unique ID for the actor (i.e. source) in this log line. For 2.4 logs this is the GUID, a string like "0x00323...". For 2.3 logs this is the same as `actor_name`.
  * **actor\_name**: the name of the actor as it appears in game
  * **actor\_relationship**: a bit field describing the relationship of the actor to the logger. This is not stored as a string (for example "0x514", which means a friendly player in the logger's raid) but is stored as the actual value that string corresponds to (in that case, 1300).
  * **target**, **target\_name**, and **target\_relationship**: same as the `actor` keys, but for the target of the action.

There will be more keys that correspond to action-specific fields. For example, a SPELL\_DAMAGE event will have keys such as `spellid`, `spellname`, `amount`, among others.

## Event methods ##

`Stasis::Parser` will return a `Stasis::Event` object when you ask it to parse a line. You can call these methods on it:

  * **toString**: return a string representation of the event, or an empty string if the parser isn't sure how to convert this event into one.
  * **timeString**: return a string representation of the event time, formatted the same way it would be in the original combat log.
  * **actionName**: return the action name, as it was written in the original combat log. Something like `SWING_DAMAGE` or `SPELL_DRAIN`.
  * **powerName**: for events with power types (e.g. `SPELL_ENERGIZE`), returns the name of the power. Something like "mana", "rage", etc.

You can also access its fields (actor, target, amount, spellid, etc) directly using syntax like `$event->{spellid}`. See the section below entitled "example of the format".

## Sample code ##

```
use Stasis::Parser;

# This prints out a human-readable version of a 2.4 log supplied over STDIN
my $parser = Stasis::Parser->new( version => 2 );

while( <STDIN> ) {
    my $event = $parser->parse($_);
    if( my $text = $event->toString ) {
        print "$text\n";
    }
}
```

## Example of the format ##
This log entry:
```
10/16 21:07:45.468  SPELL_DAMAGE,0x00000000004F381A,"Zarine",0x514,0xF13000613200015A,"Brutallus",0x10a48,27019,"Arcane Shot",0x40,1449,0,64,152,0,0,1,nil,nil
```


Would yield this `Stasis::Event` object:

```
{
    'action' => 5,
    't' => '1255752465.468',
    'actor' => '0x00000000004F381A',
    'actor_name' => 'Zarine',
    'actor_relationship' => 1300,
    'target' => '0xF13000613200015A',
    'target_name' => 'Brutallus',
    'target_relationship' => 68168,
    'spellid' => '27019',
    'spellname' => 'Arcane Shot',
    'spellschool' => 64,
    'amount' => 1449,
    'extraamount' => '0',
    'critical' => '1',
    'crushing' => '',
    'blocked' => '0',
    'school' => 100,
    'glancing' => '',
    'absorbed' => '0',
    'resisted' => 152
}
```


and would print using `$event->toString` as:

```
[Zarine] Arcane Shot crit [Brutallus] 1449 (152 resisted)
```