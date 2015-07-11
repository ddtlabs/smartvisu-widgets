# ########################################################################################
#
# motionAction2d for use with fronthem/smartVISU and two (HM) dimmers
#
# The following fhem definitions must be created in order to use this sub as it is:
#
# define d_[prefix]_AUTO_MODE       # used to switch off whole automation for our room
# define [prefix]_MD                # Physical Motion Detector available in fhem
# define d_[prefix]_MD				# MD Dummy used to store several settings
# attr d_[prefix]_MD readingList enable levelDay levelNight status timer uzsu
#
# Requirement:
# Module 98_dummy must be a least version 8809.
#
# How this sub has to be called:
# define n_[prefix]_MD notify [prefix]_MD:motion:.* { motionAction2d('dimmer1', 'dimmer2', 'prefix', 'room') }
#
# Behavior:
# - Actors are turned on only if they are switched off (manual control has priority)
# - If day or night levels are set to 0 then there are no changes of levels (devices
#   settings will not be changed)
# - If motion has already been triggered then there are no unnecessary changes made to the
#   devices.
# - If motion dection switches to a specific level and you change this level while motion
#   detection is active then no further changes will be done. No switch off after x
#   seconds and no recalibration of device levels.
#   This will be done by a simple trick:
#   Frontends (fhem or smartVISU) are or can be configured to set the brightness (pct) to
#   real numbers (eg. 1, 2 or 3) but we will set it to 1.5, 2.5, 3.5... So we can
#   distinguish whether the level was set by this sub or by a gui, physical switch.
#   If your devices does not support .5 pct levels then you have to change this code to
#   even and odd values. However, Homematic does...
#
# ########################################################################################

sub motionAction2d($$$$) {

  # get sub parameters
  my ($dev1,$dev2,$prefix,$room) = @_;

  # load dummy states into variables for 1st check
  my $dummy 		= "d_".$prefix."_MD";
  my $roomAutomatic = ReadingsVal($prefix."_AUTO_MODE", "state", "on");
  my $mdAutomatic   = ReadingsVal($dummy, "enable", "on");
  my $mdStatus      = ReadingsVal($dummy, "status", "off");

  # check if we have to do the job (both actors must be switched off or
  # md has to be already active, and both automatic dummies must be on)
  if ((((Value($dev1) eq "off") && (Value($dev2) eq "off")) || ($mdStatus eq "on")) && \
     ($roomAutomatic eq "on") && ($mdAutomatic eq "on")) {

    # load more dummy states into variables
#    my $mdMode       = ReadingsVal($dummy, "mode", "day");
    my $mdMode       = ReadingsVal($dummy, "state", "day");
    my $mdLevelDay   = ReadingsVal($dummy, "levelDay", "60");
    my $mdLevelNight = ReadingsVal($dummy, "levelNight", "10");
    my $mdTimer      = ReadingsVal($dummy, "timer", "5")*60; # Input in minutes
    my $mdTimerName  = "at_".$prefix."_MD_off";

    # if motion dection is not already active
    if ($mdStatus ne "on") {
      # ... and it's during the day and levelDay is not set to "0"
      if (($mdMode eq "day") && ($mdLevelDay ne 0)) {
        fhem("set " . $dev1 . "," . $dev2 . " pct " . ($mdLevelDay - 0.5) . " 0 2");
        fhem("set " . $dummy . " status on");
      }
      # ... and it's during the night and levelNight is not set to "0"
      elsif (($mdMode eq "night") && ($mdLevelNight ne 0)) {
        fhem("set " . $dev1 . "," . $dev2 . " pct " . ($mdLevelNight - 0.5) . " 0 2");
        fhem("set " . $dummy . " status on");
      }
    }

    # switch off in "mdTimer" seconds or renew time to switch off when night light or day light settings are not set to "0"
    if ( ($mdLevelDay ne 0) || ($mdLevelNight ne 0) ) {
      # at first it was a little bit strange for me to work with 2 levels of quotation and double semicolons to not break out ;-)
      # but nevertheless I got it and a big thank you to Rudolf König for his defmod command!
      fhem('defmod '.$mdTimerName.' at +' . sec2time($mdTimer) . ' { if ((ReadingsVal("'.$dev1.'", "pct", "") =~ /^\d+\.5$/) && (ReadingsVal("'.$dev2.'", "pct", "") =~ /^\d+\.5$/)) { fhem("set '.$dev1.','.$dev2.' pct 0 0 4");; } fhem("setreading '.$dummy.' status off");; } ');
      fhem("attr ".$mdTimerName." room ".$room);
    }
  }
}


# ########################################################################################
#
# motionAction1sw for use with fronthem/smartVISU (no dimmers, just one switch)
#
# ########################################################################################

sub motionAction1sw($$$) {

  my ($dev1,$prefix,$room) = @_;

  my $dummy         = "d_".$prefix."_MD";
  my $mdTimerName   = "at_".$prefix."_MD_off";
  my $roomAutomatic = ReadingsVal($prefix."_AUTO_MODE", "state", "on");
  my $mdAutomatic   = ReadingsVal($dummy, "enable", "on");
  my $mdStatus      = ReadingsVal($dummy, "status", "off");
  my $mdMode        = ReadingsVal($dummy, "state", "day");
  my $mdTimer       = ReadingsVal($dummy, "timer", "5")*60; # Input in minutes

  if (($mdMode eq "night") && ($mdAutomatic eq "on") && ($roomAutomatic eq "on")) {
    if ((Value($dev1) eq "off") || ($mdStatus eq "on")) {
    # if motion dection is not already active
      if ($mdStatus ne "on") {
        fhem("set " . $dev1 . " on");
        fhem("set " . $dummy . " status on");
      }
      fhem('defmod '.$mdTimerName.' at +' . sec2time($mdTimer) . ' { if (ReadingsVal("'.$dummy.'", "status", "") eq "on")  {fhem("set '.$dev1.' off");;} }');
      fhem("attr ".$mdTimerName." room ".$room);
    }
  } #main if
} #fn



##########################################################################################
# sec2time(secs)
# convert seconds to fhem time format
# cpu optimized algorithm for small values
# based on: http://www.perlmonks.org/?node_id=30392 (adam)
##########################################################################################

sub sec2time($) {

	use integer;

	my $sec = shift;

	return "00:00:0$sec" if $sec < 10;
	return "00:00:$sec" if $sec < 60;

	my $errorsec = $sec;
	my $min = $sec / 60, $sec %= 60;
	$sec = "0$sec" if $sec < 10;
        return "00:0$min:$sec" if $min < 10;
        return "00:$min:$sec" if $min < 60;

	my $hr = $min / 60, $min %= 60;
    $min = "0$min" if $min < 10;
        return "0$hr:$min:$sec" if $hr < 10;
        return "$hr:$min:$sec" if $hr < 24;

	Log 1, "Error: more than 86399 secs (>= 1 day) are not allowed by fhem time format for at command. $errorsec secs were converted to 23:59:59 at " . __FILE__ . " line " .  __LINE__ . " (" . whoami() . ")";
        return "23:59:39" if $hr >= 24;
}


##########################################################################################
# whoami()
# get calling function/package name - eg. for more informational log entries
##########################################################################################

sub whoami {(caller(1))[3]}

