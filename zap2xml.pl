#!/usr/bin/env perl
# zap2xml (c) <zap2xml@gmail.com> - for personal use only!
# not for redistribution of any kind, or conversion to other languages,
# not GPL. not for github, thank you.

BEGIN { $SIG{__DIE__} = sub { 
  return if $^S;
  my $msg = join(" ", @_);
  print STDERR "$msg";
  if ($msg =~ /can't locate/i) {
    print "\nSee homepage for tips on installing missing modules (example: \"perl -MCPAN -e shell\")\n";
    if ($^O eq 'MSWin32') {
      print "Use \"ppm install\" on windows\n";
    }
  }
  if ($^O eq 'MSWin32') {
    if ($msg =~ /uri.pm/i && $msg =~ /temp/i) {
      print "\nIf your scanner deleted the perl URI.pm file see the homepage for tips\n";
      if ($msg =~ /(\ .\:.+?par-.+?\\)/) {
        print "(Delete the $1 folder and retry)\n";
      }
    }
    sleep(5);
  } 
  exit 1;
}}

use Compress::Zlib;
use Encode;
use File::Basename;
use File::Copy;
use Getopt::Std;
use HTTP::Cookies;
use URI;
use URI::Escape;
use LWP::UserAgent;
use LWP::ConnCache;
use POSIX;
use Time::Local;
use Time::Piece;
use JSON;

no warnings 'utf8';

STDOUT->autoflush(1);
STDERR->autoflush(1);

$VERSION = "2018-12-01";
print "zap2xml ($VERSION)\nCommand line: $0 " .  join(" ",@ARGV) . "\n";

%options=();
getopts("?aA:bB:c:C:d:DeE:Fgi:IjJ:l:Lm:Mn:N:o:Op:P:qRr:s:S:t:Tu:UwWxY:zZ:89",\%options);

$homeDir = $ENV{HOME};
$homeDir = $ENV{USERPROFILE} if !defined($homeDir);
$homeDir = '.' if !defined($homeDir);
$confFile = $homeDir . '/.zap2xmlrc';

# Defaults
$start = 0;
$days = 7;
$ncdays = 0;
$ncsdays = 0;
$ncmday = -1;
$retries = 3;
$outFile = 'xmltv.xml';
$outFile = 'xtvd.xml' if defined $options{x};
$cacheDir = 'cache';
$lang = 'en';
$userEmail = '';
$password = '';
$proxy;
$postalcode; 
$country;
$lineupId; 
$device;
$sleeptime = 0;
$allChan = 0;
$shiftMinutes = 0;

$outputXTVD = 0;
$lineuptype;
$lineupname;
$lineuplocation;

$zapToken;
$zapPref='-';
%zapFavorites=();
%sidCache=();

$sTBA = "\\bTBA\\b|To Be Announced";

%tvgfavs=();

&HELP_MESSAGE() if defined $options{'?'};

$confFile = $options{C} if defined $options{C};
# read config file
if (open (CONF, $confFile))
{
  &pout("Reading config file: $confFile\n");
  while (<CONF>)
  {
    s/#.*//; # comments
    if (/^\s*$/i)                            { }
    elsif (/^\s*start\s*=\s*(\d+)/i)         { $start = $1; }
    elsif (/^\s*days\s*=\s*(\d+)/i)          { $days = $1; }
    elsif (/^\s*ncdays\s*=\s*(\d+)/i)        { $ncdays = $1; }
    elsif (/^\s*ncsdays\s*=\s*(\d+)/i)       { $ncsdays = $1; }
    elsif (/^\s*ncmday\s*=\s*(\d+)/i)        { $ncmday = $1; }
    elsif (/^\s*retries\s*=\s*(\d+)/i)       { $retries = $1; }
    elsif (/^\s*user[\w\s]*=\s*(.+)/i)       { $userEmail = &rtrim($1); }
    elsif (/^\s*pass[\w\s]*=\s*(.+)/i)       { $password = &rtrim($1); }
    elsif (/^\s*cache\s*=\s*(.+)/i)          { $cacheDir = &rtrim($1); }
    elsif (/^\s*icon\s*=\s*(.+)/i)           { $iconDir = &rtrim($1); }
    elsif (/^\s*trailer\s*=\s*(.+)/i)        { $trailerDir = &rtrim($1); }
    elsif (/^\s*lang\s*=\s*(.+)/i)           { $lang = &rtrim($1); }
    elsif (/^\s*outfile\s*=\s*(.+)/i)        { $outFile = &rtrim($1); }
    elsif (/^\s*proxy\s*=\s*(.+)/i)          { $proxy = &rtrim($1); }
    elsif (/^\s*outformat\s*=\s*(.+)/i)      { $outputXTVD = 1 if $1 =~ /xtvd/i; }
    elsif (/^\s*lineupid\s*=\s*(.+)/i)       { $lineupId = &rtrim($1); }
    elsif (/^\s*lineupname\s*=\s*(.+)/i)     { $lineupname = &rtrim($1); }
    elsif (/^\s*lineuptype\s*=\s*(.+)/i)     { $lineuptype = &rtrim($1); }
    elsif (/^\s*lineuplocation\s*=\s*(.+)/i) { $lineuplocation = &rtrim($1); }
    elsif (/^\s*postalcode\s*=\s*(.+)/i)     { $postalcode = &rtrim($1); }
    else
    {
      die "Oddline in config file \"$confFile\".\n\t$_";
    }
  }
  close (CONF);
} 
&HELP_MESSAGE() if !(%options) && $userEmail eq '';

$cacheDir = $options{c} if defined $options{c};
$days = $options{d} if defined $options{d};
$ncdays = $options{n} if defined $options{n};
$ncsdays = $options{N} if defined $options{N};
$ncmday = $options{B} if defined $options{B}; 
$start = $options{s} if defined $options{s};
$retries = $options{r} if defined $options{r};
$iconDir = $options{i} if defined $options{i};
$trailerDir = $options{t} if defined $options{t};
$lang = $options{l} if defined $options{l};
$outFile = $options{o} if defined $options{o};
$password = $options{p} if defined $options{p};
$userEmail = $options{u} if defined $options{u};
$proxy = $options{P} if defined $options{P};
$zlineupId = $options{Y} if defined $options{Y};
$zipcode = $options{Z} if defined $options{Z};
$includeXMLTV = $options{J} if defined $options{J} && -e $options{J};
$outputXTVD = 1 if defined $options{x};
$allChan = 1 if defined($options{a});
$allChan = 1 if defined($zipcode) && defined($zlineupId);
$sleeptime = $options{S} if defined $options{S};
$shiftMinutes = $options{m} if defined $options{m};
$ncdays = $days - $ncdays; # make relative to the end
$urlRoot = 'https://tvlistings.zap2it.com/';
$urlAssets = 'https://zap2it.tmsimg.com/assets/';
$tvgurlRoot = 'http://mobilelistings.tvguide.com/';
$tvgMapiRoot = 'http://mapi.tvguide.com/';
$tvgurl = 'https://www.tvguide.com/';
$tvgspritesurl = 'http://static.tvgcdn.net/sprites/';
$retries = 20 if $retries > 20; # Too many

my %programs = ();
my $cp;
my %stations = ();
my $cs;
my $rcs;
my %schedule = ();
my $sch;
my %logos = ();

my $coNum = 0;
my $tb = 0;
my $treq = 0;
my $tsocks = ();
my $expired = 0;
my $ua;
my $tba = 0;
my $exp = 0;
my @fh = ();

my $XTVD_startTime;
my $XTVD_endTime;

if (! -d $cacheDir) {
  mkdir($cacheDir) or die "Can't mkdir: $!\n";
} else {
  opendir (DIR, "$cacheDir/");
  @cacheFiles = grep(/\.html|\.js/,readdir(DIR));
  closedir (DIR);
  foreach $cacheFile (@cacheFiles) {
    $fn = "$cacheDir/$cacheFile";
    $atime = (stat($fn))[8];
    if ($atime + ( ($days + 2) * 86400) < time) {
      &pout("Deleting old cached file: $fn\n");
      &unf($fn);
    }
  }
}

my $s1 = time();
if (defined($options{z})) {

  &login() if !defined($options{a}); # get favorites
  &parseTVGIcons() if defined($iconDir);
  $gridHours = 3;
  $maxCount = $days * (24 / $gridHours);
  $offset = $start * 3600 * 24 * 1000;
  $ms = &hourToMillis() + $offset;

  for ($count=0; $count < $maxCount; $count++) {
    $curday = int($count / (24/$gridHours)) + 1;
    if ($count == 0) { 
      $XTVD_startTime = $ms;
    } elsif ($count == $maxCount - 1) { 
      $XTVD_endTime = $ms + ($gridHours * 3600000) - 1;
    }

    $fn = "$cacheDir/$ms\.js\.gz";
    if (! -e $fn || $curday > $ncdays || $curday <= $ncsdays || $curday == $ncmday) {
      &login() if !defined($zlineupId);
      my $duration = $gridHours * 60;
      my $tvgstart = substr($ms, 0, -3);
      $rs = &getURL($tvgurlRoot . "Listingsweb/ws/rest/schedules/$zlineupId/start/$tvgstart/duration/$duration", 1);
      last if ($rs eq '');
      $rc = Encode::encode('utf8', $rs);
      &wbf($fn, Compress::Zlib::memGzip($rc));
    }
    &pout("[" . ($count+1) . "/" . "$maxCount] Parsing: $fn\n");
    &parseTVGGrid($fn);

    if (defined($options{T}) && $tba) {
      &pout("Deleting: $fn (contains \"$sTBA\")\n");
      &unf($fn);
    }
    if ($exp) {
      &pout("Deleting: $fn (expired)\n");
      &unf($fn);
    }
    $exp = 0;
    $tba = 0;
    $ms += ($gridHours * 3600 * 1000); 
  } 

} else {

  &login() if !defined($options{a}); # get favorites
  $gridHours = 3;
  $maxCount = $days * (24 / $gridHours);
  $offset = $start * 3600 * 24 * 1000;
  $ms = &hourToMillis() + $offset;
  for ($count=0; $count < $maxCount; $count++) {
    $curday = int($count / (24/$gridHours)) + 1;
    if ($count == 0) { 
      $XTVD_startTime = $ms;
    } elsif ($count == $maxCount - 1) { 
      $XTVD_endTime = $ms + ($gridHours * 3600000) - 1;
    }

    $fn = "$cacheDir/$ms\.js\.gz";
    if (! -e $fn || $curday > $ncdays || $curday <= $ncsdays || $curday == $ncmday) {
      my $zstart = substr($ms, 0, -3);
      $params = "?time=$zstart&timespan=$gridHours&pref=$zapPref&";
      $params .= &getZapGParams();
      $params .= '&TMSID=&AffiliateID=gapzap&FromPage=TV%20Grid';
      $params .= '&ActivityID=1&OVDID=&isOverride=true';
      $rs = &getURL($urlRoot . "api/grid$params",1);
      last if ($rs eq '');
      $rc = Encode::encode('utf8', $rs);
      &wbf($fn, Compress::Zlib::memGzip($rc));
    }
   
    &pout("[" . ($count+1) . "/" . "$maxCount] Parsing: $fn\n");
    &parseJSON($fn);

    if (defined($options{T}) && $tba) {
      &pout("Deleting: $fn (contains \"$sTBA\")\n");
      &unf($fn);
    }
    if ($exp) {
      &pout("Deleting: $fn (expired)\n");
      &unf($fn);
    }
    $exp = 0;
    $tba = 0;
    $ms += ($gridHours * 3600 * 1000);
  } 

}
my $s2 = time();
my $tsockt = scalar(keys %tsocks);
&pout("Downloaded " . &pl($tb, "byte") 
  . " in " . &pl($treq, "http request") 
  . " using " . &pl($tsockt > 0 ? $tsockt : $treq, "socket") . ".\n") if $tb > 0;
&pout("Expired programs: $expired\n") if $expired > 0;
&pout("Writing XML file: $outFile\n");
open($FH, ">$outFile");
my $enc = 'ISO-8859-1';
if (defined($options{U})) {
  $enc = 'UTF-8';
} 
if ($outputXTVD) {
  &printHeaderXTVD($FH, $enc);
  &printStationsXTVD($FH);
  &printLineupsXTVD($FH);
  &printSchedulesXTVD($FH);
  &printProgramsXTVD($FH);
  &printGenresXTVD($FH);
  &printFooterXTVD($FH);
} else {
  &printHeader($FH, $enc);
  &printChannels($FH);
  if (defined($includeXMLTV)) {
    &pout("Reading XML file: $includeXMLTV\n");
    &incXML("<channel","<programme", $FH);
  } 
  &printProgrammes($FH);
  &incXML("<programme","</tv", $FH) if defined($includeXMLTV);
  &printFooter($FH);
}

close($FH);

my $ts = 0;
for my $station (keys %stations ) {
  $ts += scalar (keys %{$schedule{$station}})
}
my $s3 = time();
&pout("Completed in " . ( $s3 - $s1 ) . "s (Parse: " . ( $s2 - $s1 ) . "s) " . keys(%stations) . " stations, " . keys(%programs) . " programs, $ts scheduled.\n");

if (defined($options{w})) {
  print "Press ENTER to exit:";
  <STDIN>;
} else {
  sleep(3) if ($^O eq 'MSWin32');
}

exit 0;

sub incXML {
  my ($st, $en, $FH) = @_;
  open($XF, "<$includeXMLTV");
  while (<$XF>) {
    if (/^\s*$st/../^\s*$en/) {
      print $FH $_ unless /^\s*$en/
    }
  }
  close($XF);
}

sub pl {
 my($i, $s) = @_;
 my $r = "$i $s";
 return $i == 1 ? $r : $r . "s";
}

sub pout {
  print @_ if !defined $options{q};
}

sub perr {
  warn @_;
}

sub rtrim {
  my $s = shift;
  $s =~ s/\s+$//;
  return $s;
}

sub trim {
  my $s = shift;
  $s =~ s/^\s+//;
  $s =~ s/\s+$//;
  return $s;
}

sub trim2 {
  my $s = &trim(shift);
  $s =~ s/[^\w\s\(\)\,]//gsi;
  $s =~ s/\s+/ /gsi; 
  return $s;
}

sub _rtrim3 {
  my $s = shift;
  return substr($s, 0, length($s)-3);
}

sub convTime {
  my $t = shift;
  $t += $shiftMinutes * 60 * 1000;
  return strftime "%Y%m%d%H%M%S", localtime(&_rtrim3($t));
}

sub convTimeXTVD {
  my $t = shift;
  $t += $shiftMinutes * 60 * 1000;
  return strftime "%Y-%m-%dT%H:%M:%SZ", gmtime(&_rtrim3($t));
}

sub convOAD {
  return strftime "%Y%m%d", gmtime(&_rtrim3(shift));
}

sub convOADXTVD {
  return strftime "%Y-%m-%d", gmtime(&_rtrim3(shift));
}

sub convDurationXTVD {
  my $duration = shift; 
  my $hour = int($duration / 3600000);
  my $minutes = int(($duration - ($hour * 3600000)) / 60000);
  return sprintf("PT%02dH%02dM", $hour, $minutes);
}

sub appendAsterisk {
  my ($title, $station, $s) = @_;
  if (defined($options{A})) {
    if (($options{A} =~ "new" && defined($schedule{$station}{$s}{new}))
      || ($options{A} =~ "live" && defined($schedule{$station}{$s}{live}))) {
      $title .= " *";
    }
  }
  return $title;
}

sub stationToChannel {
  my $s = shift;
  if (defined($options{z})) {
    return sprintf("I%s.%s.tvguide.com", $stations{$s}{number},$stations{$s}{stnNum});
  } elsif (defined($options{O})) {
    return sprintf("C%s%s.zap2it.com",$stations{$s}{number},lc($stations{$s}{name}));
  } elsif (defined($options{9})) {
    return sprintf("I%s.labs.zap2it.com",$stations{$s}{stnNum});
  }
  return sprintf("I%s.%s.zap2it.com", $stations{$s}{number},$stations{$s}{stnNum});
}

sub sortChan {
  if (defined($stations{$a}{order}) && defined($stations{$b}{order})) {
    my $c = $stations{$a}{order} <=> $stations{$b}{order};
    if ($c == 0) { return $stations{$a}{stnNum} <=> $stations{$b}{stnNum} }
	else { return $c };
  } else {
    return $stations{$a}{name} cmp $stations{$b}{name};
  }
}

sub enc {
  my $t = shift;
  if (!defined($options{U})) {$t = Encode::decode('utf8', $t);}
  if (!defined($options{E}) || $options{E} =~ /amp/) {$t =~ s/&/&amp;/gs;}
  if (!defined($options{E}) || $options{E} =~ /quot/) {$t =~ s/"/&quot;/gs;}
  if (!defined($options{E}) || $options{E} =~ /apos/) {$t =~ s/'/&apos;/gs;}
  if (!defined($options{E}) || $options{E} =~ /lt/) {$t =~ s/</&lt;/gs;}
  if (!defined($options{E}) || $options{E} =~ /gt/) {$t =~ s/>/&gt;/gs;}
  if (defined($options{e})) {
    $t =~ s/([^\x20-\x7F])/'&#' . ord($1) . ';'/gse;
  }
  return $t;
}

sub printHeader {
  my ($FH, $enc) = @_;
  print $FH "<?xml version=\"1.0\" encoding=\"$enc\"?>\n";
  print $FH "<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n\n";
  if (defined($options{z})) {
    print $FH "<tv source-info-url=\"http://tvguide.com/\" source-info-name=\"tvguide.com\"";
  } else {
    print $FH "<tv source-info-url=\"http://tvlistings.zap2it.com/\" source-info-name=\"zap2it.com\"";
  }
  print $FH " generator-info-name=\"zap2xml\" generator-info-url=\"zap2xml\@gmail.com\">\n";
}

sub printFooter {
  my $FH = shift;
  print $FH "</tv>\n";
} 

sub printChannels {
  my $FH = shift;
  for my $key ( sort sortChan keys %stations ) {
    $sname = &enc($stations{$key}{name});
    $fname = &enc($stations{$key}{fullname});
    $snum = $stations{$key}{number};
    print $FH "\t<channel id=\"" . &stationToChannel($key) . "\">\n";
    print $FH "\t\t<display-name>" . $sname . "</display-name>\n" if defined($options{F}) && defined($sname);
    if (defined($snum)) {
      &copyLogo($key);
      print $FH "\t\t<display-name>" . $snum . " " . $sname . "</display-name>\n" if ($snum ne '');
      print $FH "\t\t<display-name>" . $snum . "</display-name>\n" if ($snum ne '');
    }
    print $FH "\t\t<display-name>" . $sname . "</display-name>\n" if !defined($options{F}) && defined($sname);
    print $FH "\t\t<display-name>" . $fname . "</display-name>\n" if (defined($fname));
    if (defined($stations{$key}{logoURL})) {
      print $FH "\t\t<icon src=\"" . $stations{$key}{logoURL} . "\" />\n";
    }
    print $FH "\t</channel>\n";
  }
}

sub printProgrammes {
  my $FH = shift;
  for my $station ( sort sortChan keys %stations ) {
    my $i = 0; 
    my @keyArray = sort { $schedule{$station}{$a}{time} cmp $schedule{$station}{$b}{time} } keys %{$schedule{$station}};
    foreach $s (@keyArray) {
      if ($#keyArray <= $i && !defined($schedule{$station}{$s}{endtime})) {
        delete $schedule{$station}{$s};
        next; 
      } 
      my $p = $schedule{$station}{$s}{program};
      my $startTime = &convTime($schedule{$station}{$s}{time});
      my $startTZ = &timezone($schedule{$station}{$s}{time});
      my $endTime;
      if (defined($schedule{$station}{$s}{endtime})) {
        $endTime = $schedule{$station}{$s}{endtime};
      } else {
        $endTime = $schedule{$station}{$keyArray[$i+1]}{time};
      }

      my $stopTime = &convTime($endTime);
      my $stopTZ = &timezone($endTime);

      print $FH "\t<programme start=\"$startTime $startTZ\" stop=\"$stopTime $stopTZ\" channel=\"" . &stationToChannel($schedule{$station}{$s}{station}) . "\">\n";
      if (defined($programs{$p}{title})) {
        my $title = &enc($programs{$p}{title});
        $title = &appendAsterisk($title, $station, $s);
        print $FH "\t\t<title lang=\"$lang\">" . $title . "</title>\n";
      } 

      if (defined($programs{$p}{episode}) || (defined($options{M}) && defined($programs{$p}{movie_year}))) {
        print $FH "\t\t<sub-title lang=\"$lang\">";
          if (defined($programs{$p}{episode})) {
             print $FH &enc($programs{$p}{episode});
          } else {
             print $FH "Movie (" . $programs{$p}{movie_year} . ")";
          } 
        print $FH "</sub-title>\n"
      }

      print $FH "\t\t<desc lang=\"$lang\">" . &enc($programs{$p}{description}) . "</desc>\n" if defined($programs{$p}{description});

      if (defined($programs{$p}{actor}) 
        || defined($programs{$p}{director})
        || defined($programs{$p}{writer})
        || defined($programs{$p}{producer})
        || defined($programs{$p}{preseter})
        ) {
        print $FH "\t\t<credits>\n";
        &printCredits($FH, $p, "director");
        foreach my $g (sort { $programs{$p}{actor}{$a} <=> $programs{$p}{actor}{$b} } keys %{$programs{$p}{actor}} ) {
          print $FH "\t\t\t<actor";
          print $FH " role=\"" . &enc($programs{$p}{role}{$g}) . "\"" if (defined($programs{$p}{role}{$g}));
          print $FH ">" . &enc($g) . "</actor>\n";
        }
        &printCredits($FH, $p, "writer");
        &printCredits($FH, $p, "producer");
        &printCredits($FH, $p, "presenter");
        print $FH "\t\t</credits>\n";
      }
  
      my $date;
      if (defined($programs{$p}{movie_year})) {
        $date = $programs{$p}{movie_year};
      } elsif (defined($programs{$p}{originalAirDate}) && $p =~ /^EP|^\d/) {
        $date = &convOAD($programs{$p}{originalAirDate});
      }
      print $FH "\t\t<date>$date</date>\n" if defined($date);

      if (defined($programs{$p}{genres})) {
        foreach my $g (sort { $programs{$p}{genres}{$a} <=> $programs{$p}{genres}{$b} or $a cmp $b } keys %{$programs{$p}{genres}} ) {
          print $FH "\t\t<category lang=\"$lang\">" . &enc(ucfirst($g)) . "</category>\n";
        }
      }

      print $FH "\t\t<length units=\"minutes\">" . $programs{$p}{duration} . "</length>\n" if defined($programs{$p}{duration});

      if (defined($programs{$p}{imageUrl})) {
        print $FH "\t\t<icon src=\"" . &enc($programs{$p}{imageUrl}) . "\" />\n";
      }

      if (defined($programs{$p}{url})) {
        print $FH "\t\t<url>" . &enc($programs{$p}{url}) . "</url>\n";
      }

      my $xs;
      my $xe;

      if (defined($programs{$p}{seasonNum}) && defined($programs{$p}{episodeNum})) {
        my $s = $programs{$p}{seasonNum};
        my $sf = sprintf("S%0*d", &max(2, length($s)), $s);
        my $e = $programs{$p}{episodeNum};
        my $ef = sprintf("E%0*d", &max(2, length($e)), $e);

        $xs = int($s) - 1;
        $xe = int($e) - 1;

        if ($s > 0 || $e > 0) {
          print $FH "\t\t<episode-num system=\"common\">" . $sf . $ef . "</episode-num>\n";
        }
      }

      $dd_prog_id = $p;
      if ( $dd_prog_id =~ /^(..\d{8})(\d{4})/ ) {
        $dd_prog_id = sprintf("%s.%s",$1,$2);
        print $FH "\t\t<episode-num system=\"dd_progid\">" . $dd_prog_id  . "</episode-num>\n";
      }

      if (defined($xs) && defined($xe) && $xs >= 0 && $xe >= 0) {
        print $FH "\t\t<episode-num system=\"xmltv_ns\">" . $xs . "." . $xe . ".</episode-num>\n";
      }

      if (defined($schedule{$station}{$s}{quality})) {
        print $FH "\t\t<video>\n";
        print $FH "\t\t\t<aspect>16:9</aspect>\n";
        print $FH "\t\t\t<quality>HDTV</quality>\n";
        print $FH "\t\t</video>\n";
      }
      my $new = defined($schedule{$station}{$s}{new});
      my $live = defined($schedule{$station}{$s}{live});
      my $cc = defined($schedule{$station}{$s}{cc});

      if (! $new && ! $live && $p =~ /^EP|^SH|^\d/) {
        print $FH "\t\t<previously-shown ";
        if (defined($programs{$p}{originalAirDate})) {
          $date = &convOAD($programs{$p}{originalAirDate});
          print $FH "start=\"" . $date . "000000\" ";
        }
        print $FH "/>\n";
      }

      if (defined($schedule{$station}{$s}{premiere})) {
        print $FH "\t\t<premiere>" . $schedule{$station}{$s}{premiere} . "</premiere>\n";
      }

      if (defined($schedule{$station}{$s}{finale})) {
        print $FH "\t\t<last-chance>" . $schedule{$station}{$s}{finale} . "</last-chance>\n";
      }

      print $FH "\t\t<new />\n" if $new;
      # not part of XMLTV format yet?
      print $FH "\t\t<live />\n" if (defined($options{L}) && $live);
      print $FH "\t\t<subtitles type=\"teletext\" />\n" if $cc;

      if (defined($programs{$p}{rating})) {
        print $FH "\t\t<rating>\n\t\t\t<value>" . $programs{$p}{rating} . "</value>\n\t\t</rating>\n"
      }

      if (defined($programs{$p}{starRating})) {
        print $FH "\t\t<star-rating>\n\t\t\t<value>" . $programs{$p}{starRating} . "/4</value>\n\t\t</star-rating>\n";
      }
      print $FH "\t</programme>\n";
      $i++;
    }
  }
}

sub printHeaderXTVD {
  my ($FH, $enc) = @_;
  print $FH "<?xml version='1.0' encoding='$enc'?>\n";
  print $FH "<xtvd from='" . &convTimeXTVD($XTVD_startTime) . "' to='" . &convTimeXTVD($XTVD_endTime)  . "' schemaVersion='1.3' xmlns='urn:TMSWebServices' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='urn:TMSWebServices http://docs.tms.tribune.com/tech/xml/schemas/tmsxtvd.xsd'>\n";
}

sub printCredits {
  my ($FH, $p, $s)  = @_;
  foreach my $g (sort { $programs{$p}{$s}{$a} <=> $programs{$p}{$s}{$b} } keys %{$programs{$p}{$s}} ) {
    print $FH "\t\t\t<$s>" . &enc($g) . "</$s>\n";
  }
}

sub printFooterXTVD {
  my $FH = shift;
  print $FH "</xtvd>\n";
} 

sub printStationsXTVD {
  my $FH = shift;
  print $FH "<stations>\n";
  for my $key ( sort sortChan keys %stations ) {
    print $FH "\t<station id='" . $stations{$key}{stnNum} . "'>\n";
    if (defined($stations{$key}{number})) {
      $sname = &enc($stations{$key}{name});
      print $FH "\t\t<callSign>" . $sname . "</callSign>\n";
      print $FH "\t\t<name>" . $sname . "</name>\n";
      print $FH "\t\t<fccChannelNumber>" . $stations{$key}{number} . "</fccChannelNumber>\n";
      &copyLogo($key);
    }
    print $FH "\t</station>\n";
  }
  print $FH "</stations>\n";
}

sub printLineupsXTVD {
  my $FH = shift;
  print $FH "<lineups>\n";
  print $FH "\t<lineup id='$lineupId' name='$lineupname' location='$lineuplocation' type='$lineuptype' postalCode='$postalcode'>\n";
  for my $key ( sort sortChan keys %stations ) {
    if (defined($stations{$key}{number})) {
      print $FH "\t<map station='" . $stations{$key}{stnNum} . "' channel='" . $stations{$key}{number} . "'></map>\n";
    }
  }
  print $FH "\t</lineup>\n";
  print $FH "</lineups>\n";
}

sub printSchedulesXTVD {
  my $FH = shift;
  print $FH "<schedules>\n";
  for my $station ( sort sortChan keys %stations ) {
    my $i = 0; 
    my @keyArray = sort { $schedule{$station}{$a}{time} cmp $schedule{$station}{$b}{time} } keys %{$schedule{$station}};
    foreach $s (@keyArray) {
      if ($#keyArray <= $i) {
        delete $schedule{$station}{$s};
        next; 
      } 
      my $p = $schedule{$station}{$s}{program};
      my $startTime = &convTimeXTVD($schedule{$station}{$s}{time});
      my $stopTime = &convTimeXTVD($schedule{$station}{$keyArray[$i+1]}{time});
      my $duration = &convDurationXTVD($schedule{$station}{$keyArray[$i+1]}{time} - $schedule{$station}{$s}{time});

      print $FH "\t<schedule program='$p' station='" . $stations{$station}{stnNum} . "' time='$startTime' duration='$duration'"; 
      print $FH " hdtv='true' " if (defined($schedule{$station}{$s}{quality}));
      print $FH " new='true' " if (defined($schedule{$station}{$s}{new}) || defined($schedule{$station}{$s}{live}));
      print $FH "/>\n";
      $i++;
    }
  }
  print $FH "</schedules>\n";
}

sub printProgramsXTVD {
  my $FH = shift;
  print $FH "<programs>\n";
  foreach $p (keys %programs) {
      print $FH "\t<program id='" . $p . "'>\n";
      print $FH "\t\t<title>" . &enc($programs{$p}{title}) . "</title>\n" if defined($programs{$p}{title});
      print $FH "\t\t<subtitle>" . &enc($programs{$p}{episode}) . "</subtitle>\n" if defined($programs{$p}{episode});
      print $FH "\t\t<description>" . &enc($programs{$p}{description}) . "</description>\n" if defined($programs{$p}{description});
      
      if (defined($programs{$p}{movie_year})) {
        print $FH "\t\t<year>" . $programs{$p}{movie_year} . "</year>\n";
      } else { #Guess
        my $showType = "Series"; 
        if ($programs{$p}{title} =~ /Paid Programming/i) {
          $showType = "Paid Programming";
        } 
        print $FH "\t\t<showType>$showType</showType>\n"; 
        print $FH "\t\t<series>EP" . substr($p,2,8) . "</series>\n"; 
        print $FH "\t\t<originalAirDate>" . &convOADXTVD($programs{$p}{originalAirDate}) . "</originalAirDate>\n" if defined($programs{$p}{originalAirDate});
      }
      print $FH "\t</program>\n";
  }
  print $FH "</programs>\n";
}

sub printGenresXTVD {
  my $FH = shift;
  print $FH "<genres>\n";
  foreach $p (keys %programs) {
    if (defined($programs{$p}{genres}) && $programs{$p}{genres}{movie} != 1) {
      print $FH "\t<programGenre program='" . $p . "'>\n";
      foreach my $g (keys %{$programs{$p}{genres}}) {
        print $FH "\t\t<genre>\n";
        print $FH "\t\t\t<class>" . &enc(ucfirst($g)) . "</class>\n";
        print $FH "\t\t\t<relevance>0</relevance>\n";
        print $FH "\t\t</genre>\n";
      }
      print $FH "\t</programGenre>\n";
    }
  }
  print $FH "</genres>\n";
}

sub loginTVG {
  my $r = &ua_get($tvgurl . 'signin/');
  if ($r->is_success) {
    my $str = $r->decoded_content;
    if ($str =~ /<input.+name=\"_token\".+?value=\"(.*?)\"/is) {
      $token = $1;
      if ($userEmail ne '' && $password ne '') {
        my $rc = 0;
        while ($rc++ < $retries) {
          my $r = &ua_post($tvgurl . 'user/attempt/', 
            { 
              _token => $token,
              email => $userEmail, 
              password => $password,
            }, 'X-Requested-With' => 'XMLHttpRequest'
          ); 

          $dc = Encode::encode('utf8', $r->decoded_content( raise_error => 1 ));
          if ($dc =~ /success/) {
            $ua->cookie_jar->scan(sub { if ($_[1] eq "ServiceID") { $zlineupId = $_[2]; }; }); 
            if (!defined($options{a})) {
              my $r = &ua_get($tvgurl . "user/favorites/?provider=$zlineupId",'X-Requested-With' => 'XMLHttpRequest'); 
              $dc = Encode::encode('utf8', $r->decoded_content( raise_error => 1 ));
              if ($dc =~ /\{\"code\":200/) {
                &parseTVGFavs($dc);
              } 
            }
            return $dc; 
          } else {
            &pout("[Attempt $rc] " . $r->status_line . ":"  . $dc . "\n");
            sleep ($sleeptime + 1);
          }
        }
        die "Failed to login within $retries retries.\n";
      }
    } else {
      die "Login token not found\n";
    }
  }
}

sub loginZAP {
  my $rc = 0;
  while ($rc++ < $retries) {
    my $r = &ua_post($urlRoot . 'api/user/login', 
      { 
        emailid => $userEmail, password => $password,
        usertype => '0', facebookuser =>'false',
      }
    ); 
 
    $dc = Encode::encode('utf8', $r->decoded_content( raise_error => 1 ));
    if ($r->is_success) {
      my $t = decode_json($dc);
      $zapToken = $t->{'token'};
      $zapPref = '';
      $zapPref .= "m" if ($t->{isMusic});
      $zapPref .= "p" if ($t->{isPPV});
      $zapPref .= "h" if ($t->{isHD});
      if ($zapPref eq '') { $zapPref = '-' } 
      else {
        $zapPref = join(",", split(//, $zapPref));
      } 

      my $prs = $t->{'properties'};
      $postalcode = $prs->{2002};
      $country = $prs->{2003};
      ($lineupId, $device) = split(/:/, $prs->{2004});
      if (!defined($options{a})) {
        my $r = &ua_post($urlRoot . "api/user/favorites", { token => $zapToken }, 'X-Requested-With' => 'XMLHttpRequest'); 
        $dc = Encode::encode('utf8', $r->decoded_content( raise_error => 1 ));
        if ($r->is_success) {
          &parseZFavs($dc);
        } else { 
          &perr("FF" . $r->status_line .  ": $dc\n");
        }
      }
      return $dc;
    } else {
      &pout("[Attempt $rc] " . $dc . "\n");
      sleep ($sleeptime + 1);
    }
  }
  die "Failed to login within $retries retries.\n";
}

sub getZapGParams {
  my %hash = &getZapParams();
  $hash{country} = delete $hash{countryCode};
  return join("&", map { "$_=$hash{$_}" } keys %hash);
}

sub getZapPParams {
  my %hash = &getZapParams();
  delete $hash{lineupId};
  return %hash;
}

sub getZapParams {
  my %phash = ();
  if (defined($zlineupId) || defined($zipcode)) {
    $postalcode = $zipcode;
    $country = "USA";
    $country = "CAN" if ($zipcode =~ /[A-z]/);
    if ($zlineupId =~ /:/) {
       ($lineupId, $device) = split(/:/, $zlineupId);
    } else {
       $lineupId = $zlineupId;
       $device = "-";
    }
    $phash{postalCode} = $postalcode;
  } else {
    $phash{token} = &getZToken();
  }
  $phash{lineupId} = "$country-$lineupId-DEFAULT";
  $phash{postalCode} = $postalcode;
  $phash{countryCode} = $country;
  $phash{headendId} = $lineupId;
  $phash{device} = $device;
  $phash{aid} = 'gapzap';
  return %phash;
}

sub login {
  if (!defined($userEmail) || $userEmail eq '' || !defined($password) || $password eq '') {
    if (!defined($zlineupId)) {
      die "Unable to login: Unspecified username or password.\n"
    }
  }

  if (!defined($ua)) {
    $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 }); # WIN
    $ua->conn_cache(LWP::ConnCache->new( total_capacity => undef ));
    $ua->cookie_jar(HTTP::Cookies->new);
    $ua->proxy(['http', 'https'], $proxy) if defined($proxy);
    $ua->agent('Mozilla/4.0');
    $ua->default_headers->push_header('Accept-Encoding' => 'gzip, deflate');
  }

  if ($userEmail ne '' && $password ne '') {
    &pout("Logging in as \"$userEmail\" (" . localtime . ")\n");
    if (defined($options{z})) {
      &loginTVG();
    } else {
      &loginZAP();
    }
  } else {
    &pout("Connecting with lineupId \"$zlineupId\" (" . localtime . ")\n");
  }
}

sub ua_stats {
  my ($s, @p) = @_;
  my $r;
  if ($s eq 'POST') {
    $r = $ua->post(@p);
  } else { 
    $r = $ua->get(@p);
  }
  my $cc = $ua->conn_cache;
  if (defined($cc)) {
    my @cxns = $cc->get_connections();
    foreach (@cxns) {
      $tsocks{$_} = 1;
    }
  }
  $treq++;
  $tb += length($r->content);
  return $r;
}

sub ua_get { return &ua_stats('GET', @_); }
sub ua_post { return &ua_stats('POST', @_); }

sub getURL {
  my $url = shift;
  my $er = shift;
  &login() if !defined($ua);

  my $rc = 0;
  while ($rc++ < $retries) {
    &pout("[$treq] Getting: $url\n");
    sleep $sleeptime; # do these rapid requests flood servers?
    my $r = &ua_get($url);
    my $cl = length($r->content);
    my $dc = $r->decoded_content( raise_error => 1 );
    if ($r->is_success && $cl) {
      return $dc;
    } elsif ($r->code == 500 && $dc =~ /Could not load details/) {
      &pout("$dc\n");
      return "";
    } else {
      &perr("[Attempt $rc] $cl:" . $r->status_line . "\n");
      &perr($r->content . "\n");
      sleep ($sleeptime + 2);
    }
  }
  &perr("Failed to download within $retries retries.\n");
  if ($er) { 
    &perr("Server out of data? Temporary server error? Normal exit anyway.\n");
    return "";
  };
  die;
}

sub wbf {
  my($f, $s) = @_;
  open(FO, ">$f") or die "Failed to open '$f': $!";
  binmode(FO);
  print FO $s;
  close(FO);
}

sub unf {
  my $f = shift;
  unlink($f) or &perr("Failed to delete '$f': $!");
}

sub copyLogo {
  my $key = shift;
  my $cid = $key;
  if (!defined($logos{$cid}{logo})) {
     $cid = substr($key, rindex($key, ".")+1);
  }
  if (defined($iconDir) && defined($logos{$cid}{logo})) {
    my $num = $stations{$key}{number};
    my $src = "$iconDir/" . $logos{$cid}{logo} . $logos{$cid}{logoExt};
    my $dest1 = "$iconDir/$num" . $logos{$cid}{logoExt};
    my $dest2 = "$iconDir/$num " . $stations{$key}{name} . $logos{$cid}{logoExt};
    my $dest3 = "$iconDir/$num\_" . $stations{$key}{name} . $logos{$cid}{logoExt};
    copy($src, $dest1);
    copy($src, $dest2);
    copy($src, $dest3);
  }
}

sub handleLogo {
  my $url = shift;
  if (! -d $iconDir) {
    mkdir($iconDir) or die "Can't mkdir: $!\n";
  }
  my $n; my $s;  ($n,$_,$s) = fileparse($url, qr"\..*");
  $stations{$cs}{logoURL} = $url;
  $logos{$cs}{logo} = $n;
  $logos{$cs}{logoExt} = $s;
  my $f = $iconDir . "/" . $n . $s;
  if (! -e $f) { &wbf($f, &getURL($url,0)); }
}

sub setOriginalAirDate {
  if (substr($cp,10,4) ne '0000') {
    if (!defined($programs{$cp}{originalAirDate})
        || ($schedule{$cs}{$sch}{time} < $programs{$cp}{originalAirDate})) {
      $programs{$cp}{originalAirDate} = $schedule{$cs}{$sch}{time};
    }
  }
}

sub getZToken {
  &login() if (!defined($zapToken));
  return $zapToken;
}

sub parseZFavs {
  my $buffer = shift;
  my $t = decode_json($buffer);
  if (defined($t->{'channels'})) {
    my $m = $t->{'channels'};
    foreach my $f (@{$m}) {
      if ($options{R}) {
        my $r = &ua_post($urlRoot . "api/user/ChannelAddtofav", { token => $zapToken, prgsvcid => $f, addToFav => "false" }, 'X-Requested-With' => 'XMLHttpRequest');
        if ($r->is_success) {
          &pout("Removed favorite $f\n");
        } else {
          &perr("RF" . $r->status_line .  "\n");
        }
      } else {
        $zapFavorites{$f} = 1;
      }
    }
    if ($options{R}) {
        &pout("Removed favorites, exiting\n");
        exit;
    };
    &pout("Lineup favorites: " .  (keys %zapFavorites) . "\n");
  }
}

sub parseTVGFavs {
  my $buffer = shift;
  my $t = decode_json($buffer);
  if (defined($t->{'message'})) {
    my $m = $t->{'message'};
    foreach my $f (@{$m}) {
      my $source = $f->{"source"};
      my $channel = $f->{"channel"};
      $tvgfavs{"$channel.$source"} = 1;
    }
    &pout("Lineup $zlineupId favorites: " .  (keys %tvgfavs) . "\n");
  }
}

sub parseTVGIcons {
  require GD;
  $rc = Encode::encode('utf8', &getURL($tvgspritesurl . "$zlineupId\.css",0) );
  if ($rc =~ /background-image:.+?url\((.+?)\)/) {
    my $url = $tvgspritesurl . $1;

    if (! -d $iconDir) {
      mkdir($iconDir) or die "Can't mkdir: $!\n";
    }

    ($n,$_,$s) = fileparse($url, qr"\..*");
    $f = $iconDir . "/sprites-" . $n . $s;
    &wbf($f, &getURL($url,0));

    GD::Image->trueColor(1);
    $im = new GD::Image->new($f);

    my $iconw = 30;
    my $iconh = 20;
    while ($rc =~ /listings-channel-icon-(.+?)\{.+?position:.*?\-(\d+).+?(\d+).*?\}/isg) {
      my $cid = $1;
      my $iconx = $2;
      my $icony = $3;

      my $icon = new GD::Image($iconw,$iconh);
      $icon->alphaBlending(0);
      $icon->saveAlpha(1);
      $icon->copy($im, 0, 0, $iconx, $icony, $iconw, $iconh);

      $logos{$cid}{logo} = "sprite-" . $cid;
      $logos{$cid}{logoExt} = $s;

      my $ifn = $iconDir . "/" . $logos{$cid}{logo} . $logos{$cid}{logoExt};
      &wbf($ifn, $icon->png);
    }
  }
}

sub parseTVGD {
  my $gz = gzopen(shift, "rb");
  my $buffer;
  $buffer .= $b while $gz->gzread($b, 65535) > 0;
  $gz->gzclose();
  my $t = decode_json($buffer);

  if (defined($t->{'program'})) {
    my $prog = $t->{'program'};
    if (defined($prog->{'release_year'})) {
      $programs{$cp}{movie_year} = $prog->{'release_year'};
    }
    if (defined($prog->{'rating'}) && !defined($programs{$cp}{rating})) {
      $programs{$cp}{rating} = $prog->{'rating'} if $prog->{'rating'} ne 'NR';
    }
  }

  if (defined($t->{'tvobject'})) {
    my $tvo = $t->{'tvobject'};
    if (defined($tvo->{'photos'})) {
      my $photos = $tvo->{'photos'};
      my %phash;
      foreach $ph (@{$photos}) {
        my $w = $ph->{'width'} * $ph->{'height'};
        my $u = $ph->{'url'};
        $phash{$w} = $u;
      }
      my $big = (sort {$b <=> $a} keys %phash)[0];
      $programs{$cp}{imageUrl} = $phash{$big};
    }
  }
}

sub parseTVGGrid {
  my $gz = gzopen(shift, "rb");
  my $buffer;
  $buffer .= $b while $gz->gzread($b, 65535) > 0;
  $gz->gzclose();
  my $t = decode_json($buffer);

  foreach my $e (@{$t}) {
    my $cjs = $e->{'Channel'};
    my $src = $cjs->{'SourceId'};
    my $num = $cjs->{'Number'};

    $cs = "$num.$src"; 

    if (%tvgfavs) {
      next if (!$tvgfavs{$cs});
    }

    if (!defined($stations{$cs}{stnNum})) {
      $stations{$cs}{stnNum} = $src;
      $stations{$cs}{number} = $num;
      $stations{$cs}{name} = $cjs->{'Name'};
      if (defined($cjs->{'FullName'}) && $cjs->{'FullName'} ne $cjs->{'Name'}) {
        if ($cjs->{'FullName'} ne '') {
          $stations{$cs}{fullname} = $cjs->{'FullName'};
        }
      }

      if (!defined($stations{$cs}{order})) {
        if (defined($options{b})) {
          $stations{$cs}{order} = $coNum++;
        } else {
          $stations{$cs}{order} = $stations{$cs}{number};
        }
      }
    }

    my $cps = $e->{'ProgramSchedules'};
    foreach my $pe (@{$cps}) {
      next if (!defined($pe->{'ProgramId'}));
      $cp = $pe->{'ProgramId'};
      my $catid = $pe->{'CatId'};

      if ($catid == 1) { $programs{$cp}{genres}{movie} = 1 } 
      elsif ($catid == 2) { $programs{$cp}{genres}{sports} = 1 } 
      elsif ($catid == 3) { $programs{$cp}{genres}{family} = 1 } 
      elsif ($catid == 4) { $programs{$cp}{genres}{news} = 1 } 
      # 5 - 10?
      # my $subcatid = $pe->{'SubCatId'}; 

      my $ppid = $pe->{'ParentProgramId'};
      if ((defined($ppid) && $ppid != 0)
        || (defined($options{j}) && $catid != 1)) {
        $programs{$cp}{genres}{series} = 99; 
      }

      $programs{$cp}{title} = $pe->{'Title'};
      $tba = 1 if $programs{$cp}{title} =~ /$sTBA/i;

      if (defined($pe->{'EpisodeTitle'}) && $pe->{'EpisodeTitle'} ne '') {
        $programs{$cp}{episode} = $pe->{'EpisodeTitle'};
        $tba = 1 if $programs{$cp}{episode} =~ /$sTBA/i;
      }

      $programs{$cp}{description} = $pe->{'CopyText'} if defined($pe->{'CopyText'}) && $pe->{'CopyText'} ne '';
      $programs{$cp}{rating} = $pe->{'Rating'} if defined($pe->{'Rating'}) && $pe->{'Rating'} ne '';

      my $sch = $pe->{'StartTime'} * 1000;
      $schedule{$cs}{$sch}{time} = $sch;
      $schedule{$cs}{$sch}{endtime} = $pe->{'EndTime'} * 1000;
      $schedule{$cs}{$sch}{program} = $cp;
      $schedule{$cs}{$sch}{station} = $cs;

      my $airat = $pe->{'AiringAttrib'};
      if ($airat & 1) { $schedule{$cs}{$sch}{live} = 1 }
      elsif ($airat & 4) { $schedule{$cs}{$sch}{new} = 1 }
      # other bits?

      my $tvo = $pe->{'TVObject'};
      if (defined($tvo)) {
        if (defined($tvo->{'SeasonNumber'}) && $tvo->{'SeasonNumber'} != 0) {
          $programs{$cp}{seasonNum} = $tvo->{'SeasonNumber'};
          if (defined($tvo->{'EpisodeNumber'}) && $tvo->{'EpisodeNumber'} != 0) {
            $programs{$cp}{episodeNum} = $tvo->{'EpisodeNumber'};
          }
        }
        if (defined($tvo->{'EpisodeAirDate'})) {
          my $eaid = $tvo->{'EpisodeAirDate'}; # GMT @ 00:00:00
          $eaid =~ tr/\-0-9//cd;
          $programs{$cp}{originalAirDate} = $eaid if ($eaid ne '');
        }
        my $url;
        if (defined($tvo->{'EpisodeSEOUrl'}) && $tvo->{'EpisodeSEOUrl'} ne '') {
          $url = $tvo->{'EpisodeSEOUrl'};
        } elsif(defined($tvo->{'SEOUrl'}) && $tvo->{'SEOUrl'} ne '') {
          $url = $tvo->{'SEOUrl'};
          $url = "/movies$url" if ($catid == 1 && $url !~ /movies/); 
        }
        $programs{$cp}{url} = substr($tvgurl, 0, -1) . $url if defined($url);
      }
  
      if (defined($options{I}) 
        || (defined($options{D}) && $programs{$cp}{genres}{movie}) 
        || (defined($options{W}) && $programs{$cp}{genres}{movie}) ) {
          &getDetails(\&parseTVGD, $cp, $tvgMapiRoot . "listings/details?program=$cp", "");
      } 
    }
  }
}

sub getDetails {
  my ($func, $cp, $url, $prefix) = @_;
  my $fn = "$cacheDir/$prefix$cp\.js\.gz";
  if (! -e $fn) {
    my $rs = &getURL($url,1);
    if (length($rs)) {
      $rc = Encode::encode('utf8', $rs);
      &wbf($fn, Compress::Zlib::memGzip($rc));
    }
  }
  if (-e $fn) {
    my $l = length($prefix) ? $prefix : "D";
    &pout("[$l] Parsing: $cp\n");
    $func->($fn);
  } else {
    &pout("Skipping: $cp\n");
  }
}

sub parseJSON {
  my $gz = gzopen(shift, "rb");
  my $buffer;
  $buffer .= $b while $gz->gzread($b, 65535) > 0;
  $gz->gzclose();
  my $t = decode_json($buffer);

  my $sts = $t->{'channels'};
  my %zapStarred=();
  foreach $s (@$sts) {

    if (defined($s->{'channelId'})) {
      if (!$allChan && scalar(keys %zapFavorites)) {
	if ($zapFavorites{$s->{channelId}}) {
          if ($options{8}) {
            next if $zapStarred{$s->{channelId}};
	    $zapStarred{$s->{channelId}} = 1;
          } 
	} else {
          next;
	}
      }
      # id (uniq) vs channelId, but id not nec consistent in cache
      $cs = $s->{channelNo} . "." . $s->{channelId};
      $stations{$cs}{stnNum} = $s->{channelId};
      $stations{$cs}{name} = $s->{'callSign'};
      $stations{$cs}{number} = $s->{'channelNo'};
      $stations{$cs}{number} =~ s/^0+//g;

      if (!defined($stations{$cs}{order})) {
        if (defined($options{b})) {
          $stations{$cs}{order} = $coNum++; 
        } else {
          $stations{$cs}{order} = $stations{$cs}{number};
        }
      }

      if ($s->{'thumbnail'} ne '') {
        my $url = $s->{'thumbnail'};
        $url =~ s/\?.*//;  # remove size
        if ($url !~ /^http/) {
          $url = "https:" . $url;
        }
        $stations{$cs}{logoURL} = $url;
        &handleLogo($url) if defined($iconDir);
      }

      my $events = $s->{'events'};
      foreach $e (@$events) {
        my $program = $e->{'program'};
        $cp = $program->{'id'};
        $programs{$cp}{title} = $program->{'title'};
        $tba = 1 if $programs{$cp}{title} =~ /$sTBA/i;
        $programs{$cp}{episode} = $program->{'episodeTitle'} if ($program->{'episodeTitle'} ne '');
        $programs{$cp}{description} = $program->{'shortDesc'} if ($program->{'shortDesc'} ne '');
        $programs{$cp}{duration} = $e->{duration} if ($e->{duration} > 0);
        $programs{$cp}{movie_year} = $program->{releaseYear} if ($program->{releaseYear} ne '');
        $programs{$cp}{seasonNum} = $program->{season} if ($program->{'season'} ne '');
        if ($program->{'episode'} ne '') {
          $programs{$cp}{episodeNum} = $program->{episode};
        }
        if ($e->{'thumbnail'} ne '') {
          my $turl = $urlAssets;
          $turl .= $e->{'thumbnail'}  . ".jpg";
          $programs{$cp}{imageUrl} = $turl;
        }
        if ($program->{'seriesId'} ne '' && $program->{'tmsId'} ne '') {
           $programs{$cp}{url} = $urlRoot . "/overview.html?programSeriesId=" 
                . $program->{seriesId} . "&tmsId=" . $program->{tmsId};
        }

        $sch = str2time1($e->{'startTime'}) * 1000;
        $schedule{$cs}{$sch}{time} = $sch;
        $schedule{$cs}{$sch}{endTime} = str2time1($e->{'endTime'}) * 1000;
        $schedule{$cs}{$sch}{program} = $cp;
        $schedule{$cs}{$sch}{station} = $cs;

        if ($e->{'filter'}) {
          my $genres = $e->{'filter'};
          my $i = 1;
          foreach $g (@{$genres}) {
            $g =~ s/filter-//i;
            ${$programs{$cp}{genres}}{lc($g)} = $i++;
          }
        }

        $programs{$cp}{rating} = $e->{rating} if ($e->{rating} ne '');

        if ($e->{'tags'}) {
          my $tags = $e->{'tags'};
          if (grep $_ eq 'CC', @{$tags}) {
            $schedule{$cs}{$sch}{cc} = 1
          }
        }

        if ($e->{'flag'}) {
          my $flags = $e->{'flag'};
          if (grep $_ eq 'New', @{$flags}) {
            $schedule{$cs}{$sch}{new} = 'New'
            &setOriginalAirDate();
          }
          if (grep $_ eq 'Live', @{$flags}) {
            $schedule{$cs}{$sch}{live} = 'Live'
            &setOriginalAirDate(); # live to tape?
          }
          if (grep $_ eq 'Premiere', @{$flags}) {
            $schedule{$cs}{$sch}{premiere} = 'Premiere';
          }
          if (grep $_ eq 'Finale', @{$flags}) {
            $schedule{$cs}{$sch}{finale} = 'Finale';
          }
        }

        if ($options{D} && !$program->{isGeneric}) {
          &postJSONO($cp, $program->{seriesId});
        }
        if (defined($options{j}) && $cp !~ /^MV/) {
          $programs{$cp}{genres}{series} = 99; 
        }
      }
    }
  }
  return 0;
}

sub postJSONO { 
  my ($cp, $sid) = @_;
  my $fn = "$cacheDir/O$cp\.js\.gz";

  if (! -e $fn && defined($sidCache{$sid}) && -e $sidCache{$sid}) {
    copy($sidCache{$sid}, $fn);
  }
  if (! -e $fn) {
    my $url = $urlRoot . 'api/program/overviewDetails';
    &pout("[$treq] Post $sid: $url\n");
    sleep $sleeptime; # do these rapid requests flood servers?
    my %phash = &getZapPParams();
    $phash{programSeriesID} = $sid;
    $phash{'clickstream[FromPage]'} = 'TV%20Grid';
    my $r = &ua_post($url, \%phash, 'X-Requested-With' => 'XMLHttpRequest'); 
    if ($r->is_success) {
      $dc = Encode::encode('utf8', $r->decoded_content( raise_error => 1 ));
      &wbf($fn, Compress::Zlib::memGzip($dc));
      $sidCache{$sid} = $fn;
    } else {
      &perr($id . " :" . $r->status_line);
    }
  }
  if (-e $fn) {
    &pout("[D] Parsing: $cp\n");
    my $gz = gzopen($fn, "rb");
    my $buffer;
    $buffer .= $b while $gz->gzread($b, 65535) > 0;
    $gz->gzclose();
    my $t = decode_json($buffer);

    if ($t->{seriesGenres} ne '') {
      my $i = 2;
      my %gh = %{$programs{$cp}{genres}};
      if (keys %gh) {
        my @genArr = sort { $gh{$a} <=> $gh{$b} } keys %gh;
        my $max = $genArr[-1];
        $i = $gh{$max} + 1;
      }
      foreach my $sg (split(/\|/, lc($t->{seriesGenres}))) {
	if (!${$programs{$cp}{genres}}{$sg}) {
          ${$programs{$cp}{genres}}{$sg} = $i++;
        }
      }
    }

    my $i = 1;
    foreach my $c (@{$t->{'overviewTab'}->{cast}}) {
      my $n = $c->{name};
      my $cn = $c->{characterName};
      my $cr = lc($c->{role});

      if ($cr eq 'host') {
        ${$programs{$cp}{presenter}}{$n} = $i++;
      } else {
        ${$programs{$cp}{actor}}{$n} = $i++;
        ${$programs{$cp}{role}}{$n} = $cn if length($cn);
      } 
    } 
    $i = 1;
    foreach my $c (@{$t->{'overviewTab'}->{crew}}) {
      my $n = $c->{name};
      my $cr = lc($c->{role});
      if ($cr =~ /producer/) {
        ${$programs{$cp}{producer}}{$n} = $i++;
      } elsif ($cr =~ /director/) {
        ${$programs{$cp}{director}}{$n} = $i++;
      } elsif ($cr =~ /writer/) {
        ${$programs{$cp}{writer}}{$n} = $i++;
      }
    } 
    if (!defined($programs{$cp}{imageUrl}) && $t->{seriesImage} ne '') {
      my $turl = $urlAssets;
      $turl .= $t->{seriesImage} . ".jpg";
      $programs{$cp}{imageUrl} = $turl;
    }
    if ($cp =~ /^MV|^SH/ && length($t->{seriesDescription}) > length($programs{$cp}{description})) {
      $programs{$cp}{description} = $t->{seriesDescription};
    }
    if ($cp =~ /^EP/) { # GMT @ 00:00:00
      my $ue = $t->{overviewTab}->{upcomingEpisode};
      if (defined($ue) && lc($ue->{tmsID}) eq lc($cp) 
        && $ue->{originalAirDate} ne ''
        && $ue->{originalAirDate} ne '1000-01-01T00:00Z') {
          $oad = str2time2($ue->{originalAirDate}) ;
          $oad *= 1000; 
          $programs{$cp}{originalAirDate} = $oad;
      } else {
        foreach my $ue (@{$t->{upcomingEpisodeTab}}) {
          if (lc($ue->{tmsID}) eq lc($cp) 
		&& $ue->{originalAirDate} ne ''
		&& $ue->{originalAirDate} ne '1000-01-01T00:00Z'
	    ) {
              $oad = str2time2($ue->{originalAirDate}) ;
              $oad *= 1000; 
              $programs{$cp}{originalAirDate} = $oad;
              last;
          }
        }  
      }
    }
  } else {
    &pout("Skipping: $sid\n");
  }
}

sub str2time1 {
  my $t = Time::Piece->strptime(shift, '%Y-%m-%dT%H:%M:%SZ');
  return $t->epoch();
}

sub str2time2 {
  my $t = Time::Piece->strptime(shift, '%Y-%m-%dT%H:%MZ');
  return $t->epoch();
}

sub hourToMillis {
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  if ($start == 0) {
    $hour = int($hour/$gridHours) * $gridHours;
  } else {
    $hour = 0; 
  }
  $t = timegm(0,0,$hour,$mday,$mon,$year);
  $t = $t - (&tz_offset * 3600) if !defined($options{g});
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($t);
  $t = timegm($sec, $min, $hour,$mday,$mon,$year);
  return $t . "000";
}

sub tz_offset {
  my $n = defined $_[0] ? $_[0] : time;
  my ($lm, $lh, $ly, $lyd) = (localtime $n)[1, 2, 5, 7];
  my ($gm, $gh, $gy, $gyd) = (gmtime $n)[1, 2, 5, 7];
  ($lm - $gm)/60 + $lh - $gh + 24 * ($ly - $gy || $lyd - $gyd)
}

sub timezone {
  my $tztime = defined $_[0] ? &_rtrim3(shift) : time; 
  my $os = sprintf "%.1f", (timegm(localtime($tztime)) - $tztime) / 3600;
  my $mins = sprintf "%02d", abs( $os - int($os) ) * 60;
  return sprintf("%+03d", int($os)) . $mins;
}

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

sub HELP_MESSAGE {
print <<END;
zap2xml <zap2xml\@gmail.com> ($VERSION)
  -u <username>
  -p <password>
  -d <# of days> (default = $days)
  -n <# of no-cache days> (from end)   (default = $ncdays)
  -N <# of no-cache days> (from start) (default = $ncsdays)
  -B <no-cache day>
  -s <start day offset> (default = $start)
  -o <output xml filename> (default = "$outFile")
  -c <cacheDirectory> (default = "$cacheDir")
  -l <lang> (default = "$lang")
  -i <iconDirectory> (default = don't download channel icons)
  -m <#> = offset program times by # minutes (better to use TZ env var)
  -b = retain website channel order
  -x = output XTVD xml file format (default = XMLTV)
  -w = wait on exit (require keypress before exiting)
  -q = quiet (no status output)
  -r <# of connection retries before failure> (default = $retries, max 20)
  -e = hex encode entities (html special characters like accents)
  -E "amp apos quot lt gt" = selectively encode standard XML entities
  -F = output channel names first (rather than "number name")
  -O = use old tv_grab_na style channel ids (C###nnnn.zap2it.com)
  -A "new live" = append " *" to program titles that are "new" and/or "live"
  -M = copy movie_year to empty movie sub-title tags
  -U = UTF-8 encoding (default = "ISO-8859-1")
  -L = output "<live />" tag (not part of xmltv.dtd)
  -T = don't cache files containing programs with "$sTBA" titles 
  -P <http://proxyhost:port> = to use an http proxy
  -C <configuration file> (default = "$confFile")
  -S <#seconds> = sleep between requests to prevent flooding of server 
  -D = include details = 1 extra http request per program!
  -I = include icons (image URLs) - 1 extra http request per program!
  -J <xmltv> = include xmltv file in output
  -Y <lineupId> (if not using username/password)
  -Z <zipcode> (if not using username/password)
  -z = use tvguide.com instead of zap2it.com
  -a = output all channels (not just favorites) 
  -j = add "series" category to all non-movie programs
END
sleep(5) if ($^O eq 'MSWin32');
exit 0;
}
