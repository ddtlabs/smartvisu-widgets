// ----- ddtlabs_icon.battery ---------------------------------------------------------
$(document).delegate('svg[data-widget="ddtlabs_icon.battery"]', {
	'update' : function (event, response) {
		// response is: {{ gad_value }}, {{ gad_switch }}
//		var val = Math.round(response[0] / $(this).attr('data-max') * 40);
		var val = (Math.round(response[0] - $(this).attr('data-min')) / ($(this).attr('data-max') - $(this).attr('data-min')) * 40);
//		console.log(val);
		fx.grid(this, val, [39, 68], [61, 28]);
	}
});


// ----- ddtlabs_icon.battery2 ---------------------------------------------------------
$(document).delegate('svg[data-widget="ddtlabs_icon.battery2"]', {
	'update' : function (event, response) {
		// response is: {{ gad_value }}, {{ gad_switch }}
//		var val = Math.round(response[0] / $(this).attr('data-max') * 40);
		var val = (Math.round(response[0] - $(this).attr('data-min')) / ($(this).attr('data-max') - $(this).attr('data-min')) * 40);
//		console.log(val);
		fx.grid(this, val, [39, 68], [61, 28]);
	}
});
