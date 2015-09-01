StasisCL is an open source, BSD licensed (see [License](License.md)) Perl application that parses WoW combat logs and generates statistics from them. The goal of the project is to generate static HTML reports that you host on your own web server. It should work on TBC logs as well as WLK logs. If you would like an example of what you can expect when you get it working look here:

http://stasisguild.org/sws/sws-patchwerk-1231309416/

I especially encourage you to look at healing reports and buff reports, which I feel are particularly strong (mostly due to expandability into spells for healing, and uptime for buffs). For example, you can see things like [debuff uptime on the boss](http://stasisguild.org/sws/sws-patchwerk-1231309416/actor_0xf130003e9c004da9.html#auras) and [spells used by each healer on a tank](http://stasisguild.org/sws/sws-patchwerk-1231309416/actor_0x000000000181bf92.html#healing_t3).

The best way to communicate a feature request or bug report is to open an issue (on the tab above). I'm pretty much guaranteed to remember it since it will stay in the list until I take a look. Read QuickStart to get going on a Mac or other Unix-like system. If you are on Windows, read QuickStartWindows. Make sure to check for updates from the SVN from time to time.

To briefly describe how this all works technically, for those of you interested: the actual "stasis" program does very little aside from gather command line options and glue modules together. Most of the work is done by a set of Perl modules in the "lib" directory, which are designed to be independent enough that you could use them in your own application.

If you'd rather do your own analysis, StasisCL can also convert log files into SQLite databases with a simple and easy-to-query schema, which you can then interact with however you desire.

The following Perl modules are used but not included:

  * File::Copy
  * File::Find
  * File::Path
  * File::Spec
  * Getopt::Long
  * HTML::Entities
  * File::Tail (only required when using -tail)

Many of these probably came with your perl distribution. The rest should be on CPAN.