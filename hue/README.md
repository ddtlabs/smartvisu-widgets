### HUE Widgets for SmartVISU / FHEM

Installation hints:

- Copy widget_hue.html to your pages folder

- Add CSS code from widget_hue.css to your visu.css or include it any other way

- Converter settings can be found in widget_hue.converter

- Code for your rooms to call widgets:

```
<div class="block">
	<div class="set-1" data-role="collapsible-set" data-theme="c" data-content-theme="a" data-mini="true">
		<div data-role="collapsible" data-collapsed="false" >
		<h3>Hue 1</h3>
		<table width="90%">
			<tr><td>{{ hue.extcolordimmer('your_hue_id','your_hue_device',16,20) }}</td></tr>
		</table>
		</div>
	</div>
</div>
```

```
<div class="block">
	<div class="set-2" data-role="collapsible-set" data-theme="c" data-content-theme="a" data-mini="true">
		<div data-role="collapsible" data-collapsed="false" >
		<h3>Hue Dimmer</h3>
		<table width="90%">
		<tr><td>{{ hue.colordimmer_small('your_hue_id_1', 'Hue 1','WZ_LI_HUE1',1,32,'') }}</td></tr>
		<tr><td>{{ hue.colordimmer_small('your_hue_id_2', 'Hue 2','WZ_LI_HUE3',1,16,20) }}</td></tr>
		<tr><td>{{ hue.colordimmer_small('your_hue_id_3', 'Hue 3','WZ_LI_HUE2',1,16,20) }}</td></tr>
		</table>
		</div>
	</div>
</div>
```
- Have fun...
