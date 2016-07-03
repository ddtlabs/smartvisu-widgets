# ########################################################################################
# $Id: 99_fronthemSonosUtils.pm 86 2015-08-28 13:33:00Z dev0 $
# Verison 0.86
# ########################################################################################
#
#  This functions are free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
# ########################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# # # # # # #   S O N O S   /   S M A R T V I S U   F U N C T I O N S   # # # # # # # # #
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


package main;
use strict;
use warnings;
use POSIX;

sub fronthemSonosUtils_Initialize($$)
{
  my ($hash) = @_;
  Log3 undef, 3, "99_fronthemSonosUtils.pm v0.90 (re)loaded";

}


# ########################################################################################
# sv_SonosTransportStateChanged()
#
# example call:
# define <notifyName> notify <yourPrefix>_.*:transportState:.* { sv_SonosTransportStateChanged($NAME,$EVTPART1) }
# eg. define n_sv_sonosGetTrackPos notify Sonos_.*:transportState:.* { sv_SonosTransportStateChanged($NAME,$EVTPART1) }
# ########################################################################################

sub sv_SonosTransportStateChanged($$) {
  my ($NAME,$EVTPART1) = @_;
  sv_SonosSetTansportState($NAME,$EVTPART1);
  sv_SonosGetTrackPos($NAME,$EVTPART1);
}


# ########################################################################################
# sv_SonosGetTansportState()
#
# example call:
# define n_sv_sonosGetTrackPos notify [yourPrefix]_.*:transportState:.* { sv_SonosGetTrackPos($NAME,$EVTPART1) }
# eg. define n_sv_sonosGetTrackPos notify Sonos_.*:transportState:.* { sv_SonosGetTrackPos($NAME,$EVTPART1) }
# ########################################################################################

sub sv_SonosSetTansportState($$) {
  my ($device,$event) = @_;

  $event =~ s/://g;

  my @d = sv_SonosGetSlaves($device);  # get all device slaves
  push(@d, $device);          # add device itself to array

  foreach my $dev (@d)
  {
    Log3 undef, 4, "sv_SonosSetTansportState($dev,$event) => Play 1 / Pause 0 / Stop: 0";
    if (($event eq "Play") || ($event eq "PLAYING"))
    {
      fhem("sleep 0.01; setreading " . $dev . " svTransportStatePlay 1" );
      fhem("sleep 0.01; setreading " . $dev . " svTransportStatePause 0" );
      fhem("sleep 0.01; setreading " . $dev . " svTransportStateStop 0" );
    }
    elsif (($event eq "Pause") || ($event eq "PAUSED_PLAYBACK"))
    {
      Log3 undef, 4, "sv_SonosSetTansportState($dev,$event) => Play 0 / Pause 1 / Stop 0";
      fhem("sleep 0.01; setreading " . $dev . " svTransportStatePlay 0" );
      fhem("sleep 0.01; setreading " . $dev . " svTransportStatePause 1" );
      fhem("sleep 0.01; setreading " . $dev . " svTransportStateStop 0" );
    }
    elsif (($event eq "Stop") || ($event eq "STOPPED") || ($event eq "ERROR"))
    {
      Log3 undef, 4, "sv_SonosSetTansportState($dev,$event) => Play 0 / Pause 0 / Stop 1";
      sv_SonosTrackPositionUpdate($dev);
      fhem("sleep 0.01; setreading " . $dev . " svTransportStatePlay 0" );
      fhem("sleep 0.01; setreading " . $dev . " svTransportStatePause 0" );
      fhem("sleep 0.01; setreading " . $dev . " svTransportStateStop 1" );
    }
      else
    {
      Log3 undef, 1, "sv_SonosGetTansportState($device,$event) => unknown state";
    }
  }
  return undef;
}



# ########################################################################################
# sv_setSonosGroupsReadings()
#
# example call:
# define n_sv_sonosTransportState notify Sonos_[A-Za-z0-9]+:transportState:.(STOPPED|PLAYING|PAUSED_PLAYBACK|ERROR).* { sv_SonosSetTansportState($NAME, $EVTPART1) }
# eg. define n_sv_sonosTransportState notify Sonos_[A-Za-z0-9]+:transportState:.(STOPPED|PLAYING|PAUSED_PLAYBACK|ERROR).* { sv_SonosSetTansportState($NAME, $EVTPART1) }
#
# Note:
# If your SONOSPLAYER devices contain more than 1 underscore or umlauts then you have to
# adjust both regexs [-0-9a-zA-Z]+ below.
# ########################################################################################

sub sv_setSonosGroupsReadings($$) {
  my ($device,$EVENT) = @_;

  Log3 undef, 4, "device: $device / EVENT: " . $EVENT;

  my @evt = split(" ",$EVENT);
  my ($evtName, $trigger, $room) = @evt;

  if ($trigger eq "Gruppenwiedergabe:")
  {
    my $master = sv_SonosGetDeviceFromRoom($room);
    fhem("sleep 0.01; setreading $device svIsInThisGroup $master");
    Log3 undef, 4, "sleep 0.01; setreading $device svIsInThisGroup $master";
    fhem("sleep 0.01; setreading $device svIsInAnyGroup 1");
    fhem("sleep 0.01; setreading $master svHasClient_"."$device"." 1");

    # overwrite currentAlbumArtURL when player has become a slave
    my $masterCoverUrl = ReadingsVal($master, "currentAlbumArtURL", "");
    fhem("sleep 0.01; setreading $device currentAlbumArtURL $masterCoverUrl");

    # sync transportState to slave, sonos module shows always PLAYING if player is a slave.
    # Ask Reinerlein if this is a bug?
    fhem("sleep 0.1; setreading $device svTransportStatePlay "   . ReadingsVal($master, "svTransportStatePlay", ""));
    fhem("sleep 0.1; setreading $device svTransportStatePlause " . ReadingsVal($master, "svTransportStatePause", ""));
    fhem("sleep 0.1; setreading $device svTransportStateStop "   . ReadingsVal($master, "svTransportStateStop", ""));
    # TrackPos sync to salve
    #fhem("sleep 0.1; setreading $device svTrackPosition "        . ReadingsVal($master, "svTrackPosition", ""));

  }
  else
  {
    fhem("sleep 0.01; setreading $device svIsInThisGroup none");
    fhem("sleep 0.01; setreading $device svIsInAnyGroup 0");
    my @devs = sv_SonosGetDevices();
    foreach my $dev (@devs)
    {
      fhem("sleep 0.01; setreading $dev svHasClient_"."$device"." 0");
    }
  }
}



# ########################################################################################
# sv_SonosGetTrackPos()
#
# example call:
# define n_sv_sonosGetTrackPos notify [yourPrefix]_.*:transportState:.* { sv_SonosGetTrackPos($NAME,$EVTPART1) }
# eg. define n_sv_sonosGetTrackPos notify Sonos_.*:transportState:.* { sv_SonosGetTrackPos($NAME,$EVTPART1) }
# ########################################################################################

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
  my $atSec = "05";

  if (ReadingsVal($atName, "state", "doNotExist") eq "doNotExist")
  {
    Log3 undef, 4, "sv_defineAtTimer: defmod ".$atName." at +*00:00:" . $atSec . " {sv_SonosTrackPositionUpdate(\"$device\")}";
    fhem("sleep 0.01; {sv_SonosTrackPositionUpdate(\"$device\")}");
    fhem("defmod -temporary ".$atName." at +*00:00:" . $atSec . " {sv_SonosTrackPositionUpdate(\"$device\")}");
    fhem("attr ".$atName." room ".$room);
  }
  return undef;
}

sub sv_deleteAtTimer($) {
  my ($device) = @_;
  my $atName = "at_" . $device . "_GetTrackPos";

  if (ReadingsVal($atName, "state", "doNotExist") ne "doNotExist")
  {
    Log3 undef, 4, "sv_deleteAtTimer($device): " . "delete $atName";
    fhem("delete $atName");
  }
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# # # # # # # # # # # #    H E L P E R   F U N C T I O N S   # # # # # # # # # # # # # # #
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# ####################################################################
# sv_calcTrackPosPercent()      ($LastActionResult = eg. GetCurrentTrackPosition: 0:00:11)
# ####################################################################

sub sv_SonosTrackPositionUpdate($) {
  my ($device) = @_;
  fhem("get $device CurrentTrackPosition");

  my $trackPosP;
  my $trackDurT = ReadingsVal($device, 'currentTrackDuration', '0:01:00');

  if (($trackDurT eq "0:00:00") || ($trackDurT eq "NOT_IMPLEMENTED") || ($trackDurT eq "")) # last is a test
  {
    $trackPosP = 0;
  }
  else
  {
    my $trackDurS = SONOS_GetTimeSeconds($trackDurT);
    my $trackPosT = ReadingsVal($device, "currentTrackPosition", "0:00:10");
    my $trackPosS = SONOS_GetTimeSeconds($trackPosT);

    # update is too late, we are one step beyond...
    $trackPosP = int(100 * $trackPosS / (0.1 + $trackDurS));
    if ($trackPosP >= 100) {$trackPosP = 100}  # $trackDurS = 0
  }

  Log3 undef, 4, "sv_SonosTrackPositioUpdate($device): setreading $device svTrackPosition $trackPosP";
  my @c = sv_SonosGetSlaves($device);  # include slaves
  push(@c, $device);           # include device itself
  foreach my $client (@c) {
    Log3 undef, 4, "sv_SonosTrackPositioUpdate($device): setreading $client svTrackPosition $trackPosP";
    fhem("sleep 0.01; setreading $client svTrackPosition $trackPosP");
  }

  return undef;
}


# ####################################################################
# sv_SonosGetPrefix()
#
# get sonos prefix name
# ####################################################################

sub sv_SonosGetPrefix() {
  my @p = devspec2array('TYPE=SONOS');
  my $prefix = shift @p;
  return "No SONOS device" if ($prefix eq "");
  return $prefix;
}


# ####################################################################
# sv_SonosGetDevices()
#
# get all sonos devices (stereo pairs will be handled as one device)
# ####################################################################

sub sv_SonosGetDevices() {
  my @devs = devspec2array("TYPE=SONOSPLAYER:FILTER=NAME!=.*(_LR|_RR|_LF|_RF|_SW|_LF_RF)");
  return @devs;
}


# ####################################################################
# sv_SonosGetDevicesFromRoom()
#
# get device name from room (used for $EVENT: "Gruppenwiedergabe: Livingroom")
# ####################################################################

sub sv_SonosGetDeviceFromRoom($) {
  my ($room) = @_;

  my @devs = devspec2array("TYPE=SONOSPLAYER:FILTER=NAME!=.*(_LR|_RR|_LF|_RF|_SW|_LF_RF)");
  foreach my $dev (@devs)
  {
    return $dev if ($dev =~/$room/);
  }
}


# ####################################################################
# sv_SonosGetSlaves($)
#
# get player's slaves if any
# ####################################################################

sub sv_SonosGetSlaves($) {
  my ($master) = @_;

  my @slaves;
  my @d = sv_SonosGetDevices();
  foreach my $device (@d)
  {
    if (ReadingsVal($master, "svHasClient_" . $device, "0") eq "1")
    {
      push(@slaves, $device);
    }
  }
  return @slaves;
}


# ####################################################################
# sv_SonosGetMaster($)
#
# get player's master if any
# ####################################################################

sub sv_SonosGetMaster($) {
  my ($device) = @_;

  my $master = ReadingsVal($device, "svIsInThisGroup", "none");
  return $master if $master ne "none";
  return $device;
}

# ####################################################################
# sv_SonosSec2time(secs)
# - convert seconds to fhem time format
# - will be used in fronthem converter SonosTrackPos
# ####################################################################

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



# ####################################################################
# Init all sv.* readings used by smartvisu Widget
# ####################################################################

sub sv_SonosReadingsInit() {

  my @d = sv_SonosGetDevices();

  foreach my $device (@d)
  {
    foreach my $devName (@d)
    {
      Log3 undef, 1, "notify: setreading $device svHasClient_$devName 0";
      fhem("setreading $device svHasClient_$devName 0");
    }
    Log3 undef, 1, "notify: setreading $device svPlaylists none";
    fhem("setreading $device svPlaylists 0");
    Log3 undef, 1, "notify: setreading $device svTrackPosition 0";
    fhem("setreading $device svTrackPosition 0");
    Log3 undef, 1, "notify: setreading $device svIsInAnyGroup 0";
    fhem("setreading $device svIsInAnyGroup 0");
    Log3 undef, 1, "notify: setreading $device svIsInThisGroup none";
    fhem("setreading $device svIsInThisGroup none");
    Log3 undef, 1, "notify: setreading $device svTransportStatePause 0";
    fhem("setreading $device svTransportStatePause none");
    Log3 undef, 1, "notify: setreading $device svTransportStatePlay 0";
    fhem("setreading $device svTransportStatePlay none");
    Log3 undef, 1, "notify: setreading $device svTransportStateStop 0";
    fhem("setreading $device svTransportStateStop none");
  }
}


# ####################################################################
# Delete all sv.* readings used by smartvisu Widget
# ####################################################################

sub sv_SonosReadingsDelete() {
  my @d = sv_SonosGetDevices();

  foreach my $device (@d)
  {
    foreach my $devName (@d)
    {
      Log3 undef, 1, "notify: deletereading $device svHasClient_$devName";
      fhem("deletereading $device svHasClient_$devName");
    }
    Log3 undef, 1, "notify: deletereading $device svPlaylists";
    fhem("deletereading $device svPlaylists 0");
    Log3 undef, 1, "notify: deletereading $device svTrackPosition";
    fhem("deletereading $device svTrackPosition 0");
    Log3 undef, 1, "notify: deletereading $device svIsInAnyGroup";
    fhem("deletereading $device svIsInAnyGroup 0");
    Log3 undef, 1, "notify: deletereading $device svIsInThisGroup";
    fhem("deletereading $device svIsInThisGroup");
    Log3 undef, 1, "notify: deletereading $device svTransportStatePause";
    fhem("deletereading $device svTransportStatePause");
    Log3 undef, 1, "notify: deletereading $device svTransportStatePlay";
    fhem("deletereading $device svTransportStatePlay");
    Log3 undef, 1, "notify: deletereading $device svTransportStateStop";
    fhem("deletereading $device svTransportStateStop");
    Log3 undef, 1, "notify: deletereading $device svIsVisible";
    fhem("deletereading $device svIsVisible");
  }
}




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# # # # # # #   S O N O S   C O N V E R T E R   # # # # # # # # # # # # # # # # # # # # #
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package fronthem;
use strict;
use warnings;


# ########################################################################################
# Fronthem converter: SonosGroup
# - catch readings svHasClient.* / svIsInAnyGroup and do the job
# ########################################################################################

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
    main::Log3 undef, 4, $cName . "gad: " . $gad . " / device: " . $device . " / reading: " . $reading;

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
          main::Log3 undef, 4, $cName . "set $device AddMember $reading";
          $param->{result} = main::fhem("set $device AddMember $reading");
        }
        # Remove player from group
        elsif ($gadval eq "0")
        {
          main::Log3 undef, 4, $cName . "set $device RemoveMember $reading";
          $param->{result} = main::fhem("set $device RemoveMember $reading");
        }
      }
      else
      {
        # notify sv (refresh button)
        main::Log3 undef, 4, $cName . "setreading ".$device." svHasClient_".$reading." 0";
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
        main::Log3 undef, 4, $cName . "set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device;
        $param->{result} = main::fhem("set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device);
      }
      # Trigger event for SV to get the correct status, again. (button was pushed in off state, set to off again)
      elsif ($gadval eq "1")
      {
        main::Log3 undef, 4, $cName . "setreading " . $device . " " . $reading . " 0";
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



# ########################################################################################
# Fronthem converter: SonosTransportState
# - get play/stop status from transportState reading and set play/stop via state
# ########################################################################################

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
    if ($reading eq "svTransportState")
    {
      $param->{result} = main::fhem("set $device $gadval");
      $param->{results} = [];
      return 'done';
    }
    if ($reading eq "svTransportStateStop")
    {
      if ($gadval eq "1")
      {
        main::fhem("setreading $device svTransportStatePlay 0");  # immediately update, not needed but better haptic
        main::fhem("setreading $device svTransportStateStop 1");    # trackPos @ timer deletion
        $param->{result} = main::fhem("set $device Stop");
        $param->{results} = [];
        return 'done';
      }
      elsif ($gadval eq "0")
      {
        $param->{result} = main::fhem("setreading $device svTransportStateStop 1");
        $param->{results} = [];
        return 'done';
      }
    }
    if ($reading eq "svTransportStatePlay")
    {
      if ($gadval eq "1")
      {
        main::fhem("setreading $device svTransportStateStop 0");    # immediately update, not needed but better haptic
        $param->{result} = main::fhem("set $device Play");
        $param->{results} = [];
        return 'done';
      }
      elsif ($gadval eq "0")
      {
        $param->{result} = main::fhem("set $device Pause");;
        $param->{results} = [];
        return 'done';
      }
    }
    if ($reading eq "svTransportStatePause")
    {
      if ($gadval eq "1")
      {
        if (main::ReadingsVal($device, "svTransportStatePlay","") eq "1")
        {
          $param->{result} = main::fhem("set $device Pause");
        }
        else
        {
          $param->{result} = main::fhem("setreading $device svTransportStatePause 0"); # if button was pushed in stop mode
        }
        $param->{results} = [];
        return 'done';
      }

      if ($gadval eq "0")
      {
        $param->{result} = main::fhem("set $device Play");;
        $param->{results} = [];
        return 'done';
      }
    }
    # other readings...
    main::Log3 undef, 1, $cName . "SonosTransportState converter should only be used for reading transportState / svTransportState.* with gadval=0/1";
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




# ########################################################################################
# Fronthem converter: SonosAlbumArtURL
# - replace empty.jpg url (reading currentAlbumArtURL)
# ########################################################################################

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
        main::Log3 undef, 4, $cName . "set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device;
        main::fhem("set " . main::ReadingsVal($device, "svIsInThisGroup", $device) . " RemoveMember " . $device);
      }

      # currentAudio is playing and no (radio)stream and no timmer is running (switched from normalAudio to streamAudio without changing transportState)
      my $atName1 = "at_" . $device . "_GetTrackPos";
      main::Log3 undef, 4, $cName . "Device: " . $device . " / TransportState: " . main::ReadingsVal($device, "transportState", "") . " / atDev (state/doNotExist): " . main::ReadingsVal($atName1, "state", "doNotExist") . " / currentNormalAudio: " . main::ReadingsVal($device, 'currentNormalAudio','');
      if ((main::ReadingsVal($device, 'currentNormalAudio','0') eq 1) && (main::ReadingsVal($atName1, "state", "doNotExist") eq "doNotExist") && (main::ReadingsVal($device, "transportState", "STOPPED") eq "PLAYING")  && (main::ReadingsVal($device, 'currentTrackProvider','') !~ /Gruppenwiedergabe/) )
      {
        main::Log3 undef, 4, $cName . "get trackPos update and define timer (img change and no timer running)";
        main::sv_SonosTrackPositionUpdate($device);
        main::sv_defineAtTimer($device);
      }
      elsif ((main::ReadingsVal($device, "transportState", "STOPPED") ne "PLAYING") || (main::ReadingsVal($device, 'currentNormalAudio','0') eq 0))
      {
        main::Log3 undef, 4, $cName . "delete Timer";
        main::sv_deleteAtTimer($device);
      }

      # If currentAlbumArtURL =~ /empty.jpg/
      if ($event =~ /\/fhem\/sonos\/cover\/empty.jpg/)
      {
        $event = "/smartvisu/pages/base/pics/sonos_empty.jpg";
        main::sv_SonosTrackPositionUpdate($device);  #better haptic
        main::Log3 undef, 4, "empty  currentAlbumArtURL replaced device: $device - event: ".  $event;
      }
      # overwrite slave player's currentAlbumArtURL
      else
      {
        my @c = main::sv_SonosGetSlaves($device);
        foreach my $client (@c)
        {
          main::fhem("setreading $client currentAlbumArtURL ".  $event);
          main::Log3 undef, 4, "setreading $client currentAlbumArtURL ".  $event;
        }
      }
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




# ########################################################################################
# Fronthem converter: SonosTrackPos
# - set trackPosition in %
# ########################################################################################

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

      #if position was set by a slave
      my $device = main::sv_SonosGetMaster($device);

      #calc percent
      my $durationT = main::ReadingsVal($device, 'currentTrackDuration', '0:00:10');
      my $durationS = main::SONOS_GetTimeSeconds($durationT);
      my $newposS = $gadval * $durationS / 100 ;
      my $newposT = main::sv_SonosSec2time($newposS);

      main::Log3 undef, 4, $cName . "set ".$device." CurrentTrackPosition ".$newposT;
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


sub SonosRoomSelect(@)
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
  my $cName = "fronthem converter (SonosRoomSelect): ";

  if ($param->{cmd} eq 'get')
  {
      $event = ($reading eq 'state')?main::Value($device):main::ReadingsVal($device, $reading, '');
      $param->{cmd} = 'send';
  }
  if ($param->{cmd} eq 'send') # fhem events -> sv
  {
    $param->{gad} = $gad;
    $param->{gadval} = $event;
    $param->{gads} = [];
    return undef;
  }
  elsif ($param->{cmd} eq 'rcv') # sv evetns -> fhem
  {
    if ($reading eq "svIsVisibleName") {
      # set all other devices svIsVisible flag to 0
      # use multiple foreach to use the right order for best haptic (switching visibility)
      my @sdevs = main::sv_SonosGetDevices();

      # set all player's svIsVisibleName to $gadval
      foreach my $sdev (@sdevs) {
        main::fhem("setreading $sdev svIsVisibleName $gadval");
        main::Log3 undef, 4, "setreading $sdev svIsVisibleName $gadval";
      }  

      foreach my $sdev (@sdevs) {
        if (not $sdev =~ /$gadval/) {
          main::fhem("setreading $sdev svIsVisible 0");
          main::Log3 undef, 4, "setreading $sdev svIsVisible 0";
        }
      }  

      foreach my $sdev (@sdevs) {
        if ($sdev =~ /$gadval/) {
          main::fhem("setreading $sdev svIsVisible 1");
          main::Log3 undef, 4, "setreading $sdev svIsVisible 1";
        }
      }  

      $param->{result} = [];
      $param->{results} = [];
      return 'done';
    }

    # other readings...
    main::Log3 undef, 1, $cName . "SonosTransportState converter should only be used for reading svIsVisible with gadval=0/1";
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


sub SonosLists(@)
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

  my $cName = "fronthem converter (SonosLists): ";

  if ($param->{cmd} eq 'get')
  {
    $event = main::ReadingsVal($device, $reading, '');
     $param->{cmd} = 'send';
  }
  if ($param->{cmd} eq 'send')
  {
    my @playlist;
    my %evt = %{eval( $event )};
    foreach (keys %evt) { push(@playlist, $evt{$_}{"Title"}) }
    $param->{gadval} = join(";;",sort @playlist);
    main::Log3 undef, 4, $cName . "device: $device, reading: $reading, gadval: $param->{gadval}";

    $param->{gad} = $gad;
    $param->{gads} = [];
    return undef;
  }
  elsif ($param->{cmd} eq 'rcv')
  {
    if ($reading eq "Playlists")
    {
      $gadval =~ s/ /%20/g;
      main::Log3 undef, 4, $cName . "set $device StartPlaylist $gadval";
      main::fhem("set $device StartPlaylist $gadval");
      $param->{results} = [];
      return 'done';
    }
    elsif ($reading eq "Radios")
    {
      $gadval =~ s/ /%20/g;
      main::Log3 undef, 4, $cName . "set $device StartRadio $gadval";
      main::fhem("set $device StartRadio $gadval");
      $param->{results} = [];
      return 'done';
    }
    else {
      # other readings...
      main::Log3 undef, 1, $cName . "SonosLists converter should only be used for reading Radios/Playlists ";
      main::Log3 undef, 1, $cName . "but was used for: set " . $device . " " . $reading . " " . $gadval;
      $param->{results} = [];
      return undef;
    }
  }
  elsif ($param->{cmd} eq '?')
  {
    return 'usage: Sonos';
  }
  return undef;
}





1;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# # # # # # # # # # #    C O M M A N D   R E F E R E N C E   # # # # # # # # # # # # # #
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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
      Sonos_.*[^(_LR|_RR|_LF|_RF|_SW)]:currentTrackProvider:.\w.* { sv_setSonosGroupsReadings($NAME, $EVENT) }<br/>
      Prefix Sonos_ has to be replaced by your own if it differs.
      </li><br/>
    <li><b>sv_SonosTransportStateChanged($NAME, $EVTPART1)</b><br>Used to define at
      devices to get ongoing currentTrackPosition and set trackPosition readings. Will be
      called from notify with definition:<br/>
      Sonos_.*[^(_LR|_RR|_LF|_RF|_SW)]:transportState:.* { sv_SonosTransportStateChanged($NAME,$EVTPART1) }<br/>
      Prefix Sonos_ has to be replaced by your own if it differs.
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
