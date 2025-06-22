menu(type="taskbar" vis=key.shift() or key.lbutton() pos=0 title=app.name image=\uE249) 
{ 
	item(title="config" image=\uE10A cmd='"@app.cfg"') 
	item(title="manager" image=\uE0F3 admin cmd='"@app.exe"') 
	item(title="directory" image=\uE0E8 cmd='"@app.dir"') 
	item(title="version\t"+@app.ver vis=label col=1) 
	item(title="docs" image=\uE1C4 cmd='https://nilesoft.org/docs') 
	item(title="donate" image=\uE1A7 cmd='https://nilesoft.org/donate') 
} 
menu(where=@(this.count == 0) type='taskbar' image=icon.settings expanded=true) 
{ 
	menu(title="Apps" image=\uE254) 
	{ 
		item(title='Paint' image=\uE116 cmd='mspaint') 
		item(title='Calculator' image=\ue1e7 cmd='calc.exe') 
		item(title=str.res('regedit.exe,-16') image cmd='regedit.exe') 
	} 
	menu(title=title.windows image=\uE1FB) 
	{ 
		item(title='Show Window Horizontal' cmd=command.Show_windows_stacked) 
		item(title='Show Window Vertical' cmd=command.Show_windows_side_by_side) 
		sep 
		item(title='Minimize All Window' cmd=command.minimize_all_windows) 
		item(title='Restore All Window' cmd=command.restore_all_windows) 
	} 
	item(title=title.desktop image=icon.desktop cmd=command.toggle_desktop) 
	separator 
	menu(title="Ghost Mode" image='C:\Windows\Ico\ghost.ico') 
	{ 
		item(title='Cleanup Temporary File' image='C:\Windows\Ico\clean.ico' cmd='EcMenu_x64.exe' arg='/TempClean') 
		item(title='Restart Explorer' image='C:\Windows\Explorer.exe' cmd='EcMenu_x64.exe' arg='/ReExplorer') 
		item(title='Rebuild Icon Cache' image='C:\Windows\Ico\Sencha.ico' cmd='EcMenu_x64.exe' arg='/ReIconCache') 
		item(title='Reduce Memory' image='C:\Windows\Ico\ram.ico' cmd='EcMenu_x64.exe' arg='/Admin /ReduceMemory') 
		separator 
		item(title='Classic Control Panel' image='control.exe' cmd='control.exe') 
		item(title='Device Manager' image='DeviceProperties.exe' cmd='mmc.exe' arg='/s C:\Windows\system32\devmgmt.msc') 
		item(title='Defragment Drive' image='C:\Windows\system32\dfrgui.exe' cmd='C:\Windows\system32\dfrgui.exe') 
		item(title='Network Connections' image='iscsicli.exe' cmd='C:\Windows\system32\control.exe' arg='ncpa.cpl') 
	} 
	item(vis=key.shift() title=title.exit_explorer cmd=command.restart_explorer) 
	separator 
	item(title='Taskbar Settings' image=icon.settings cmd='ms-settings:taskbar') 
	item(title='Settings' image=icon.settings cmd='ms-settings:') 
	item(title='Task Manager' sep=both image=icon.task_manager cmd='taskmgr.exe') 
} 
