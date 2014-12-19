# Powerpodder by Zach Dohman <zmon49@gmail.com>
#
# Based on Powershell version of Mashpodder for windows.
# Fun copyright stuff is below. 
#
# Mashpodder by Chess Griffin <chess.griffin@gmail.com>
# Copyright 2009-2014
#
# Originally based on BashPodder by Linc Fessenden 12/1/2004
#
# Redistributions of this script must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
#  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
#  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
# Loads Web utilities for power shell
[Reflection.Assembly]::LoadFile( `
  'C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727\System.Web.dll')`
  | out-null 
# Enables debugging output
[CmdletBinding()]  
 #   Param(
 #   $verb = 0
 #   )
 #   if ($verb -eq 0){
#	
#    }
# Silence Download progress bar
$ProgressPreference = "SilentlyContinue"
### START USER CONFIGURATION
# Default values can be set here. Command-line flags can override some of
# these but not all of them.

# BASEDIR: Base location of the script and related }les.  If you have an
# escaped space in the directory name be sure to keep the double quotes.
# Default is "$HOME/mashpodder".  This is commented out on purpose to start
# with in order to force the user to review this USER CONFIGURATION section
# and set the various options. Uncomment and set to desired path.
# Mashpodder will not create this directory for you.
$BASEDIR="$HOME/mashpodder/"

# RSSFILE: Location of mp.conf }le.  Can be changed to another }le name.
# Default is "$BASEDIR/mp.conf".
$RSSFILE="$BASEDIR/mp.conf"

# PODCASTDIR: Location of podcast directories listed in $RSSFILE.  If you
# have an escaped space in the directory name be sure to keep the double
# quotes.  Default is "$BASEDIR/podcasts".  Thanks to startrek.steve for
# reporting the issues that led to these directory changes.  Mashpodder will
# create this directory if it does not exist unless $CREATE_PODCASTDIR is
# set to "".
$PODCASTDIR="$basedir\podcasts"

# CREATE_PODCASTDIR: Default "1" will create the directory for you if it
# does not exist; "" means to fail and exit if $PODCASTDIR does not exist.
# If your podcast directory is on a mounted share (e.g. NFS, Samba), then
# setting this to "" and thus fail is a means of detecting an unmounted
# share, and to avoid unintentionally writing to the mount point.  (This
# assumes that $PODCASTDIR is below, and not, the mount point.)
$CREATE_PODCASTDIR="1"

# DATEFILEDIR: Location of the "date" directory below $PODCASTDIR
# Note: do not use a leading slash, it will get added later.  The
# eventual location will be $PODCASTDIR/$DATEFILEDIR/$(date +$DATESTRING)
# Mashpodder will create this directory if it does not exist.
# Default is "", which results in date directories being put in $PODCASTDIR.
$DATEFILEDIR=""

# TMPDIR: Location of temp logs, where }les are temporarily downloaded to,
# and other bits.  If you have an escaped space in the directory name be
# sure to keep the double quotes.  Mashpodder will create this directory if
# it does not exist but it will not be deleted on exit.  Default is
# "$BASEDIR/tmp".
$TMPDIR="$BASEDIR/tmp"

# DATESTRING: Valid date format for date-based archiving.  Can be changed
# to other valid formats.  See man date.  Default is "%Y%m%d".
$DATESTRING="%Y%m%d"

# PARSE_ENCLOSURE: Location of parse_enclosure.xsl }le.  Default is
# "$BASEDIR/parse_enclosure.xsl".
$PARSE_ENCLOSURE="$BASEDIR/parse_enclosure.xsl"

# PODLOG: This is a critical }le.  This is the }le that saves the name of
# every }le downloaded (or checked with the 'update' option in mp.conf.)
# If you lose this }le then mashpodder should be able to automatically
# recreate it during the next run, but it's still a good idea to make sure
# the }le is kept in a safe place.  Default is "$BASEDIR/podcast.log".
$PODLOG="$BASEDIR/podcast.log"

# PODLOG_BACKUP: Setting this option to "1" will create a date-stamped
# backup of your podcast.log }le before new podcast }les are downloaded.
# The }lename will be $PODLOG.$DATESTRING (see above variables).  If you
# enable this, you'll want to monitor the number of backups and manually
# remove old copies.  Default is "".
$PODLOG_BACKUP=""

# FIRST_ONLY: Default "" means look to mp.conf for whether to download or
# update; "1" will override mp.conf and download the newest episode.
$FIRST_ONLY=""

# M3U: Default "" means no m3u playlist created; "1" will create m3u
# playlists in each podcast's directory listing all the }les in that
# directory.
$M3U=""

# DAILY_PLAYLIST: Default "" means no daily m3u playlist created; "1" will
# create an m3u playlist in $PODCASTDIR listing all newly downloaded
# shows.  The m3u }lename will have the $DATESTRING prepended to it and
# additional new downloads for that day will be added to the }le.  NOTE:
# $M3U must also be set to "1" for this to work.
$DAILY_PLAYLIST=""

# UPDATE: Default "" means look to mp.conf on whether to download or
# update; "1" will override mp.conf and cause all feeds to be updated
# (meaning episodes will be marked as downloaded but not actually
# downloaded).
$UPDATE=""


### END USER CONFIGURATION

$SCRIPT=${0##*/}
$CWD=$(pwd)
$TEMPLOG="$TMPDIR/temp.log"
$SUMMARYLOG="$TMPDIR/summary.log"
$TEMPRSSFILE="$TMPDIR/mp.conf.temp"
$TEMPDLFILE="$TMPDIR/dl.xml"
$DAILYPLAYLIST="$PODCASTDIR/$(get-date -uformat $DATESTRING)_daily_playlist.m3u"
$OLDIFS=$IFS
$IFS='\n'


function xsltproc($xml){

$xslt = New-Object System.Xml.Xsl.XslCompiledTransform;
$xslt.Load($PARSE_ENCLOSURE);
$xslt.Transform($xml, $TEMPDLFILE);
}

Function touch
{
    $file = $args[0]
    if($file -eq $null) {
        throw "No filename supplied"
    }

    if(Test-Path $file)
    {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    }
    else
    {
        echo $null > $file
    }
}

function crunch {
    write-error -Message $args[0]
    return
}

function sanity_checks{
    # Perform some basic checks
    # Print the date
    $error.clear()
    #write-verbose -message
    write-verbose -message "################################"
    write-verbose -message "Starting mashpodder on"
    write-verbose date
        
    

    if (!$BASEDIR ){
        crunch "\$BASEDIR has not been set.  Please review the USER `
            CONFIGURATION section at the top of mashpodder.sh and set `
            \$BASEDIR and any other applicable options."
        exit 0
    }

    if (!(test-path $BASEDIR)){
        crunch "\$BASEDIR does not exist.  Please re-check the settings `
            at the top of mashpodder.sh and try again."
        exit 0
    }

    cd $BASEDIR

    # Make podcast directory if necessary
    if ( !(test-path $PODCASTDIR )){
        if ( "$CREATE_PODCASTDIR"-eq "1" ){
            write-verbose -message "Creating $PODCASTDIR."
            mkdir -path $PODCASTDIR -ErrorAction SilentlyContinue | out-null
            if ( !(test-path $PODCASTDIR )){
                crunch "\$PODCASTDIR does not exist, and can not be made.  Please re-check the settings `
                at the top of powerpodder.ps1 and try again.  This could also `
                indiciate an unmounted share, if it is on a shared directory."
            }
            }
        else{
            crunch "\$PODCASTDIR does not exist.  Please re-check the settings `
                at the top of powerpodder.ps1 and try again.  This could also `
                indiciate an unmounted share, if it is on a shared directory."
            exit 0
        }
    }

    # Make tmp directory if necessary
    if ( !(test-path $TMPDIR) ){
        write-verbose -message "Creating temporary directory."
        mkdir -path $TMPDIR | out-null
    }

    rm -force $TEMPRSSFILE -ErrorAction SilentlyContinue
    touch $TEMPRSSFILE

    # Make sure the mp.conf file or the file passed with -c switch exists
    if ( !(test-path "$RSSFILE" )){
        crunch "The }le $RSSFILE cannot be found.  Run $0 -h `
            for usage and check the settings at the top of mashpodder.sh.`
            Exiting."
        exit 0
    }

    # Check the mp.conf and do some basic error checking
    # The next two lines take care of blank lines and '#' lines
    $lines = get-content $RSSFILE | where{$_ -ne "" -and !$_.startswith("#")}
    #$lines = $lines | where{!$_.startswith("#")}
   foreach($line in $lines){
        $props = $line.Split(" ")
        $DLNUM="none"
        $FEED=$props[0]
        $ARCHIVETYPE=$props[1]
        $DLNUM=$props[2]

        if ( "$DLNUM" -ne "none" -and "$DLNUM" -ne "all" -and `
            "$DLNUM" -ne "update" -and $DLNUM -lt 1 ){
            crunch "Something is wrong with the download type for $FEED. According to $RSSFILE, it is set to $DLNUM. It should be set to 'none', 'all', 'update', or a number greater than zero.  Please check $RSSFILE.  Exiting"
            exit 0
        }

        # Check type of archiving for each feed
        if ( "$DLNUM" -eq "update" ){
            $DATADIR=$ARCHIVETYPE
            }
        else{
            if ( ! ("$ARCHIVETYPE" -eq "date") ){
                $DATADIR=$ARCHIVETYPE}
            else{
                if ( $DATEFILEDIR ){
                    $DATADIR="$DATEFILEDIR/$(get-date -uformat $DATESTRING)"
                    }
                else{
                    $DATADIR=$(get-date -uformat $DATESTRING)
                    }
                }
           # else{
           #     crunch "Error in archive type for $FEED.  It should be set `
           #         to 'date' for date-based archiving, or to a directory `
           #         name for directory-based archiving.  Exiting."
           #     exit 0
           #}
        }

        if ( "$FIRST_ONLY" -eq "1" ){
            $DLNUM="1"
        }
        if ( "$UPDATE" -eq "1" ){
            $DLNUM="update"
        }
        echo "$FEED $DATADIR $DLNUM" >> $TEMPRSSFILE
    }
    
    # Backup the $PODLOG if $PODLOG_BACKUP=1
    if ( "$PODLOG_BACKUP" -eq "1" ){
       
        write-verbose -message "Backing up the $PODLOG }le."
        
        $NEWPODLOG="$PODLOG.$(get-date $DATESTRING)"
        cp $PODLOG $NEWPODLOG
    }

    # Delete the temp log:
    rm -force $TEMPLOG -ErrorAction SilentlyContinue
    touch $TEMPLOG

    # Create podcast log if necessary
    if ( !(test-path $PODLOG) ){
        write-verbose -message "Creating $PODLOG file."
        touch $PODLOG
    }
    if($error.Count -gt 2){
        exit
    }
}

function fix_url{
    # Take a url embedded in a feed, get the filename, and perform some
    # fixes
    

    $FIXURL=$args[0]

    # Get the filename
    $FILENAME=$FIXURL.Substring($FIXURL.LastIndexOf("/") + 1)

    # Remove parentheses in filenames
    $FILENAME=$FILENAME -replace "[()]",""

    # Replace URL hex sequences in filename (like %20 for ' ' and %2B for '+')
     $FILENAME=[System.Web.HttpUtility]::UrlDecode($FILENAME)

    # Replace spaces in filename with underscore
      $FILENAME = $FILENAME.replace(" ","_")

    # Fix Podshow.com numbers that keep changing
   # $FILENAME=$(echo $FILENAME | sed -e 's/_pshow_[0-9]*//')

    # Fix MSNBC podcast names for audio feeds from Brian Reichart
 #   if echo $FIXURL | grep -q "msnbc.*pd_.*mp3$"; then
 #       FILENAME=$(echo $FIRSTFILENAME | sed -e 's/.*\(pd_.*mp3$\)/\1/')
 #       return
 #   fi
 #   if echo $FIXURL | grep -q "msnbc.*pdm_.*mp3$"; then
 #       FILENAME=$(echo $FIRSTFILENAME | sed -e 's/.*\(pdm_.*mp3$\)/\1/')
 #       return
 #   fi
 #   if echo $FIXURL | grep -q "msnbc.*vh-.*mp3$"; then
 #       FILENAME=$(echo $FIRSTFILENAME | sed -e 's/.*\(vh-.*mp3$\)/\1/')
 #       return
 #   fi
 #   if echo $FIXURL | grep -q "msnbc.*zeit.*m4v$"; then
 #       FILENAME=$(echo $FIRSTFILENAME | sed -e 's/.*\(a_zeit.*m4v$\)/\1/')
 #   fi
#
#    # Fix MSNBC podcast names for video feeds
#    if echo $FIXURL | grep -q "msnbc.*pdv_.*m4v$"; then
#        FILENAME=$(echo $FIRSTFILENAME | sed -e 's/.*\(pdv_.*m4v$\)/\1/')
#        return
#    fi
#
    # Remove question marks at end
    $FILENAME=$FILENAME.replace("?","")
    
    return $FILENAME
}

function check_directory {
    # Check to see if DATADIR exists and if not, create it
    if ( !(Test-path $PODCASTDIR/$DATADIR)){
        write-verbose -message "The directory $PODCASTDIR/$DATADIR for $FEED does not exist.  Creating now...`n"
        mkdir -path $PODCASTDIR/$DATADIR | out-null
   }
    
}

function fetch_podcasts {
    # This is the main loop
    #local LINE FEED DATADIR DLNUM COUNTER FILE URL FILENAME DLURL

    # Read the mp.conf file and wget any url not already in the
    # podcast.log file:
    $NEWDL=0
    $casts = Get-Content $TEMPRSSFILE
    foreach($pod in $casts){
        $props = $pod.Split(" ")
        $FEED=$props[0]
        $DATADIR=$props[1]
        $DLNUM=$props[2]
        $COUNTER=0

        
            if ("$DLNUM" -eq "all" ){
                write-vebose "Checking $FEED -- all episodes."
                continue
                }
            elseif ( "$DLNUM" -eq "none") {
                write-verbose "No downloads selected for $FEED."
                continue
                }
           elseif ( "$DLNUM" -eq "update") {
                Write-Verbose "Catching $FEED up in logs."
                }
            else{
                Write-Verbose "Checking $FEED -- last $DLNUM episodes."
            }
        

        xsltproc($feed)
        $FILE = get-content $TEMPDLFILE
           


        if (!$FILE){
          
            crunch "ERROR: cannot parse any episodes in $FEED. Skipping.`n"
            echo "ERROR: could not parse any episodes in $FEED." >> $SUMMARYLOG
            continue
          
        }

        foreach ($URL in $FILE){
            
            if ( "$DLNUM" -eq "$COUNTER" ){
                break
           }
            $DLURL=$URL
            $FILENAME=fix_url $DLURL
            echo $FILENAME >> $TEMPLOG
            
                write-verbose "Found $FILENAME in feed "
            
            if (!(select-string $PODLOG -pattern $FILENAME)){
                
                  write-verbose "but not in \$PODLOG. Proceeding."
                
                if ( "$DLNUM" -eq "update" ){
                    
                        write-verbose "Adding $FILENAME to \$PODLOG and continuing."
                        echo "$FILENAME added to \$PODLOG" >> $SUMMARYLOG
                    
                    continue
                }
                check_directory $DATADIR
                if ( !(test-path $PODCASTDIR/$DATADIR/"$FILENAME" )){
                    
                        write-verbose "NEW:  Fetching $FILENAME and saving in $DATADIR directory."
                        write-verbose "$FILENAME downloaded to $DATADIR" >> $SUMMARYLOG
                    
                    cd $TMPDIR
                    wget "$DLURL" -Outfile "$FILENAME"
                        
                    $NEWDL=$NEWDL+1
                    mv "$FILENAME" $PODCASTDIR/$DATADIR/"$FILENAME"
                    cd $BASEDIR
                    if ("$M3U" -and "$DAILY_PLAYLIST"){
                        
                            write-vebose "Adding "$FILENAME" to daily playlist."
                        
                        echo $DATADIR/"$FILENAME" >> $DAILYPLAYLIST
                   }
                 }
                else{
                 
                    write-verbose "$FILENAME appears to already exist in $DATADIR directory.  Skipping."
                }
             }
            else{
             
                  write-verbose "and in \$PODLOG. Skipping.`n"
             }
           
           $COUNTER=$COUNTER+1
        }
        # Create an m3u playlist:
        #if [[ "$DLNUM" != "update" && $NEWDL -gt 0 ]]; then
        if ("$DLNUM" -ne "update" ){
            if ($M3U){
                
                    Write-Verbose "Creating $DATADIR m3u playlist."
                
                ls $PODCASTDIR/$DATADIR | add-content $PODCASTDIR/$DATADIR/podcast.m3u 
            }
        }
        
            Write-Verbose "Done.  Continuing to next feed."
            
        
    } 
    if ( !(test-path $TEMPLOG)){
        
            write-verbose "Nothing to download."
        
   }
}

function final_cleanup () {
    # Delete temp files, create the log files, and clean up
    
        write-verbose "Cleaning up."
    
    get-content $TEMPLOG | add-content $PODLOG 
   
   
    if ( $DAILYPLAYLIST) {
        get-content $TEMPLOG | add-content $DAILYPLAYLIST 
        
        
    }
    rm -force $TEMPRSSFILE
     rm -force $TEMPLOG -ErrorAction SilentlyContinue
        Write-Verbose "Total downloads: $NEWDL"
        Write-Verbose "All done."
        if ($SUMMARYLOG){
            
            write-verbose "++SUMMARY++"
            get-content $SUMMARYLOG -ErrorAction SilentlyContinue
            rm -force $SUMMARYLOG -ErrorAction SilentlyContinue
        }
        write-verbose "################################"
   
    # These next 2 lines were moved here so if the user kills the program
    # with ctrl-C (see the trap code, below), they will also cd to cwd
    # before exiting.
    cd $CWD
    $IFS=$OLDIFS
	#Make sure podcast.log only has unique names
	get-content $PODLOG | sort-object | Get-Unique | set-content $PODLOG
}



sanity_checks
fetch_podcasts
final_cleanup

exit 0
