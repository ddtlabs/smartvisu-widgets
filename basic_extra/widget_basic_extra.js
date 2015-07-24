// ----- basic.dual -----------------------------------------------------------
$(document).delegate('a[data-widget="basic_extra.dual"]', {
	'update': function (event, response) {
		$(this).val(response);
		$(this).trigger('draw');
	},

	'draw': function(event) {
		if($(this).val() == $(this).attr('data-val-on')) {
			$('#' + this.id + '-off').hide();
			$('#' + this.id + '-on').show();
		}
		else {
			$('#' + this.id + '-on').hide();
			$('#' + this.id + '-off').show();
		}
	},

	'click': function (event) {
		io.write($(this).attr('data-item'), ($(this).val() == $(this).attr('data-val-on') ? $(this).attr('data-val-off') : $(this).attr('data-val-on')) );
	}
});


