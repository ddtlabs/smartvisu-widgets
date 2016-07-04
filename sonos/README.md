### Sonos Widget for smartVISU / FHEM

**Version: 0.90**

**Screenshots:**

![](screenshots/sonos1.png)

![](screenshots/sonos2.png)

**Description:**
- SmartVISU widget to control Sonos(r) speakers with FHEM/Fronthem.

**Features:**
- Control groups, play/radio lists, track position, volume, mute, play, stop, skip, ...
- Popup with equalizer and volume slider for neighbour players

**Important update note:**
- If your are updating from version **0.85** or below, you have to replace a notify and delete a userReadings definition. See change log blow.
- If your are updating from version **0.86** or below, you have to adopt widget call. Radiolists and playlists are read from readings. See change log blow.

**Requirements:**
- Fully functioning FHEM (at least version 9118, 2015-08-23) with configured Sonos modules
- SmartVISU **2.8+** (https://github.com/Martin-Gleiss/smartvisu)
- Fronthem (https://github.com/herrmannj/fronthem)
- ~~FHEM Sonos player device names without umlauts or underscores in room name. A underscore between prefix and room name is needed on the other hand.~~
- ~~If you are affected then rename your player(s), please. Otherwise you can try to change regexs in notifies and subs in 99_fronthemSonosUtils.pm.~~

**Installation advices:**

**FHEM:**
- Copy 99_fronthemSonosUtils.pm to your FHEM module folder (typically /opt/fhem/FHEM).
- Check that file has the same permission as all other files in this directory.
- Restart FHEM.
- **UPDATED:** Define 2 FHEM notifies (replace "Sonos_" by your used prefix, if you named it differently):
```
define n_sv_sonosGroups notify Sonos_.*[^(_LR|_RR|_LF|_RF|_SW)]:currentTrackProvider:.\w.* { sv_setSonosGroupsReadings($NAME, $EVENT) }
define n_sv_sonosTransportState notify Sonos_.*[^(_LR|_RR|_LF|_RF|_SW)]:transportState:.* { sv_SonosTransportStateChanged($NAME,$EVTPART1) }
```
- Do not forget to save.

**smartVISU:**
- Copy widget_ddtlabs_sonos.* to your smartVISU pages folder.
- Copy content of *.css and *.js to your visu.css/visu.js or [include it](https://github.com/ddtlabs/smartvisu-widgets/wiki/HowTo-Install-Widgets).
- Copy sonos_empty.jpg to smartvisu_root/pages/base/pics (typically /var/www/smartvisu/pages/base/pics).
- Copy icons/.* to smartvisu ws icon folder (typically /var/www/smartvisu/icons/ws).
- Check that permissions of all copied files are correct.

**Icons:**
- Each Sonos player can build a group with its neighbours. Icons that are used for that purpose must be named in this way: my_audio_group_[playername].svg
- eg. one of your Sonos player is named "Sonos_Livingroom" then your icon for that room must be named "my_audio_group_Sonos_Livingroom.svg".
- You can use any smartVISU compatible svg icon. Some icons are included that display the first character of the room name. The character can simple be changed with a text editor of your choice (last line in svg). Position of this character can be adjusted in x/y lines above.
- Check that permissions of all copied/created files are correct.

**Widget declaration:**
```
/**
* Sonos(r) Multimedia Player
*
* @param id: unique id for this widget, no default, mandatory
* @param gad: gad name, no default, mandatory
* @param neighbors:	array of other Sonos neighbour speakers. eg: ['Sonos_Studio', 'Sonos_Wohnzimmer'], no default
* @author dev0
*/

{% macro player(id, gad, neighbors) %}
```

**Simple example widget call** for three separate players (eg. for rooms_*.html or category_*.html):
```
{% import "widget_ddtlabs_sonos.html" as ddtlabs_sonos %}

<div class="block" style="width: 100%;">
	<div class="set-1" data-role="collapsible-set" data-theme="c" data-content-theme="a" data-mini="true">
		<div data-role="collapsible" data-collapsed="false" >
		<h3>Sonos Studio <span class="sonos_header_presence">
			{{ ddtlabs_sonos.presence('sonos_studio', 'Sonos_Studio') }}
		</span></h3>
		<table width="100%">
			<tr><td>
        {{ ddtlabs_sonos.player('sonos_studio', 'Sonos_Studio', ['Sonos_Kitchen', 'Sonos_Wohnzimmer']) }}
			</td></tr>
		</table>
		</div>
	</div>
</div>


<div class="block" style="width: 100%;">
	<div class="set-1" data-role="collapsible-set" data-theme="c" data-content-theme="a" data-mini="true">
		<div data-role="collapsible" data-collapsed="false" >
		<h3>Sonos Wohnzimmer <span class="sonos_header_presence">
			{{ ddtlabs_sonos.presence('sonos_wohnzimmer', 'Sonos_Wohnzimmer') }}
		</span></h3>
		<table width="100%">
			<tr><td>
        {{ ddtlabs_sonos.player('sonos_wohnzimmer', 'Sonos_Wohnzimmer', ['Sonos_Kitchen', 'Sonos_Studio']) }}
			</td></tr>
		</table>
		</div>
	</div>
</div>


<div class="block" style="width: 100%;">
	<div class="set-1" data-role="collapsible-set" data-theme="c" data-content-theme="a" data-mini="true">
		<div data-role="collapsible" data-collapsed="false" >
		<h3>Sonos Kitchen <span class="sonos_header_presence">
			{{ ddtlabs_sonos.presence('sonos_kitchen', 'Sonos_Kitchen') }}
		</span></h3>
		<table width="100%">
			<tr><td>
        {{ ddtlabs_sonos.player('sonos_kitchen', 'Sonos_Kitchen', ['Sonos_Wohnzimmer', 'Sonos_Studio']) }}
			</td></tr>
		</table>
		</div>
	</div>
</div>

/** Note: radio stations must be added to Sonos "My Radiostations" to work with FHEM's Sonos Modules */
```

**Advanced example widget call** for three devices, but only 1 player is displayed. You can select your Sonos device from selectmenu:
```
{% import "status.html" as status %}
{{ status.collapse('mm_Sonos_Studio_visible',     'mm_Sonos_Studio.svIsVisible') }}
{{ status.collapse('mm_Sonos_Livingroom_visible', 'mm_Sonos_Livingroom.svIsVisible') }}
{{ status.collapse('mm_Sonos_Kitchen_visible',    'mm_Sonos_Kitchen.svIsVisible') }}

{% import "widget_ddtlabs_sonos.html" as ddtlabs_sonos %}
<div class="block" style="width: 100%; Xmin-width: 520px;">
  <div class="ui-bar-c ui-li-divider ui-corner-top" style="height: 16px;">
    <table border="0" class="sonos_player_table_selector">
    <tr>
      <td>
        <div class="sonos_header_presence_aio hide" data-bind="mm_Sonos_Studio_visible">     {{ ddtlabs_sonos.presence('id_sonos_studio_presence',     'Sonos_Studio') }}     </div>
        <div class="sonos_header_presence_aio hide" data-bind="mm_Sonos_Livingroom_visible"> {{ ddtlabs_sonos.presence('id_sonos_livingroom_presence', 'Sonos_Livingroom') }} </div>
        <div class="sonos_header_presence_aio hide" data-bind="mm_Sonos_Kitchen_visible">    {{ ddtlabs_sonos.presence('id_sonos_kitchen_presence',    'Sonos_Kitchen') }}      </div>
      </td>
      <td>
        <div class="sonos_player_selector">
        {{ ddtlabs_sonos.selectmenu_static('id_select_player', 'mm_Sonos_Livingroom.svIsVisibleName',  [['Sonos Livingroom','Sonos_Livingroom'],['Sonos Studio','Sonos_Studio'],['Sonos Kitchen','Sonos_Kitchen']], '', '')}}
        </div>
      </td>
    </tr>
    </table>
  </div>
  <div class="ui-fixed ui-body-a ui-corner-bottom">
    <table width="100%" height="280">
      <tr><td>
        <div class="hide" data-bind="mm_Sonos_Studio_visible">     {{ ddtlabs_sonos.player('sonos_studio',     'Sonos_Studio',     ['Sonos_Kitchen', 'Sonos_Livingroom']) }}  </div>
        <div class="hide" data-bind="mm_Sonos_Livingroom_visible"> {{ ddtlabs_sonos.player('sonos_livingroom', 'Sonos_Livingroom', ['Sonos_Kitchen', 'Sonos_Studio']) }}      </div>
        <div class="hide" data-bind="mm_Sonos_Kitchen_visible">    {{ ddtlabs_sonos.player('sonos_kitchen',    'Sonos_Kitchen',    ['Sonos_Livingroom', 'Sonos_Studio']) }} </div>
      </td></tr>
    </table>
  </div>
</div>
```

- Group / ungroup your players in all possible combinations with Sonos Controller while FHEM is running. Dynamic readings will be created.

**Fronthem converter usage:**
  - **SonosGroup:** used for all svHasClient_Sonos_.* and svIsInAnyGroup readings (these FHEM readings will automatically be created at first when Sonos speakers are grouped)
  - **SonosAlbumArtURL:** used for currentAlbumArtURL reading (inter alia fixing a FHEM Sonos module bug)
  - **SonosTrackPos:** used for svTrackPosition reading
  - **SonosTransportState:** used for transportState.* readings
  - **SonosLists:** used for Playlist and Radiolist readings
  - **NumDirect:** used for Volume reading
  - **Direct:** used for all other readings
  - Some readings may not be displayed in FHEM Gad Editor because they are not on Sonos modules internal setList. Enter them nevertheless.
  - Last part of gad/items names that are displayed in gad editor are the reading names that must be selected for each reading and cmd. I hope that makes this configuration a little bit easier.

| item                               | device    | reading               | converter           | cmd set               |
| ---------------------------------- | --------- | --------------------- | ------------------- | --------------------- |
| mm_Sonos_xyz.Balance               | Sonos_xyz | Balance               | Direct              | Balance               |
| mm_Sonos_xyz.Bass                  | Sonos_xyz | Bass                  | Direct              | Bass                  |
| mm_Sonos_xyz.CrossfadeMode         | Sonos_xyz | CrossfadeMode         | Direct              | CrossfadeMode         |
| mm_Sonos_xyz.Loudness              | Sonos_xyz | Loudness              | Direct              | Loudness              |
| mm_Sonos_xyz.Mute                  | Sonos_xyz | Mute                  | Direct              | Mute                  |
| mm_Sonos_xyz.Playlist              | Sonos_xyz | Playlists             | SonosLists          | Playlists             |
| mm_Sonos_xyz.Radiolist             | Sonos_xyz | Radios                | SonosLists          | Radios                |
| mm_Sonos_xyz.Repeat                | Sonos_xyz | Repeat                | Direct              | Repeat                |
| mm_Sonos_xyz.Shuffle               | Sonos_xyz | Shuffle               | Direct              | Shuffle               |
| mm_Sonos_xyz.Treble                | Sonos_xyz | Treble                | Direct              | Treble                |
| mm_Sonos_xyz.currentAlbum          | Sonos_xyz | currentAlbum          | Direct              |                       |
| mm_Sonos_xyz.currentAlbumArtURL    | Sonos_xyz | currentAlbumArtURL    | SonosAlbumArtURL    |                       |
| mm_Sonos_xyz.currentArtist         | Sonos_xyz | currentArtist         | Direct              |                       |
| mm_Sonos_xyz.currentSender         | Sonos_xyz | currentSender         | Direct              |                       |
| mm_Sonos_xyz.currentSenderCurrent  | Sonos_xyz | currentSenderCurrent  | Direct              |                       |
| mm_Sonos_xyz.currentSenderInfo     | Sonos_xyz | currentSenderInfo     | Direct              |                       |
| mm_Sonos_xyz.currentTitle          | Sonos_xyz | currentTitle          | Direct              |                       |
| mm_Sonos_xyz.currentTrackDuration  | Sonos_xyz | currentTrackDuration  | Direct              |                       |
| mm_Sonos_xyz.presence              | Sonos_xyz | presence              | Direct              |                       |
| mm_Sonos_xyz.roomName              | Sonos_xyz | roomName              | Direct              |                       |
| mm_Sonos_xyz.state                 | Sonos_xyz | state                 | Direct              | state                 |
| mm_Sonos_xyz.svHasClient_Sonos_xxx | Sonos_xyz | svHasClient_Sonos_xxx | SonosGroup          | svHasClient_Sonos_xxx |
| mm_Sonos_xyz.svHasClient_Sonos_yyy | Sonos_xyz | svHasClient_Sonos_yyy | SonosGroup          | svHasClient_Sonos_yyy |
| mm_Sonos_xyz.svIsInAnyGroup        | Sonos_xyz | svIsInAnyGroup        | SonosGroup          | svIsInAnyGroup        |
| mm_Sonos_xyz.svIsVisible           | Sonos_xyz | svIsVisible           | SonosRoomSelect     | svIsVisible           |
| mm_Sonos_xyz.svTrackPosition       | Sonos_xyz | svTrackPosition       | SonosTrackPos       | svTrackPosition       |
| mm_Sonos_xyz.svTransportStatePause | Sonos_xyz | svTransportStatePause | SonosTransportState | svTransportStatePause |
| mm_Sonos_xyz.svTransportStatePlay  | Sonos_xyz | svTransportStatePlay  | SonosTransportState | svTransportStatePlay  |
| mm_Sonos_xyz.svTransportStateStop  | Sonos_xyz | svTransportStateStop  | SonosTransportState | svTransportStateStop  |
| mm_Sonos_xyz.volume                | Sonos_xyz | Volume                | NumDirect           | Volume                |


**Used Sonos player readings:**
  - can be found in the beginning of sonos player macro in widget_ddtlabs_sonos.html
  - some additional readings are created dynamically based on Sonos neighbours within Sonos players.
    - eg. svHasClient_Sonos_Livingroom, svHasClient_Sonos_Kitchen, ...

**Debugging:**
- Enable at least verbose 4 and have a look at 99_fronthemSonosUtils.pm for disabled Log3 and main::Log3 lines and enable them. reload 99_fronthemSonosUtils

**Uninstall:**
- Remove additional userReading svTrackPosition from all Sonos players (if defined in earlier version).
- Delete both created notifies within FHEM.
- Call within FHEM {sv_SonosReadingsDelete()} to delete all addional created readings within Sonos players.
- Delete all copied files.
- Say quite and sad: bye bye ;-)

**Note** on using "ddtlabs" in file names and css statements:
- I decided to use a unique prefix name to be sure to not collide with other widgets.

**ToDo:**
- Remove continously currentTrackPosition update and replace it with a timerEvent() js function. **Voluntaries up, please!**
- ~~Popup with sliders for treble, bass, balance and other settings.~~
- ~~Get radio and play lists from FHEM readings.~~
- ~~Dynamic layout in width.~~

**Update notes:**
- If 99_fronthemSonosUtils.pm was replaced, then restart FHEM. "Reload 99_fronthemSonosUtils" could no be enough in some cases!
- See change log for instructions.

**Change log:**
- **1st bugfix**
- An at device was created for players that are group slaves at FHEM restart (fixed)
- FHEM requirements: min. version 9118
- Changed ongoing trackPosition update to 10sec (former 4sec)
- Immediately trackPosition update if cover image changes (new track started)
- **v0.78**
- A more dynamic layout in width.
- Added a popup with equalizer and volumes for neighbour players
- **v0.79**
- New gad-items / readings: svTransportStatePause, svTransportStatePlay, svTransportStateStop (converter: SonosTransportState)
- Current widget version can be found in popup window, too.
- UserReading definition for svTrackPosition is no longer needed. **Delete it you are updating from v0.78 or below, please.**
- Popup IDs were not set correctly: same popup was shown for all players (fixed)
- Minor layout changes
- **v0.80**
- Code cleanup
- **v.081**
- Slave player can control master (play,pause,stop,next,prev,trackPos)
- If player is a slave then cover art and track position will be shown from master player
- **v.082**
- SET Track Position will be redirected from slave player to master
- **v0.83**
- missed to set log level back to 4 (fixed)
- replaced multistate button by dual
- **v0.84**
- Minor changes
- **v0.85**
- Device name recognition revised, no more device name restriction!
  - **You have to adopt both notify calls**
  - See definition above.
- Master states are synced to slave players (improvement)
- **v0.86**
- Added a little bit more delay to volume sliders
- **v0.90**
- Playlists and radio stations are captured from FHEM reading and must not be be specified in widget call. You have to remove them from widget call and you must configure them in GAD Editor. Thanx to raman for that feature.
- You can define a all-in-one device for multiple players. See advanced example above.
- Show presence state at top of device
- Minor changes and code cleanup
- Advanced example for Widget call
- New presence symbol

**Credits / Copyrights / Trademarks:**
- My wife!
- My wife!
- My wife!
- SONOS is a registered trademark of Sonos, Inc. SONOS Reg. U.S. Pat. & Tm. Off.
- FHEM: (c) Rudolf Koenig (http://www.fhem.de/fhem.html)
- Fronthem: (c) herrmannj (https://github.com/herrmannj/fronthem)
- FHEM Sonos modules: (c) Reiner Leins
- smartVISU: (c) Martin Gleiß (http://docu.smartvisu.de/2.7/index.php?page=copyright)
- Some group icons are based on icons that are published by creative commons license:
  - Credit goes to: Marek Polakovic from the Noun Project

**Have fun.**





















