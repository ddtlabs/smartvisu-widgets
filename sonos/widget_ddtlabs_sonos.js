/* -----------------------------------------------
ddtlabs_sonos.cover
----------------------------------------------- */
$(document).delegate('[data-widget="ddtlabs_sonos.cover"]',{update:function(d, a){$(this).attr('src', a);}});


/* -----------------------------------------------
ddtlabs_sonos.selectmenu
----------------------------------------------- */
$(document).delegate('select[data-widget="ddtlabs_sonos.selectmenu"]', {
	'update': function (event, response) {
		$(this).val(response[0]).selectmenu('refresh');
	},
	'change': function (event) {
		io.write($(this).attr('data-item'), $(this).val());
	}
});


