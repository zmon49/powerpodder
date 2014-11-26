Powerpodder

podcatching client based on MashPodder

In early 2014 I started using Mashpodder. At the time I was using linux, however
when I switched to Windows I had the problem of no good CLI podcast downloader. 
This is the result of my conversion of Mashpodder from Bash to Powershell.
the conversion results in backwards compatibility. if switching to windows you
can save your mp.conf and not have to find all your favorite podcasts again!

Powerpodder allows the user to download podcast episodes. The user can choose
to save these episodes in a named directory (i.e. separate directory per feed)
or in a date-based directory, so the most recent episodes are in one folder.
Or, the user can combine this by having some podcasts in a named directory and
others in the date-based directory. The user can choose to download all, none,
or a set number of episodes per feed. The user can also choose to mark the
episodes as downloaded (without actually downloading them) which can be used
to 'catch up' to a podcast.

Three files are needed: powerpodder.ps1, mp.conf, and parse-enclosure.xsl. All
three of these files are available here in the powerpodder repository. You can
also browse through the source tree and download the files directly. 


Finally, about the Git repo: this is a tiny project so there will only be
one branch, which is 'master' and that will contain the latest code and
patches and testing bits.  It may or may not work at any given time.
However, when it seems that the code is stable, I'll tag a release.  So,
basically, if you want something stable, use the latest release.  If you
want the latest-and-greatest or want to help test, use the master branch.

Enjoy!
