// ----- basic.dual -----------------------------------------------------------
$(document).delegate('a[data-widget="ddtlabs_basic.dual"]', {
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

// ----- basic.switch ---------------------------------------------------------
$(document).delegate('span[data-widget="ddtlabs_basic.switch"]', {
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
		io.write($(this).attr('data-item'), ($(this).val() == $(this).attr('data-val-off') ? $(this).attr('data-val-on') : $(this).attr('data-val-off')) );
	}
});

// ----- basic.switch.v1 ------------------------------------------------------
$(document).delegate('span[data-widget="ddtlabs_basic.switch.v1"]', {
	'update': function (event, response) {
		$('#' + this.id + ' img').attr('src', (response == $(this).attr('data-val-on') ? $(this).attr('data-pic-on') : $(this).attr('data-pic-off')));
	},

	'click': function (event) {
		if ($('#' + this.id + ' img').attr('src') == $(this).attr('data-pic-off')) {
			io.write($(this).attr('data-item'), $(this).attr('data-val-on'));
		}
		else {
			io.write($(this).attr('data-item'), $(this).attr('data-val-off'));
		}
	}
});

$(document).delegate('span[data-widget="ddtlabs_basic.switch.v1"] > a > img', 'hover', function (event) {
	if (event.type === 'mouseenter') {
		$(this).addClass("ui-focus");
	}
	else {
		$(this).removeClass("ui-focus");
	}
});
