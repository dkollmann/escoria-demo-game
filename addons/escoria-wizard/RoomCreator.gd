@tool
extends Control

const SCRIPT_BLANK_TEXT         = "Room will not have a script configured."
const SCRIPT_SELECT_TEXT        = "Please select script."
const PLAYER_BLANK_TEXT         = "Scene will be left blank."
const PLAYER_SELECT_TEXT        = "Please select scene."
const BACKGROUND_BLANK_TEXT     = "Image will be left blank."
const BACKGROUND_SELECT_TEXT    = "Please select image."

const ROOM_PATH_SETTING         = "escoria/wizard/path_to_rooms"

var settings_modified: bool


func _ready() -> void:
	$"InformationWindows/PlayerSceneFileDialog".get_cancel_button().connect("pressed", Callable(self, "PlayerSceneCancelled"))
	$"InformationWindows/BackgroundImageFileDialog".get_cancel_button().connect("pressed", Callable(self, "BackgroundFileCancelled"))
	
	for c in $InformationWindows.get_children():
		c.hide()

func PlayerSceneCancelled() -> void:
	if %PlayerScene.text == PLAYER_SELECT_TEXT:
		%UseEmptyPlayerButton.button_pressed = true


func BackgroundFileCancelled() -> void:
	if %BackgroundImage.text == BACKGROUND_SELECT_TEXT:
		%UseEmptyBackground.button_pressed = true


func room_creator_reset() -> void:
	var roompath = ProjectSettings.get_setting(ROOM_PATH_SETTING)
	
	%RoomName.text = ""
	%GlobalID.text = ""
	%PlayerScene.text = PLAYER_BLANK_TEXT
	%SelectPlayerScene.visible = false
	%SelectPlayerSceneSpacer.visible = true
	%UseEmptyPlayerButton.button_pressed = true
	%ESCScript.editable = false
	%ESCScript.text = SCRIPT_BLANK_TEXT
	%UseEmptyRoomScript.button_pressed = true
	%BackgroundImage.text = BACKGROUND_BLANK_TEXT
	%UseEmptyRoomSpacer.visible = true
	%UseEmptyBackground.button_pressed = true
	%SelectBackground.visible = false
	%SelectBackgroundSpacer.visible = true
	%BackgroundPreview.visible = true
	%RoomBackground.visible = true
	%BackgroundPreview.texture = null
	%RoomFolder.text = roompath if roompath else ""
	$InformationWindows/RoomFolderDialog.current_dir = roompath if roompath else ""
	settings_modified = false


func _on_RoomName_text_changed(new_text: String) -> void:
	%GlobalID.text = new_text
	settings_modified = true


func _on_GlobalID_text_changed(new_text: String) -> void:
	settings_modified = true


func _on_UseEmptyPlayerButton_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		%SelectPlayerScene.visible = false
		%SelectPlayerSceneSpacer.visible = true
		%PlayerScene.text = PLAYER_BLANK_TEXT
	else:
		%SelectPlayerScene.visible = true
		%SelectPlayerSceneSpacer.visible = false
		%PlayerScene.text = PLAYER_SELECT_TEXT
		$"InformationWindows/PlayerSceneFileDialog".popup_centered()


func _on_SelectPlayerScene_pressed() -> void:
	$"InformationWindows/PlayerSceneFileDialog".visible = true
	$"InformationWindows/PlayerSceneFileDialog".invalidate()


func _on_PlayerSceneFileDialog_file_selected(path: String) -> void:
	settings_modified = true
	%PlayerScene.text = path


func _on_UseEmptyRoomScript_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		%ESCScript.editable = false
		%ESCScript.text = SCRIPT_BLANK_TEXT
	else:
		%ESCScript.editable = true
		%ESCScript.text = "%s.esc" % %GlobalID.text


func _on_SelectRoomScript_pressed() -> void:
	$"InformationWindows/ESCScriptFileDialog".visible = true
	$"InformationWindows/ESCScriptFileDialog".invalidate()


func _on_ESCScriptFileDialog_file_selected(path: String) -> void:
	settings_modified = true
	%ESCScript.text = path


func _on_UseEmptyBackground_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		%SelectBackground.visible = false
		%SelectBackgroundSpacer.visible = true
		%BackgroundImage.text = BACKGROUND_BLANK_TEXT
		%BackgroundPreview.texture = null
		%RoomBackground.visible = true
	else:
		%SelectBackground.visible = true
		%SelectBackgroundSpacer.visible = false
		%BackgroundImage.text = BACKGROUND_SELECT_TEXT

		var viewport_centre: Vector2 = get_viewport_rect().size / 2
		var dialog_start: Vector2 = $"InformationWindows/BackgroundImageFileDialog".size / 2
		var dialog_pos: Vector2 = viewport_centre - dialog_start
		$"InformationWindows/BackgroundImageFileDialog".position = dialog_pos

		$"InformationWindows/BackgroundImageFileDialog".popup_centered()


func _on_SelectBackground_pressed() -> void:
	var viewport_centre: Vector2 = get_viewport_rect().size / 2
	var dialog_start: Vector2 = $"InformationWindows/BackgroundImageFileDialog".size / 2
	var dialog_pos: Vector2 = viewport_centre - dialog_start
	$"InformationWindows/BackgroundImageFileDialog".position = dialog_pos

	$"InformationWindows/BackgroundImageFileDialog".visible = true
	$"InformationWindows/BackgroundImageFileDialog".invalidate()


func _on_BackgroundImageFileDialog_file_selected(path: String) -> void:
	settings_modified = true

	%BackgroundImage.text = path

	var image_stream_texture:CompressedTexture2D

	image_stream_texture = load(path)

	%BackgroundPreview.texture = image_stream_texture
	%RoomBackground.visible = false
	set_preview_scale()


func set_preview_scale() -> void:
	var preview_scale = Vector2.ONE
	# Calculate the scale to make the preview as big as possible in the preview window depending on
	# the height to width ratio of the frame
	var preview_size = %RoomBackground.get_size()
#	%BackgroundPreview.rect_scale = Vector2.ONE
	var image_size = %BackgroundPreview.texture.get_size()

	preview_scale.x =  preview_size.x / image_size.x
	preview_scale.y =  preview_size.y / image_size.y

#	print("scale = "+str(preview_scale)+", preview size = "+str(preview_size)+", image_size = "+str(image_size))
	if preview_scale.y > preview_scale.x:
		%BackgroundPreview.scale = Vector2(preview_scale.x, preview_scale.x)
	else:
		# Image width will hit the preview boundary before the height will
		%BackgroundPreview.scale = Vector2(preview_scale.y, preview_scale.y)


func _on_ClearButton_pressed() -> void:
	if settings_modified:
		$InformationWindows/ClearConfirmationDialog.popup_centered()


func _on_MainMenuButton_pressed() -> void:
	if settings_modified:
		$InformationWindows/MainMenuConfirmationDialog.popup_centered()
	else:
		get_node("../Menu").visible = true
		get_node("../RoomCreator").visible = false


func _on_ClearConfirmationDialog_confirmed() -> void:
	room_creator_reset()


func _on_MainMenuConfirmationDialog_confirmed() -> void:
	get_node("../Menu").visible = true
	get_node("../RoomCreator").visible = false


func _on_ChangeRoomFolderButton_pressed() -> void:
	$"InformationWindows/RoomFolderDialog".popup_centered()


func _on_RoomFolderDialog_dir_selected(dir: String) -> void:
	ProjectSettings.set_setting(ROOM_PATH_SETTING, dir)
	var property_info = {
		"name": ROOM_PATH_SETTING,
		"type": TYPE_STRING
	}
	ProjectSettings.add_property_info(property_info)
	%RoomFolder.text = dir


func _on_CreateButton_pressed() -> void:
	var RoomName = %RoomName.text

	if RoomName.length() < 1:
		$"InformationWindows/GenericErrorDialog".dialog_text = "Error!\n\nRoom name must be specified."
		$"InformationWindows/GenericErrorDialog".popup_centered()
		return

	var ScriptName = %ESCScript.text

	if %UseEmptyRoomScript.button_pressed == false:
		if ScriptName.length() < 5 or ! ScriptName.substr(ScriptName.length() - 4) == ".esc":
			$"InformationWindows/GenericErrorDialog".dialog_text = "Error!\n\n" \
			+ "Room ESC script must be a filename ending in '.esc'"
			$"InformationWindows/GenericErrorDialog".popup_centered()
			return

	if "/" in %ESCScript.text:
			$"InformationWindows/GenericErrorDialog".dialog_text = "Error!\n\n" \
			+ "Please remove any '/' characters from the name of the Room ESC script."
			$"InformationWindows/GenericErrorDialog".popup_centered()
			return

	var BaseDir = ProjectSettings.get_setting(ROOM_PATH_SETTING)
	var ImageSize = Vector2(1,1)
	var NewRoom = ESCRoom.new()

	NewRoom.name = RoomName
	NewRoom.global_id = %GlobalID.text

	if ! %ESCScript.text == SCRIPT_SELECT_TEXT and ! %ESCScript.text == SCRIPT_BLANK_TEXT:
		NewRoom.esc_script = "%s/%s/scripts/%s" % [BaseDir, RoomName, %ESCScript.text]

	if ! %PlayerScene.text == PLAYER_SELECT_TEXT and ! %PlayerScene.text == PLAYER_BLANK_TEXT:
		var player_scene = load(%PlayerScene.text)
		NewRoom.player_scene = player_scene

	var Background = ESCBackground.new()
	Background.name = "Background"

	var BackgroundSize = Vector2.ONE

	if ! %BackgroundImage.text == BACKGROUND_SELECT_TEXT and ! %BackgroundImage.text == BACKGROUND_BLANK_TEXT:
		Background.texture = %BackgroundPreview.texture
		BackgroundSize = Background.texture.get_size()
	else:
		# Set TextureRect to have the same size as the Viewport so that the room
		# works even if no texture is set in the TextureRect
		BackgroundSize = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), \
							ProjectSettings.get_setting("display/window/size/viewport_height"))
		Background.size = BackgroundSize

	NewRoom.add_child(Background)

	var NewTerrain = ESCTerrain.new()
	NewTerrain.name = "WalkableArea"
	var NewNavigationPolygonInstance = NavigationRegion2D.new()

	var NewNavigationPolygon = NavigationPolygon.new()
	NewNavigationPolygonInstance.navigation_polygon = NewNavigationPolygon

	NewRoom.add_child(NewTerrain)

	NewTerrain.add_child(NewNavigationPolygonInstance)

	var Objects = Node2D.new()
	Objects.name = "RoomObjects"
	NewRoom.add_child(Objects)

	var StartPos = ESCLocation.new()
	StartPos.name = "StartPos"
	StartPos.is_start_location = true
	StartPos.global_id = "%s_start_pos" % RoomName
	StartPos.position = Vector2(int(BackgroundSize.x / 2), int(BackgroundSize.y / 2))
	NewRoom.add_child(StartPos)

	get_tree().edited_scene_root.add_child(NewRoom)
	NewRoom.set_owner(get_tree().edited_scene_root)
	NewNavigationPolygonInstance.set_owner(NewRoom)
	NewTerrain.set_owner(NewRoom)
	Background.set_owner(NewRoom)
	Objects.set_owner(NewRoom)
	StartPos.set_owner(NewRoom)

	DirAccess.make_dir_recursive_absolute("%s/%s/scripts" % [BaseDir, RoomName])
	DirAccess.make_dir_recursive_absolute("%s/%s/objects" % [BaseDir, RoomName])
	DirAccess.copy_absolute("res://addons/escoria-wizard/room_script_template.esc", "%s/%s/scripts/%s" % \
		[BaseDir, RoomName, %ESCScript.text])

	# Export scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(get_tree().edited_scene_root.get_node(NewRoom.name))

	# Flag suggestions from https://godotengine.org/qa/50437/how-to-turn-a-node-into-a-packedscene-via-gdscript
	ResourceSaver.save(packed_scene, "%s/%s/%s.tscn" % [BaseDir, RoomName, RoomName], \
		ResourceSaver.FLAG_CHANGE_PATH|ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

	NewRoom.queue_free()
	get_tree().edited_scene_root.get_node(NewRoom.name).queue_free()
	# Scan the filesystem so that the new folders show up in the file browser.
	# Without this you might not see the objects/scripts folders in the filetree.
	var ep = EditorPlugin.new()
	ep.get_editor_interface().get_resource_filesystem().scan()
	ep.free()

	$InformationWindows/CreateCompleteDialog.popup_centered()
