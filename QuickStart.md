I wrote these instructions on a mostly stock Mac (the only significant modification is that I installed Xcode, which I think is where subversion came from) but they should apply to any Unix-like system assuming you have subversion and perl installed. If you're on Windows try the QuickStartWindows instructions instead.

  * First you need to download the latest version of the code. There is no real release cycle at this time so you are stuck using the subversion trunk at `http://stasiscl.googlecode.com/svn/trunk/`. If you don't know how then your best shot is to open up a terminal and do the following:

```
svn checkout http://stasiscl.googlecode.com/svn/trunk/ stasiscl
cd stasiscl
```

> When you want to update the code from the latest version in the trunk, run `svn update`.

  * You may need to install some perl modules from CPAN if you don't have all the ones on the front page list. If this is true then run `sudo perl -MCPAN -eshell`, possibly do some setup, and then type `install X` for the various modules you are missing (the least likely one for you to have is `File::Tail`)

  * Create a folder on your machine that you would like to store your guild's web stats in. For purposes of the quick start I will use `/home/jqpublic/sws`. Once this is done you must copy the folder `extras` from the subversion trunk into the folder you just made. This should contain a `.js` and a `.css` file which are necessary for proper display.

  * If you want an index, you have two choices. You can use Abbi's PHP index, which you can download from http://elitistjerks.com/blogs/abbi/171-revised_stasiscl_raid_listing.html. Or, you can set up static index by creating a `wws-history` folder inside the one you made (`/home/jqpublic/sws/wws-history` in this example), and this must contain the normal contents of a `wws-history` folder from the standalone version of WWS (the one it makes when you click "Generate Report" and have "Update History" checked). These files are not included because I do not hold the copyright. If you do not want an index you may skip this step. In case you're wondering, the reason this is necessary is because this program does not create its own index, but is capable of making a data.xml file in the same format that the standalone version of WWS does.

  * At this point setup is complete. For each log file you wish to run, you need to call "stasis add" with the appropriate options and send it the file over standard input. Do this in a terminal:

```
# 2.4 log (a.k.a v2) -- name of logger is not needed:
./stasis add -dir /home/jqpublic/sws -ver 2 -file /path/to/log/file

# Normally boss attempts are discarded and only kills are recorded. If you wish to preserve all attempts, add "-attempt", for example:
./stasis add -dir /home/jqpublic/sws -ver 2 -attempt -file /path/to/log/file

# Pre-2.4 log (a.k.a. v1) -- note the name of the logger is needed:
./stasis add -dir /home/jqpublic/sws -ver 1 -log Gian -file /path/to/log/file
```

  * If you chose to create an index, when you are done adding logs you should run the following command, which will generate a data.xml inside the wws-history folder you made earlier:

```
./stasis history -dir /home/jqpublic/sws
```

  * You can now upload the contents of your folder (`/home/jqpublic/sws`) to a web server or open the various `index.html` on your local machine.

  * If at some point you wish to re-run the log file (new version of the program maybe) then you need only to run the same `stasis add` command again. It will remove the old directories and write out new ones. At some point there will probably be a way to do this automatically but for now it must be done manually.

  * If you wish to remove a parse, just remove the directory `sws-XXXXX` and re-run `./stasis history` with the appropriate `-dir` option.