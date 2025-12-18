menu(where=!wnd.is_desktop && sel.count>0 type='file|dir|drive|namespace|back' mode="multiple" title='File manage' image=\uE253)
{
	menu(separator="after" title=title.copy_path image=icon.copy_path)
	{
		item(where=sel.count > 1 title='Copy (@sel.count) items selected' cmd=command.copy(sel(false, "\n")))
		item(mode="single" title=@sel.path tip=sel.path cmd=command.copy(sel.path))
		item(mode="single" type='file' separator="before" find='.lnk' title='open file location')
		separator
		item(mode="single" where=@sel.parent.len>3 title=sel.parent cmd=@command.copy(sel.parent))
		separator
		item(mode="single" type='file|dir|back.dir' title=sel.file.name cmd=command.copy(sel.file.name))
		item(mode="single" type='file' where=sel.file.len != sel.file.title.len title=@sel.file.title cmd=command.copy(sel.file.title))
	}

	menu(image=icon.copy_path title='Environment Path' mode='single' type='dir|back.dir|drive|back.drive|desktop') {
	//+ https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables
	item(title='ENV GUI' keys='SHIFT edit sys env' tip='Edit Environment Variables' image='@sys.bin\imageres.dll,156' sep='both'
		 admin=keys.shift() cmd='rundll32.exe' args='sysdm.cpl,EditEnvironmentVariables')

	$reg_cu = reg.get('HKCU\Environment', 'PATH')
	$reg_lm = reg.get('HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'PATH')
	// does not work for drives
	$is_in_path			= str.contains(reg_cu, sel+';') or str.contains(reg_cu, sel+'\;') or str.end(reg_cu, sel)
	$add_to_path		= str.replace('@reg_cu;@sel', ';;', ';').trimstart(';')
	$remove_from_path	= str.replace(reg_cu, sel, '').replace('\;', ';').replace(';;', ';')
	
	/* need explorer restart to take effect
	item(title=if(is_in_path, 'Remove from ', 'Add to ')+"%PATH%" type='dir' 
		admin cmd-line='/c @if(is_in_path, if(msg('Are you sure you want to remove this path?', 'NileSoft Shell', msg.yesno | msg.warning)==msg.idyes, 'setx PATH "@remove_from_path" & pause & exit'), 'setx PATH "@add_to_path" & pause & exit')')
	*/
	item(title=if(is_in_path, 'Remove path from ', 'Add path to ')+"%PATH%" type='dir|dir.back' image=if(is_in_path, \uE171, \uE172)
		admin cmd=if(is_in_path, if(msg('Are you sure you want to remove this path?', 'NileSoft Shell', msg.yesno | msg.warning)==msg.idyes, reg.set('HKCU\Environment', 'PATH', remove_from_path)), reg.set('HKCU\Environment', 'PATH', add_to_path)))

	separator()
	item(title='Check '+"%PATH%" keys='default'	where=keys.shift()	image=\uE187 cmd=msg(str.join(str.split('%path%', ';'), "\n"))) 
	item(title='Check '+"%PATH%" keys='CU'		where=keys.shift()	image=\uE187 cmd=msg(str.join(str.split(reg_cu, ';'), "\n")))
	item(title='Check '+"%PATH%" keys='LM'		where=keys.shift()	image=\uE187 cmd=msg(str.join(str.split(reg_lm, ';'), "\n")))
	item(title='Check '+"%PATH%" keys='LM+CU'	where=keys.shift()	image=\uE187 cmd=msg(str.join(str.split(reg_lm, ';'), "\n") + "\n\n" + str.join(str.split(reg_cu, ';'), "\n")))
	}

	item(mode="single" type="file" title="Change extension" image=\uE0B5 cmd=if(input("Change extension", "Type extension"),
		io.rename(sel.path, path.join(sel.dir, sel.file.title + "." + input.result))))

	menu(separator="after" image=\uE290 title=title.select)
	{
		item(title="All" image=icon.select_all cmd=command.select_all)
		item(title="Invert" image=icon.invert_selection cmd=command.invert_selection)
		item(title="None" image=icon.select_none cmd=command.select_none)
	}

	item(type='file|dir|back.dir|drive' title='Take ownership' image=[\uE194,#f00] admin
		cmd args='/K takeown /f "@sel.path" @if(sel.type==1,null,"/r /d y") && icacls "@sel.path" /grant *S-1-5-32-544:F @if(sel.type==1,"/c /l","/t /c /l /q")')
	separator
	menu(title="Show/Hide" image=icon.show_hidden_files)
	{
		item(title="System files" image=inherit cmd='@command.togglehidden')
		item(title="File name extensions" image=icon.show_file_extensions cmd='@command.toggleext')
	}

	menu(type='file|dir|back.dir' mode="single" title='Attributes' image=icon.properties)
	{
		$atrr = io.attributes(sel.path)
		item(title='Hidden' checked=io.attribute.hidden(atrr)
			cmd args='/c ATTRIB @if(io.attribute.hidden(atrr),"-","+")H "@sel.path"' window=hidden)

		item(title='System' checked=io.attribute.system(atrr)
			cmd args='/c ATTRIB @if(io.attribute.system(atrr),"-","+")S "@sel.path"' window=hidden)

		item(title='Read-Only' checked=io.attribute.readonly(atrr)
			cmd args='/c ATTRIB @if(io.attribute.readonly(atrr),"-","+")R "@sel.path"' window=hidden)

		item(title='Archive' checked=io.attribute.archive(atrr)
			cmd args='/c ATTRIB @if(io.attribute.archive(atrr),"-","+")A "@sel.path"' window=hidden)
		separator
		item(title="Created" keys=io.dt.created(sel.path, 'y/m/d') cmd=io.dt.created(sel.path,2000,1,1) vis=label)
		item(title="Modified" keys=io.dt.modified(sel.path, 'y/m/d') cmd=io.dt.modified(sel.path,2000,1,1) vis=label)
		item(title="Accessed" keys=io.dt.accessed(sel.path, 'y/m/d') cmd=io.dt.accessed(sel.path,2000,1,1) vis=label)
	}

	menu(mode="single" type='file' find='.dll|.ocx' separator="before" title='Register Server' image=\uea86)
	{
		item(title='Register' admin cmd='regsvr32.exe' args='@sel.path.quote' invoke="multiple")
		item(title='Unregister' admin cmd='regsvr32.exe' args='/u @sel.path.quote' invoke="multiple")
	}

	menu(mode="single" type='back' expanded=true)
	{
		menu(separator="before" title='New Folder' image=icon.new_folder)
		{
			item(title='DateTime' cmd=io.dir.create(sys.datetime("ymdHMSs")))
			item(title='Guid' cmd=io.dir.create(str.guid))
		}

		menu(title='New File' image=icon.new_file)
		{
			$dt = sys.datetime("ymdHMSs")
			item(title='TXT' cmd=io.file.create('@(dt).txt', 'Hello World!'))
			item(title='XML' cmd=io.file.create('@(dt).xml', '<root>Hello World!</root>'))
			item(title='JSON' cmd=io.file.create('@(dt).json', '[]'))
			item(title='HTML' cmd=io.file.create('@(dt).html', "<html>\n\t<head>\n\t</head>\n\t<body>Hello World!\n\t</body>\n</html>"))
		}
	}

	item(where=!wnd.is_desktop title=title.folder_options image=icon.folder_options cmd=command.folder_options)
}