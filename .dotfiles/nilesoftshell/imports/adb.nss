$svg_android = '<svg width="100" height="100" viewBox="0 0 24 24">
  <path fill="@image.color1" d="M17.6,9.48l1.84-3.18c0.16-0.31,0.04-0.69-0.26-0.85c-0.29-0.15-0.65-0.06-0.83,0.22l-1.88,3.24 c-2.86-1.21-6.08-1.21-8.94,0L5.65,5.67c-0.19-0.29-0.58-0.38-0.87-0.2C4.5,5.65,4.41,6.01,4.56,6.3L6.4,9.48 C3.3,11.25,1.28,14.44,1,18h22C22.72,14.44,20.7,11.25,17.6,9.48z M7,15.25c-0.69,0-1.25-0.56-1.25-1.25 c0-0.69,0.56-1.25,1.25-1.25S8.25,13.31,8.25,14C8.25,14.69,7.69,15.25,7,15.25z M17,15.25c-0.69,0-1.25-0.56-1.25-1.25 c0-0.69,0.56-1.25,1.25-1.25s1.25,0.56,1.25,1.25C18.25,14.69,17.69,15.25,17,15.25z"/></svg>'

menu(mode="multiple" type='file' title='ADB' image=svg_android)
{
	item(find='.apk' mode="single" title='Install APK' cmd='powershell.exe' args='-noexit -command "adb install -r -t \"@sel.path\""')
	item(find='.apk' where=sel.count>1 title='Install Multiple APKs' cmd-ps=`$paths = '@sel(false, "|")'; $paths.Split('|') | ForEach-Object { if($_.Trim()) { adb install -r -t """$_""" } }`)
	item(title='Push to Downloads' cmd-ps=`$paths = '@sel(false, "|")'; $paths.Split('|') | ForEach-Object { if($_.Trim()) { adb push """$_""" /storage/emulated/0/Download/ } }`)
}
