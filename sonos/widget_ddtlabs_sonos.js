/*
-----------------------------------------------
Sonos Cover
-----------------------------------------------
 */

$(document).delegate('[data-widget="ddtlabs_sonos.cover"]',{update:function(d, a){$(this).attr('src', a);}});



/*
-----------------------------------------------
Sonos Select
-----------------------------------------------
 */

$(document).delegate('select[data-widget="ddtlabs_sonos.selectmenu"]', {
	'update': function (event, response) {
		var prog = response[0].match(/prog[123]/g);
		$(this).val(prog).selectmenu('refresh');
		// DEBUG: console.log("[ddtlabs_sonos.selectmenu] update '" + this.id + "': aktuell: " +  $(this).attr('selected'), response);
	},

	'change': function (event) {
		io.write($(this).attr('data-item'), $(this).val());
		// DEBUG: console.log("[ddtlabs_sonos.selectmenu] change '" + this.id + "':", $(this).prop('selected'));
	}
});
