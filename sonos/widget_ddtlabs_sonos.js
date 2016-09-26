/* -----------------------------------------------------------------------------
* Functions for smartVISU Sonos(c) Widget
* Version 0.91
* --------------------------------------------------------------------------- */

/* -----------------------------------------------
ddtlabs_sonos.cover
----------------------------------------------- */
$(document).delegate('[data-widget="ddtlabs_sonos.cover"]',{update:function(d, a){$(this).attr('src', a);}});


/* -----------------------------------------------
ddtlabs_sonos.selectmenu_statsic
----------------------------------------------- */

$(document).delegate('select[data-widget="ddtlabs_sonos.selectmenu_static"]', {
  'update': function (event, response) {
    $(this).val(response[0]).selectmenu('refresh');
  },
  'change': function (event) {
    io.write($(this).attr('data-item'), $(this).val());
  }
});


/* ------------------------------------------------------
ddtlabs_sonos.selectmenu with dynamic selects fron FHEM readings
Special thanx to raman (https://forum.fhem.de/index.php/topic,54768.0.html)
------------------------------------------------------ */

$(document).delegate('select[data-widget="ddtlabs_sonos.selectmenu"]', {
  'update': function (event, response) {
    if ($(this).val() == undefined) {
      $(this).find('option').remove().end();
      var newOption = "<option value='" + $(this).attr('data-label') + "'>" + $(this).attr('data-label') + "</option>";
      $(this).append(newOption).selectmenu('refresh');
      //var playlists = response[0].split(';;');
      var playlists = response[0].toString().explode(';;');
      playlists.sort();
      for (var i = 0; i < playlists.length; i++) {
        var newOption = "<option value='" + playlists[i] + "'>" + playlists[i] + "</option>";
        $(this).append(newOption).selectmenu('refresh');
      }
    }
  },
  'change': function (event) {
    io.write($(this).attr('data-item'), $(this).val());
    $(this).val($(this).attr('data-label')).selectmenu('refresh',true);
  }
});


/* -----------------------------------------------
slider with delay of 800ms
----------------------------------------------- */

$(document).delegate('input[data-widget="ddtlabs_int_sonos.slider"]', {
  'update': function (event, response) {
    // DEBUG: console.log("[basic.slider] update '" + this.id + "': " + response + " timer: " + $(this).attr('timer') + " lock: " + $(this).attr('lock'));
    $(this).attr('lock', 1);
    $('#' + this.id).val(response).slider('refresh').attr('mem', $(this).val());
  },

  'slidestop': function (event) {
    if ($(this).val() != $(this).attr('mem')) {
      io.write($(this).attr('data-item'), $(this).val());
    }
  },

  'change': function (event) {
    // DEBUG: console.log("[basic.slider] change '" + this.id + "': " + $(this).val() + " timer: " + $(this).attr('timer') + " lock: " + $(this).attr('lock'));
    if (( $(this).attr('timer') === undefined || $(this).attr('timer') == 0 && $(this).attr('lock') == 0 )
      && ($(this).val() != $(this).attr('mem'))) {

      if ($(this).attr('timer') !== undefined) {
        $(this).trigger('click');
      }

      $(this).attr('timer', 1);
      setTimeout("$('#" + this.id + "').attr('timer', 0);", 2000);
    }

    $(this).attr('lock', 0);
  },

  'click': function (event) {
    // $('#' + this.id).attr('mem', $(this).val());
    io.write($(this).attr('data-item'), $(this).val());
  }
});


/* -----------------------------------------------
test delayed functions
----------------------------------------------- */

// this function sets the value to the web instantly and starts a timer to send the value delayed to the server
// taken from HmTc Widget by verbadsoldier

function volume_setDelayed(uid, item, val) {
    widget.update(item, val);

    obj = $('#' + uid);

    // check if there is still a timer
    if (obj.prop("setDelayTimer") != undefined ){
        clearTimeout(obj.prop("setDelayTimer"));
        obj.removeProp("setDelayTimer");
    }

    // set timer to send the value delayed
    obj.prop("setDelayTimer", setTimeout(function(){
                                           io.write(item, val);
                                           $('#' + uid).removeProp("setDelayTimer");
                                         }, 3000));

}

