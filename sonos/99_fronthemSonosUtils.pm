##############################################
# $Id: 99_fronthemSonosUtils.pm 63 2015-08-22 08:00:00Z dev0 $

package main;
use strict;
use warnings;
use POSIX;
sub

fronthemSonosUtils_Initialize($$)
{
 my ($hash) = @_;
}


##########################################################################################
# sv_SonosGroups()
#
# example call:
# define n_sv_sonosGroups notify [yourPrefix]_.*:currentTrackProvider:.\w.* { sv_SonosGroups($NAME, $EVENT) }
# eg. define n_sv_sonosGroups notify Sonos_.*:currentTrackProvider:.\w.* { sv_SonosGroups($NAME, $EVENT) }
#
# Note:
# If your SONOSPLAYER devices contain more than 1 underscore or umlauts then you have to
# adjust both regexs [-0-9a-zA-Z]+ below.
##########################################################################################

sub sv_setSonosGroupsReadings($$) {
  my ($device,$EVENT) = @_;

  Log3 undef, 4, "EVENT: " . $EVENT;

  my @evt = split(" ",$EVENT);
  my ($evtName, $trigger, $room) = @evt;

  my @pre = devspec2array('TYPE=SONOS');
  my $prefix = shift @pre;

  if ($trigger eq "Gruppenwiedergabe:") {
    fhem("sleep 0.1; setreading $device svIsInThisGroup ".$prefix."_$room");
	fhem("sleep 0.1; setreading $device svIsInAnyGroup 1");
	fhem("sleep 0.1; setreading ".$prefix."_$room svHasClient_"."$device"." 1");
  }
  else {
    fhem("sleep 0.1; setreading $device svIsInThisGroup none");
	fhem("sleep 0.1; setreading $device svIsInAnyGroup 0");
    fhem("sleep 0.1; setreading ".$prefix."_[0-9a-zA-Z]+:FILTER=TYPE=SONOSPLAYER svHasClient_"."$device"." 0");
  }
}



##########################################################################################
# sv_SonosGetTrackPos()
#
# example call:
# define n_sv_sonosGetTrackPos notify [yourPrefix]_.*:transportState:.* { sv_SonosGetTrackPos($NAME,$EVTPART1) }
# eg. define n_sv_sonosGetTrackPos notify Sonos_.*:transportState:.* { sv_SonosGetTrackPos($NAME,$EVTPART1) }
##########################################################################################

sub sv_SonosGetTrackPos($$) {
	my ($device,$evt) = @_;

	my $atName = "at_".$device."_GetTrackPos";
	my $room = "hidden";

	Log3 undef, 4, "sv_SonosGetTrackPos: device: " . $device . " / currentTrackProvider: " . ReadingsVal($device, 'currentTrackProvider','ERROR') . " / currentStreamAudio: " . ReadingsVal($device, "currentStreamAudio","ERROR");
	if (($evt eq "PLAYING") && (ReadingsVal($device, 'currentTrackProvider','') !~ /Gruppenwiedergabe/) && (ReadingsVal($device, 'currentStreamAudio','1') eq 0))
	{
		sv_defineAtTimer($device);
	}
	else
	{
		sv_deleteAtTimer($device);
	}
}

sub sv_defineAtTimer($) {
	my ($device) = @_;

	my $atName = "at_".$device."_GetTrackPos";
	my $room = "hidden";
	my $atSec = "04";

	Log3 undef, 4, "sv_defineAtTimer: defmod ".$atName." at +00:00:" . $atSec . " get ".$device." currentTrackPosition";
	Log3 undef, 4, "sv_defineAtTimer: defmod ".$atName." at +*00:00:" . $atSec . " get ".$device." currentTrackPosition";
	# non permanent at will be modified to permanent at -> TEMPORARY device -> will not be saved
	fhem("defmod ".$atName." at +00:00:" . $atSec . " get ".$device." currentTrackPosition");
	fhem("defmod ".$atName." at +*00:00:" . $atSec . " get ".$device." currentTrackPosition");
	fhem("attr ".$atName." room ".$room);
	return undef;
}

sub sv_deleteAtTimer($) {
	my ($device) = @_;
	my $atName = "at_" . $device . "_GetTrackPos";
	if (ReadingsVal($atName, "state", "doNotExist") ne "doNotExist")
	{
		Log3 undef, 4, "sv_deleteAtTimer: " . "delete $atName";
		fhem("sleep 0.1; setreading ".$device." svTrackPosition 0");
		fhem("delete $atName");
	}
}



##########################################################################################
# sv_SonosSec2time(secs)
# - convert seconds to fhem time format
# - will be used in fronthem converter SonosTrackPos
##########################################################################################

sub sv_SonosSec2time($) {

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

	Log3 undef, 1, "Error: more than 86399 secs (>= 1 day) are not allowed by fhem time format for at command. $errorsec secs were converted to 23:59:59 at ";
	return "23:59:39" if $hr >= 24;
}



##########################################################################################
# sv_calcTrackPosPercent()      ($LastActionResult = eg. GetCurrentTrackPosition: 0:00:11)
##########################################################################################

sub sv_calcTrackPosPercent($$) {
	my ($device, $LastActionResult) = @_;

	my @lar = split(" ", $LastActionResult);
	my ($x, $posT) = @lar;
	my $posP = int(100 * SONOS_GetTimeSeconds($posT) / ( 0.1 + SONOS_GetTimeSeconds(ReadingsVal($device, 'currentTrackDuration', '01:00:00'))));
	#Log3 undef, 4, "Device: " . $device . " / LastActionResult: " . $LastActionResult . " / posP: " . $posP;
	return $posP;
}



###############################################################################
# Init all sv.* readings used by smartvisu Widget
###############################################################################

sub sv_SonosReadingsInit() {
	my @p = devspec2array('TYPE=SONOS');

	my $prefix = shift @p;
	return "No SONOS device" if $prefix eq "";

	my @d = devspec2array("TYPE=SONOSPLAYER:FILTER=NAME=" . $prefix ."_[0-9a-zA-Z]+");
	foreach my $sd (@d) {
		Log3 undef, 1, "notify: setreading ".$prefix."_[A-Za-z0-9] svHasClient_$sd 0";
		fhem("setreading ".$prefix."_[A-Za-z0-9] svHasClient_$sd 0");
	}

	Log3 undef, 1, "notify: setreading " . $prefix . "_[A-Za-z0-9] svPlaylists 0";
	fhem("setreading " . $prefix . "_[A-Za-z0-9] svPlaylists 0");
	Log3 undef, 1, "notify: setreading " . $prefix . "_[A-Za-z0-9] svTrackPosition 0";
	fhem("setreading " . $prefix . "_[A-Za-z0-9] svTrackPosition 0");
	Log3 undef, 1, "notify: setreading " . $prefix . "_[A-Za-z0-9] svIsInAnyGroup 0";
	fhem("setreading " . $prefix . "_[A-Za-z0-9] svIsInAnyGroup 0");
	Log3 undef, 1, "notify: setreading " . $prefix . "_[A-Za-z0-9] svIsInThisGroup none";
	fhem("setreading " . $prefix . "_[A-Za-z0-9] svIsInThisGroup none");
}


###############################################################################
# Delete all sv.* readings used by smartvisu Widget
###############################################################################

sub sv_SonosReadingsDelete() {
	my @p = devspec2array('TYPE=SONOS');
	my $prefix = shift @p;

	return "No SONOS device" if $prefix eq "";

	my @d = devspec2array("TYPE=SONOSPLAYER:FILTER=NAME=" . $prefix ."_[0-9a-zA-Z]+");
	foreach my $sd (@d)
	{
		Log3 undef, 4, "notify: deletereading ".$prefix."_[A-Za-z0-9] svHasClient_$sd";
		fhem("deletereading ".$prefix."_[A-Za-z0-9] svHasClient_$sd");
	}

	Log3 undef, 1, "notify: deletereading " . $prefix . "_[A-Za-z0-9] svPlaylists";
	fhem("deletereading " . $prefix . "_[A-Za-z0-9] svPlaylists 0");
	Log3 undef, 1, "notify: deletereading " . $prefix . "_[A-Za-z0-9] svTrackPosition";
	fhem("deletereading " . $prefix . "_[A-Za-z0-9] svTrackPosition 0");
	Log3 undef, 1, "notify: deletereading " . $prefix . "_[A-Za-z0-9] svIsInAnyGroup";
	fhem("deletereading " . $prefix . "_[A-Za-z0-9] svIsInAnyGroup 0");
	Log3 undef, 1, "notify: deletereading " . $prefix . "_[A-Za-z0-9] svIsInThisGroup";
	fhem("deletereading " . $prefix . "_[A-Za-z0-9] svIsInThisGroup");
}




##########################################################################################
#
# #######################   S O N O S   C O N V E R T E R   ##############################
#
##########################################################################################
package fronthem;
use strict;
use warnings;


###############################################################################
#
# Fronthem Converter for Sonos Widget
# direkt relations (gadval == reading == setval) with the following exeptions:
#
# - catch readings svHasClient.* / svIsInAnyGroup and do the job
#
###############################################################################
sub SonosGroup(@)
{
	my ($param) = @_;
	my $cmd = $param->{cmd};
	my $gad = $param->{gad};
	my $gadval = $param->{gadval};

	my $device = $param->{device};
	my $reading = $param->{reading};
	my $event = $param->{event};

	my @args = @{$param->{args}};
	my $cache = $param->{cache};

	# who am I ?
	my $cName = "fronthem converter (SonosGroup): ";

	if ($param->{cmd} eq 'get')
	{
		$event = ($reading eq 'state')?main::Value($device):main::ReadingsVal($device, $reading, '');
    	$param->{cmd} = 'send';
	}
	if ($param->{cmd} eq 'send')
	{
		$param->{gad} = $gad;
		$param->{gadval} = $event;
		$param->{gads} = [];
    	return undef;
	}
	elsif ($param->{cmd} eq 'rcv')
	{
		main::Log3 undef, 4, "Debug: " . $cName . "gad: " . $gad . " / device: " . $device . " / event: " . $event . " / reading: " . $reading;

		# catch reading svHasClient.*
		if ($reading =~ /svHasClient/)
		{
			$reading =~ s/svHasClient_//g;
			# if device is member of a group, do not allow to become master of other device
			if (main::ReadingsVal($device, "currentTitle", "Gruppenwiedergabe") ne "Gruppenwiedergabe" )
			{
				# Add player to group
				if ($gadval eq "1")
				{
					main::Log3 undef, 4, "Debug: " . $cName . "set $device AddMember $reading";
					$param->{result} = main::fhem("set $device AddMember $reading");
				}
				# Remove player from group
				elsif ($gadval eq "0")
				{
					main::Log3 undef, 4, "Debug: " . $cName . "set $device RemoveMember $reading";
					$param->{result} = main::fhem("set $device RemoveMember $reading");
				}
			}
			else
			{
				# notify sv (refresh button)
				main::Log3 undef, 4, "Debug: " . $cName . "setreading ".$device." svHasClient_".$reading." 0";
				main::fhem("setreading ".$device." svHasClient_".$reading." 0");
			}
			$param->{result} = $gadval;
			$param->{results} = [];
			# job is done, no further processing afterwards
			return 'done';
		}

		# catch reading svIsInAnyGroup
		if ($reading eq "svIsInAnyGroup")
		{
			# player is going to remove itself from group
			if ($gadval eq "0")
			{
				# eg set Sonos_Wohnzimmer (reading svIsInThisGroup) RemoveMember (command) Sonos_Studio (the device itself)
				main::Log3 undef, 4, "Debug: " . $cName . "set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device;
				$param->{result} = main::fhem("set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device);
			}
			# Trigger event for SV to get the correct status, again. (button was pushed in off state, set to off again)
			elsif ($gadval eq "1")
			{
				main::Log3 undef, 4, "Debug: " . $cName . "setreading " . $device . " " . $reading . " 0";
				$param->{result} = main::fhem("setreading " . $device . " " . $reading . " 0");
			}
			$param->{result} = $gadval;
			$param->{results} = [];
			# job is done, no further processing afterwards
	    	return 'done';
		}

		# other readings...
		main::Log3 undef, 1, $cName . "SonosGroup converter should only be used for reading svHasClient";
		main::Log3 undef, 1, $cName . "but was used for: set " . $device . " " . $reading . " " . $gadval;
		$param->{result} = $gadval;
		$param->{results} = [];
		return undef;
	}
	elsif ($param->{cmd} eq '?')
	{
		return 'usage: Direct';
  	}
	return undef;
}



###############################################################################
#
# Fronthem Converter for Sonos Widget
# direkt relations (gadval == reading == setval) with the following exeptions:
#
# - get play/stop status from transportState reading and set play/stop via state
#
###############################################################################
sub SonosTransportState(@)
{
	my ($param) = @_;
	my $cmd = $param->{cmd};
	my $gad = $param->{gad};
	my $gadval = $param->{gadval};

	my $device = $param->{device};
	my $reading = $param->{reading};
	my $event = $param->{event};

	my @args = @{$param->{args}};
	my $cache = $param->{cache};

	# who am I ?
	my $cName = "fronthem converter (SonosTransportState): ";

	if ($param->{cmd} eq 'get')
	{
    	$event = ($reading eq 'state')?main::Value($device):main::ReadingsVal($device, $reading, '');
    	$param->{cmd} = 'send';
	}
	if ($param->{cmd} eq 'send')
	{
		$param->{gad} = $gad;
		$param->{gadval} = $event;
		$param->{gads} = [];
		return undef;
	}
	elsif ($param->{cmd} eq 'rcv')
	{
		# set stop via state if reading transportState is STOPPED
		if (($reading eq "transportState") && ($gadval eq "STOPPED"))
		{
			$param->{result} = main::fhem("set $device Stop");
			$param->{results} = [];
    		{return 'done'}

		}
		# set start via state if reading transportState is PLAYING
		elsif (($reading eq "transportState") && ($gadval eq "PLAYING"))
		{
			$param->{result} = main::fhem("set $device Play");
			$param->{results} = [];
    		{return 'done'}
		}

	# other readings...
	main::Log3 undef, 1, $cName . "SonosTransportState converter should only be used for reading transportState";
	main::Log3 undef, 1, $cName . "but was used for: set " . $device . " " . $reading . " " . $gadval;
	$param->{result} = $gadval;
	$param->{results} = [];
	return undef
	}
	elsif ($param->{cmd} eq '?')
	{
	return 'usage: Sonos';
	}
	return undef;
}




###############################################################################
#
# Fronthem Converter for Sonos Widget
# direkt relations (gadval == reading == setval) with the following exeptions:
#
# - replace empty.jpg url (reading currentAlbumArtURL)
#
###############################################################################
sub SonosAlbumArtURL(@)
{
	my ($param) = @_;
	my $cmd = $param->{cmd};
	my $gad = $param->{gad};
	my $gadval = $param->{gadval};

	my $device = $param->{device};
	my $reading = $param->{reading};
	my $event = $param->{event};

	my @args = @{$param->{args}};
	my $cache = $param->{cache};

	# who am I ?
	my $cName = "fronthem converter (SonosAlbumArtURL): ";

	if ($param->{cmd} eq 'get')
	{
    	$event = ($reading eq 'state')?main::Value($device):main::ReadingsVal($device, $reading, '');
		$param->{cmd} = 'send';
	}
	if ($param->{cmd} eq 'send')
	{
    	$param->{gad} = $gad;
		# replace empty.jpg url (reading currentAlbumArtURL) and Sonos module bugfix
		if ($reading eq "currentAlbumArtURL")
		{
			# Sonos Modul seems to have a problem, when you remove master of a group by
			# Sonos controller then the remaining slave is not disconnected from the old
			# master if there is any. transportState = ERROR ans AlbumURL is empty.
			if (($event eq "") && (main::ReadingsVal($device, "transportState", $device) eq "ERROR"))
			{
				#main::Log3 undef, 3, $cName . "set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device;
				main::fhem("set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device);
			}

			# currentAudio is playing and no (radio)stream and no timmer is running (switched from normalAudio to streamAudio without changing transportState)
			my $atName1 = "at_" . $device . "_GetTrackPos";
			main::Log3 undef, 4, $cName . "Device: " . $device . " / TransportState: " . main::ReadingsVal($device, "transportState", "") . " / atDev (state/doNotExist): " . main::ReadingsVal($atName1, "state", "doNotExist") . " / currentNormalAudio: " . main::ReadingsVal($device, 'currentNormalAudio','');
			if ((main::ReadingsVal($device, 'currentNormalAudio','0') eq 1) && (main::ReadingsVal($atName1, "state", "doNotExist") eq "doNotExist") && (main::ReadingsVal($device, "transportState", "STOPPED") eq "PLAYING") )
			{
				main::Log3 undef, 4, $cName . "jep, define timer (img change and no timer running)";
				main::sv_defineAtTimer($device);
			}
			elsif ((main::ReadingsVal($device, "transportState", "STOPPED") ne "PLAYING") || (main::ReadingsVal($device, 'currentNormalAudio','0') eq 0))
			{
				main::Log3 undef, 4, $cName . "delete Timer";
				main::sv_deleteAtTimer($device);
			}
			################################

			# replace empty.jpg url
			$event =~ s/\/fhem\/sonos\/cover\/empty.jpg/\/smartvisu\/pages\/base\/pics\/sonos_empty.jpg/g;
		}

		$param->{gadval} = $event;
		$param->{gads} = [];
		return undef;
	}
	elsif ($param->{cmd} eq 'rcv')
	{
		# other readings...
		main::Log3 undef, 1, $cName . "SonosTransportState converter should only be used for reading currentAlbumArtURL";
		main::Log3 undef, 1, $cName . "but was used for: set " . $device . " " . $reading . " " . $gadval;
		$param->{results} = [];
   		return undef;
	}
	elsif ($param->{cmd} eq '?')
	{
    	return 'usage: Sonos';
	}
	return undef;
}




###############################################################################
#
# Fronthem Converter for Sonos Widget
# direkt relations (gadval == reading == setval) with the following exeptions:
#
# -
#
###############################################################################
sub SonosTrackPos(@)
{
	my ($param) = @_;
	my $cmd = $param->{cmd};
	my $gad = $param->{gad};
	my $gadval = $param->{gadval};

	my $device = $param->{device};
	my $reading = $param->{reading};
	my $event = $param->{event};

	my @args = @{$param->{args}};
	my $cache = $param->{cache};

	# who am I ?
	my $cName = "fronthem converter (SonosTransportState): ";

	if ($param->{cmd} eq 'get')
	{
		$event = ($reading eq 'state')?main::Value($device):main::ReadingsVal($device, $reading, '');
	   	$param->{cmd} = 'send';
	}
	if ($param->{cmd} eq 'send')
	{
		$param->{gad} = $gad;
		$param->{gadval} = $event;
		$param->{gads} = [];
		return undef;
	}
	elsif ($param->{cmd} eq 'rcv')
	{
		if ($reading eq "svTrackPosition")
		{
			my $durationT = main::ReadingsVal($device, 'currentTrackDuration', '0:00:10');
			my $durationS = main::SONOS_GetTimeSeconds($durationT);
			my $newposS = $gadval * $durationS / 100 ;
			my $newposT = main::sv_SonosSec2time($newposS);

			#main::Log3 undef, 3, $cName . "set ".$device." CurrentTrackPosition ".$newposT;
			main::fhem("set ".$device." CurrentTrackPosition ".$newposT);

			$param->{results} = [];
			return 'done';
		}

		# other readings...
		main::Log3 undef, 1, $cName . "SonosTrakPos converter should only be used for reading currentTrackPosition";
		main::Log3 undef, 1, $cName . "but was used for: set " . $device . " " . $reading . " " . $gadval;
		$param->{results} = [];
		return undef;
	}
	elsif ($param->{cmd} eq '?')
	{
    	return 'usage: Sonos';
	}
	return undef;
}




1;


=pod
=begin html

<a name="fronthemSonosUtils"></a>
<h3>fronthemSonosUtils</h3>
<ul>
  This is a collection of functions and fronthem converts that will be used by
  Sonos Widget for smartVISU.<br/>
  </br>
  <b>Defined converter</b><br/><br/>
  <ul>
    <li><b>SonosGroup</b><br>used for readings: svHasClient.* / svIsInAnyGroup
      </li><br/>
    <li><b>SonosTransportState</b><br>used for reading: transportState
      </li><br/>
    <li><b>SonosAlbumArtURL</b><br>used for reading: SonosAlbumArtURL
      </li><br/>
    <li><b>SonosTrackPos</b><br>used for reading: svTrackPosition
      </li><br/>
  </ul>
  </br>
  <b>Defined functions</b><br/><br/>
  <ul>
    <li><b>sv_setSonosGroupsReadings($NAME, $EVENT)</b><br>Used to set readings sv.*
      depending on Sonos group states. Will be called from notify with definition:<br/>
      Sonos_[A-Za-z0-9]+:currentTrackProvider:.\w.* { sv_setSonosGroupsReadings($NAME, $EVENT) }<br/>
      Prefix Sonos_ has to be replaced by your own if it differs.
      </li><br/>
    <li><b>sv_SonosGetTrackPos($NAME, $EVTPART1)</b><br>Used to define at devices to
      get ongoing currentTrackPosition. Will be called from notify with definition:<br/>
      Sonos_.*:transportState:.* { sv_SonosGetTrackPos($NAME,$EVTPART1) }<br/>
      Prefix Sonos_ has to be replaced by your own if it differs.
      </li><br/>
    <li><b>sv_calcTrackPosPercent($device, $lastActionResult)</b><br>Used to set
      userReading svTrackPosition within Sonos player devices:<br/>
      svTrackPosition:LastActionResult.*?GetCurrentTrackPosition.* { sv_calcTrackPosPercent($name, ReadingsVal($name, "LastActionResult", "")) }
      </li><br/>
    <li><b>sv_SonosReadingsInit()</b><br/>Used to init svReadings within all Sonos players
      if needed.
      </li><br/>
    <li><b>sv_SonosReadingsDelete()</b><br/>Used to delete all svReadings within all Sonos
      players if needed.
      </li><br/>
    <li><b>All other functions</b> are only used internally.
      </li><br/>
  </ul>
</ul>
=end html
=cut
