#! /usr/bin/perl
#
# This script has been modified from the one included with the Baseball Hacks
# book in the following ways:
#
# * it requires a year to be passed on the command line
# * it doesn't try to download files for future games
# * it will not die on a transfer error, so be sure to save output
#   to a log file and read carefully to get any missed files
# * it does *not* download players.txt or batter/pitcher files
# * it *does* download: game.xml, gameday_Syn.xml, linescore.xml
#
use LWP;
my $browser = LWP::UserAgent->new;
$baseurl = "http://gd2.mlb.com/components/game/mlb";
$outputdir = "./games";

use Time::Local;

sub extractDate($) {
  # extracts and formats date from a time stamp
  ($t) = @_;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
    = localtime($t);
  $mon  += 1;
  $year += 1900;
  $mon = (length($mon) == 1) ? "0$mon" : $mon;
  $mday = (length($mday) == 1) ? "0$mday" : $mday;
  return ($mon, $mday, $year);
}

sub verifyDir($) {
  # verifies that a directory exists,
  # creates the directory if the directory doesn't
  my ($d) = @_;
  if (-e $d) {
    die "$d not a directory\n" unless (-d $outputdir);
  } else {
    die "could not create $d: $!\n" unless (mkdir $d);
  }
}

$y = $ARGV[0];
die "please specify a year\n" if ($y == "");

# get all important files Mar 1 through Nov 10
$start = timelocal(0,0,0,20,2,$y-1900);
($mon, $mday, $year) = extractDate($start);
print "starting at $mon/$mday/$year\n";

#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$end = timelocal(0,0,0,30,10,$y-1900);
$end = time < $end ? time : $end; # don't go beyond today
($mon, $mday, $year) = extractDate($end);
print "ending at $mon/$mday/$year\n";

verifyDir($outputdir);

for ($t = $start; $t < $end; $t += 60*60*24) {
  ($mon, $mday, $year) = extractDate($t);
  print "processing $mon/$mday/$year\n";

  verifyDir("$outputdir/year_$year");
  verifyDir("$outputdir/year_$year/month_$mon");
  verifyDir("$outputdir/year_$year/month_$mon/day_$mday");

  $dayurl = "$baseurl/year_$year/month_$mon/day_$mday/";
  print "\t$dayurl\n";

  $response = $browser->get($dayurl);
  print "Couldn't get $dayurl: ", $response->status_line, "\n"
    unless $response->is_success;
  $html = $response->content;
  my @games = ();
  while($html =~ m/<a href=\"(gid_\w+\/)\"/g ) {
    push @games, $1;
  }

  foreach $game (@games) {
    $gamedir = "$outputdir/year_$year/month_$mon/day_$mday/$game";
    if (-e $gamedir) {
      # already fetched info on this game
      print "\t\tskipping game: $game\n";
    } else {
      print "\t\tfetching game: $game\n";
      verifyDir($gamedir);
      $gameurl = "$dayurl/$game";
      $response = $browser->get($gameurl);
      print "Couldn't get $gameurl: ", $response->status_line, "\n"
        unless $response->is_success;
      $gamehtml = $response->content;


      # boxscore.xml
      if($gamehtml =~ m/<a href=\"boxscore\.xml\"/ ) {
        $boxurl = "$dayurl/$game/boxscore.xml";
        $response = $browser->get($boxurl);
        print "Couldn't get $boxurl: ", $response->status_line, "\n"
          unless $response->is_success;
        $boxhtml = $response->content;
        open BOX, ">$gamedir/boxscore.xml"
          or die "could not open file $gamedir/boxscore.xml: $|\n";
        print BOX $boxhtml;
        close BOX;
      } else {
        print "warning: no xml box score for $game\n";
      }


      # players.xml
      if($gamehtml =~ m/<a href=\"players\.xml\"/ ) {
        $fileurl = "$dayurl/$game/players.xml";
        $response = $browser->get($fileurl);
        print "Couldn't get $fileurl: ", $response->status_line, "\n"
          unless $response->is_success;
        $html = $response->content;
        open FILE, ">$gamedir/players.xml"
          or die "could not open file $gamedir/players.xml: $|\n";
        print FILE $html;
        close FILE;
      } else {
        print "warning: no players file for $game\n";
      }


      # game.xml
      if($gamehtml =~ m/<a href=\"game\.xml\"/ ) {
        $fileurl = "$dayurl/$game/game.xml";
        $response = $browser->get($fileurl);
        print "Couldn't get $fileurl: ", $response->status_line, "\n"
          unless $response->is_success;
        $html = $response->content;
        open FILE, ">$gamedir/game.xml"
          or die "could not open file $gamedir/game.xml: $|\n";
        print FILE $html;
        close FILE;
      } else {
        print "warning: no game file for $game\n";
      }


      # gameday_Syn.xml
      if($gamehtml =~ m/<a href=\"gameday_Syn\.xml\"/ ) {
        $fileurl = "$dayurl/$game/gameday_Syn.xml";
        $response = $browser->get($fileurl);
        print "Couldn't get $fileurl: ", $response->status_line, "\n"
          unless $response->is_success;
        $html = $response->content;
        open FILE, ">$gamedir/gameday_Syn.xml"
          or die "could not open file $gamedir/gameday_Syn.xml: $|\n";
        print FILE $html;
        close FILE;
      } else {
        print "warning: no gameday_Syn file for $game\n";
      }


      # linescore.xml
      if($gamehtml =~ m/<a href=\"linescore\.xml\"/ ) {
        $fileurl = "$dayurl/$game/linescore.xml";
        $response = $browser->get($fileurl);
        print "Couldn't get $fileurl: ", $response->status_line, "\n"
          unless $response->is_success;
        $html = $response->content;
        open FILE, ">$gamedir/linescore.xml"
          or die "could not open file $gamedir/linescore.xml: $|\n";
        print FILE $html;
        close FILE;
      } else {
        print "warning: no linescore file for $game\n";
      }


      #if($gamehtml =~ m/<a href=\"inning\/\"/ ) {
      #  $inningdir = "$gamedir/inning";
      #  verifyDir($inningdir);
      #  $inningurl = "$dayurl/$game/inning/";
      #  $response = $browser->get($inningurl);
      #  print "Couldn't get $gameurl: ", $response->status_line, "\n"
      #    unless $response->is_success;
      #  $inninghtml = $response->content;

      #  my @files = ();
      #  while($inninghtml =~ m/<a href=\"(inning_.*)\"/g ) {
      #    push @files, $1;
      #  }

      #  foreach $file (@files) {
      #    print "\t\t\tinning file: $file\n";
      #    $fileurl = "$inningurl/$file";
      #    $response = $browser->get($fileurl);
      #    print "Couldn't get $fileurl: ", $response->status_line, "\n"
      #      unless $response->is_success;
      #    $filehtml = $response->content;
      #    open FILE, ">$inningdir/$file"
      #      or die "could not open file $inningdir/$file: $|\n";
      #    print FILE $filehtml;
      #    close FILE;
      #  }
      #}


      #if($gamehtml =~ m/<a href=\"players\.txt\"/ ) {
      #  $plyrurl = "$dayurl/$game/players.txt";
      #  $response = $browser->get($plyrurl);
      #  print "Couldn't get $plyrurl: ", $response->status_line, "\n"
      #    unless $response->is_success;
      #  $plyrhtml = $response->content;
      #  open PLYRS, ">$gamedir/players.txt"
      #    or die "could not open file $gamedir/players.txt: $|\n";
      #  print PLYRS $plyrhtml;
      #  close PLYRS;
      #} else {
      #  print "warning: no player list for $game\n";
      #}


      #if($gamehtml =~ m/<a href=\"batters\/\"/ ) {
      #  $battersdir = "$gamedir/batters";
      #  verifyDir($battersdir);
      #  $battersurl = "$dayurl/$game/batters/";
      #  $response = $browser->get($battersurl);
      #  print "Couldn't get $battersurl: ", $response->status_line, "\n"
      #    unless $response->is_success;
      #  $battershtml = $response->content;

      #  my @files = ();
      #  while($battershtml =~ m/<a href=\"(\d+\.xml)\"/g ) {
      #    push @files, $1;
      #  }

      #  foreach $file (@files) {
      #    print "\t\t\tbatter file: $file\n";
      #    $fileurl = "$battersurl/$file";
      #    $response = $browser->get($fileurl);
      #    print "Couldn't get $fileurl: ", $response->status_line, "\n"
      #      unless $response->is_success;
      #    $filehtml = $response->content;
      #    open FILE, ">$battersdir/$file"
      #      or die "could not open file $battersdir/$file: $|\n";
      #    print FILE $filehtml;
      #    close FILE;
      #  }
      #}


      #if($gamehtml =~ m/<a href=\"pitchers\/\"/ ) {
      #  $pitchersdir = "$gamedir/pitchers";
      #  verifyDir($pitchersdir);
      #  $pitchersurl = "$dayurl/$game/pitchers/";
      #  $response = $browser->get($pitchersurl);
      #  print "Couldn't get $pitchersurl: ", $response->status_line, "\n"
      #    unless $response->is_success;
      #  $pitchershtml = $response->content;

      #  my @files = ();
      #  while($pitchershtml =~ m/<a href=\"(\d+\.xml)\"/g ) {
      #    push @files, $1;
      #  }

      #  foreach $file (@files) {
      #    print "\t\t\tpitcher file: $file\n";
      #    $fileurl = "$pitchersurl/$file";
      #    $response = $browser->get($fileurl);
      #    print "Couldn't get $fileurl: ", $response->status_line, "\n"
      #      unless $response->is_success;
      #    $filehtml = $response->content;
      #    open FILE, ">$pitchersdir/$file"
      #      or die "could not open file $pitchersdir/$file: $|\n";
      #    print FILE $filehtml;
      #    close FILE;
      #  }
      #}


      #if($gamehtml =~ m/<a href=\"pbp\/\"/ ) {
      #  $pbpdir = "$gamedir/pbp";
      #  verifyDir($pbpdir);

      #  $bpbpdir = "$gamedir/pbp/batters";
      #  verifyDir($bpbpdir);
      #  $bpbpurl = "$dayurl/$game/pbp/batters";
      #  $response = $browser->get($bpbpurl);
      #  print "Couldn't get $bpbpurl: ", $response->status_line, "\n"
      #    unless $response->is_success;
      #  $bpbphtml = $response->content;

      #  my @files = ();
      #  while($bpbphtml =~ m/<a href=\"(\d+\.xml)\"/g ) {
      #    push @files, $1;
      #  }

      #  foreach $file (@files) {
      #    print "\t\t\tpbp batter file: $file\n";
      #    $fileurl = "$bpbpurl/$file";
      #    $response = $browser->get($fileurl);
      #    print "Couldn't get $fileurl: ", $response->status_line, "\n"
      #      unless $response->is_success;
      #    $filehtml = $response->content;
      #    open FILE, ">$bpbpdir/$file"
      #      or die "could not open file $bpbpdir/$file: $!\n";
      #    print FILE $filehtml;
      #    close FILE;
      #  }

      #  $ppbpdir = "$gamedir/pbp/pitchers";
      #  verifyDir($ppbpdir);
      #  $ppbpurl = "$dayurl/$game/pbp/pitchers";
      #  $response = $browser->get($ppbpurl);
      #  print "Couldn't get $ppbpurl: ", $response->status_line, "\n"
      #    unless $response->is_success;
      #  $ppbphtml = $response->content;

      #  my @files = ();
      #  while($ppbphtml =~ m/<a href=\"(\d+\.xml)\"/g ) {
      #    push @files, $1;
      #  }

      #  foreach $file (@files) {
      #    print "\t\t\tpbp pitcher file: $file\n";
      #    $fileurl = "$ppbpurl/$file";
      #    $response = $browser->get($fileurl);
      #    print "Couldn't get $fileurl: ", $response->status_line, "\n"
      #      unless $response->is_success;
      #    $filehtml = $response->content;
      #    open FILE, ">$ppbpdir/$file"
      #      or die "could not open file $ppbpdir/$file: $|\n";
      #    print FILE $filehtml;
      #    close FILE;
      #  }
      #}
      sleep(1); # be at least somewhat polite; one game per second
    }
  }
}
