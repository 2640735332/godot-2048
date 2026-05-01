@tool
extends EditorPlugin

func _enter_tree():
	# Wait a moment for editor to fully init
	await get_tree().create_timer(1.0).timeout
	
	var export_singleton = Engine.get_singleton("EditorExport")
	if export_singleton == null:
		print("RESULT: EditorExport singleton NULL")
		get_editor_interface().get_base_control().quit()
		return
	
	print("RESULT: EditorExport singleton FOUND")
	print("RESULT: export_platform_count = ", export_singleton.get_export_platform_count())
	
	# Check each platform
	for i in range(export_singleton.get_export_platform_count()):
		var p = export_singleton.get_export_platform(i)
		if p:
			print("RESULT: Platform[", i, "] = ", p.get_name())
			# Try creating a preset
			var preset = p.create_preset()
			if preset:
				print("RESULT: create_preset for ", p.get_name(), " -> preset.is_valid() = ", preset.is_valid())
			else:
				print("RESULT: create_preset for ", p.get_name(), " -> NULL Ref")
	
	# Check existing presets
	print("RESULT: get_export_preset_count = ", export_singleton.get_export_preset_count())
	
	# Try save_presets
	if export_singleton.has_method("save_presets"):
		print("RESULT: save_presets exists")
	
	# Try to manually add a preset
	if export_singleton.has_method("add_export_preset"):
		print("RESULT: add_export_preset method exists")
		# Create one for Android
		for i in range(export_singleton.get_export_platform_count()):
			var p = export_singleton.get_export_platform(i)
			if p and p.get_name() == "Android":
				var preset = p.create_preset()
				if preset and preset.is_valid():
					preset.set_name("Android")
					preset.set_runnable(true)
					var err = export_singleton.add_export_preset(preset)
					print("RESULT: add_export_preset Android err = ", err)
				else:
					print("RESULT: Android preset invalid, trying to check why...")
					# Ref might be valid but needs options set
					if preset:
						print("RESULT: preset ref exists but is_valid=", preset.is_valid())
	
	print("RESULT: After add, get_export_preset_count = ", export_singleton.get_export_preset_count())
	
	get_editor_interface().get_base_control().quit()
