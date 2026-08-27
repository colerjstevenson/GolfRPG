@tool
extends EditorScript

# Configuration: Point to your root actor/object folder
const TARGET_FOLDER = "res://assets/Ducks/"

func _run():
	var clean_path = TARGET_FOLDER.simplify_path()
	var folder_name = clean_path.get_file()
	
	var folder_dir = clean_path + "/"
	var save_path = folder_dir + folder_name + "_frames.tres"
	var sprite_frames = SpriteFrames.new()
	
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	# Start recursive processing from the root folder
	_process_folder(folder_dir, "", sprite_frames)
		
	# Save the resource using the proper Godot 4 API footprint
	var error = ResourceSaver.save(sprite_frames, save_path)
	if error == OK:
		print("Successfully imported all recursive variable sheets to: ", save_path)
		# Force Godot to re-index files so it updates in the inspector layout instantly
		var editor_interface = EditorInterface.get_resource_filesystem()
		if editor_interface:
			editor_interface.scan()
	else:
		print("Error saving resource. Code: ", error)

# Recursive helper function
func _process_folder(folder_dir: String, prefix: String, sprite_frames: SpriteFrames):
	var dir = DirAccess.open(folder_dir)
	if not dir:
		print("Cannot access directory: ", folder_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
			
		var full_path = folder_dir + file_name
		
		if dir.current_is_dir() or DirAccess.dir_exists_absolute(full_path):
			var sub_folder_dir = full_path + "/"
			var new_prefix = prefix + file_name + "_"
			_process_folder(sub_folder_dir, new_prefix, sprite_frames)
		
		elif file_name.ends_with(".png"):
			# Ensure we ignore Godot's internal .png.import sidecar files
			if file_name.ends_with(".png.import"):
				file_name = dir.get_next()
				continue
				
			var anim_name = prefix + file_name.get_basename()
			
			# FIX: Use explicit ResourceLoader with type hints for Editor Tool scope
			var sheet_texture = ResourceLoader.load(full_path, "Texture2D")
			if sheet_texture is Texture2D:
				var tex_width = sheet_texture.get_width()
				var tex_height = sheet_texture.get_height()
				
				# Dynamically find frame width
				var frame_width = tex_height
				while frame_width <= tex_width:
					if tex_width % frame_width == 0:
						break
					frame_width += 1
				
				if frame_width > tex_width:
					frame_width = tex_width
					
				var frame_height = tex_height
				
				# If animation already exists, reset it to prevent corrupted frame stacking
				if not sprite_frames.has_animation(anim_name):
					sprite_frames.add_animation(anim_name)
				else:
					sprite_frames.clear(anim_name)
					
				sprite_frames.set_animation_speed(anim_name, 10.0)
				sprite_frames.set_animation_loop(anim_name, true)
				
				var total_frames = tex_width / frame_width
				
				for i in range(total_frames):
					var atlas_tex = AtlasTexture.new()
					atlas_tex.atlas = sheet_texture
					atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
					# Add frame sequentially using string identifier names
					sprite_frames.add_frame(anim_name, atlas_tex)
					
		file_name = dir.get_next()
	dir.list_dir_end()
