modify(
	find="Open with Code"
	image = \uE272
)

modify(
	find="Open with Code"
	where=wnd.is_desktop
	vis=vis.remove
)

modify(
	find="NanaZip"
	image = svg_nanazip
)

modify(
	find="File Converter"
	image = svg_file_converter
	menu="File manage" pos=1
)

modify(
	mode=mode.multiple
	where=(this.name=="Scan with Microsoft Defender" || this.name=="Upload With ShareX" || this.name=="7-Zip")
	menu=title.more_options
)

modify(
	find='vlc|WizTree|Open Alacritty here|Edit with|TeraCopy|Rename with PowerRename|Open with Sublime Text'
	menu=title.more_options
)

modify(
	find="Open git"
	pos="bottom"
	menu="develop"
)

	item(where=wnd.is_desktop title='ENV GUI' keys='SHIFT edit sys env' tip='Edit Environment Variables' image='@sys.bin\imageres.dll,156' sep='after'
		 admin=keys.shift() cmd='rundll32.exe' args='sysdm.cpl,EditEnvironmentVariables')