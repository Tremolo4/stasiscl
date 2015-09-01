I don't have access to a Windows machine for testing, but these instructions are adapted from the Unix-like version at QuickStart based on contributions from _mutagen_ on the elitist jerks forum. If they don't work please let me know because that means I wrote them down incorrectly.

  * First you need to download the latest version of the code. There is no real release cycle at this time so you are stuck using the subversion trunk at `http://stasiscl.googlecode.com/svn/trunk/`. If you aren't sure how to do this, try [TortoiseSVN](http://tortoisesvn.net/downloads) (external link). I'm not sure how to tell TortoiseSVN to update the code from the repository when it changes, but hopefully you can figure it out.

  * Windows does not come with Perl, so you will need to get a Perl distribution if you do not already have one. Try [ActivePerl](http://www.activestate.com/Products/activeperl/) if you don't have a personal favorite. You may need to install some modules if you don't have all the ones on the front page's list. If this is the case then use the program "Perl Package Manager".

  * Create a directory on your machine that you would like to store your guild's web stats in. For purposes of the quick start I will use `C:\stasiscl\www`. Once this is done you must copy the directory `extras` from the subversion trunk into the directory you just made. This should contain a `.js` and a `.css` file which are necessary for proper display.

  * If you want an index, you have two choices. You can use Abbi's PHP index, which you can download from http://elitistjerks.com/blogs/abbi/171-revised_stasiscl_raid_listing.html. Or, you can set up static index by creating a `wws-history` directory inside the one you made (`C:\stasiscl\www\wws-history` in this example), and this must contain the normal contents of a `wws-history` folder from the standalone version of WWS (the one it makes when you click "Generate Report" and have "Update History" checked). These files are not included because I do not hold the copyright. If you do not want an index you may skip this step. In case you're wondering, the reason this is necessary is because this program does not create its own index, but is capable of making a data.xml file in the same format that the standalone version of WWS does.

  * At this point setup is complete. For each log file you wish to run, you need to call "stasis add" with the appropriate options and send it the file over standard input. Open a command prompt and `cd` to the directory you checked the code out to. Then do something like one of the following:

```
# 2.4 log (a.k.a v2) -- name of logger is not needed:
perl stasis add -dir C:\stasiscl\www -ver 2 -file C:\path\to\log\file

# Normally boss attempts are discarded and only kills are recorded. If you wish to preserve all attempts, add "-attempt", for example:
perl stasis add -dir C:\stasiscl\www -ver 2 -attempt -file C:\path\to\log\file

# Pre-2.4 log (a.k.a. v1) -- note the name of the logger is needed:
perl stasis add -dir C:\stasiscl\www -ver 1 -log Gian -file C:\path\to\log\file
```

  * If you chose to create an index, when you are done adding logs you should run the following command, which will generate a data.xml inside the wws-history folder you made earlier:

```
perl stasis history -dir C:\stasiscl\www
```

  * You can now upload the contents of your folder (`C:\stasiscl\www`) to a web server or open the various `index.html` on your local machine.

  * If at some point you wish to re-run the log file (new version of the program maybe) then you need only to run the same `stasis add` command again. It will remove the old directories and write out new ones. At some point there will probably be a way to do this automatically but for now it must be done manually.

  * If you wish to remove a parse, just remove the directory `sws-XXXXX` and re-run `perl stasis history` with the appropriate `-dir` option.