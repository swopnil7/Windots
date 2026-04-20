
menu(where=wnd.is_desktop title="Performance" image=svg_power)
{
	item(title="Balanced" image=svg_power cmd='powercfg' args='-setactive 381b4222-f694-41f0-9685-ff5bb260df2e')
	item(title="Power saver" image=svg_battery cmd='powercfg' args='-setactive 48d3e473-e93e-4c68-a419-598c0051aadd')
	item(title="High performance" image=svg_performance cmd='powercfg' args='-setactive 50aab3e0-cbb2-47eb-8d63-86f970543e54')
	item(title="Ultimate Performance" image=svg_ultra_performance cmd='powercfg' args='-setactive da2c9856-2a0e-4d69-8a06-d742bbfdf37b')
	separator
	item(title="Reduce Memory" image=svg_memory_clean cmd='C:\Scripts\EcMenu_v1.6\EcMenu_x64.exe' args='/Admin /ReduceMemory' window='hidden')
	item(title="Clear Temp Files" image=svg_temp_clean cmd='C:\Scripts\EcMenu_v1.6\EcMenu_x64.exe' args='/TempClean' window='hidden')
}
