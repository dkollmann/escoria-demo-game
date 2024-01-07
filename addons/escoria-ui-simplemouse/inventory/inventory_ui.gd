extends ESCInventory


# Whether the inventory is visible currently
var inventory_visible: bool = false

@onready var _tween: Tween3 = Tween3.new(self)

func _ready() -> void:
	# Hide inventory by default
	$FloatingInventory/panel.position.x = \
		ProjectSettings.get_setting("display/window/size/viewport_width")

func _on_inventory_button_pressed():
	if _tween.is_running():
		return
	if inventory_visible:
		hide_inventory()
	else:
		show_inventory()


func show_inventory():
	_tween.reset()
	_tween.interpolate_property(
		$FloatingInventory/panel,
		"position:x",
		$FloatingInventory/panel.position.x,
		$FloatingInventory/panel.position.x - \
				$FloatingInventory/panel.size.x - \
				$inventory_button.size.x,
		0.6
	)
	_tween.play()
	await _tween.finished
	_tween.stop()
	inventory_visible = true


func hide_inventory():
	_tween.reset()
	_tween.interpolate_property(
		$FloatingInventory/panel,
		"position:x",
		$FloatingInventory/panel.position.x,
		$FloatingInventory/panel.position.x + \
				$FloatingInventory/panel.size.x + \
				$inventory_button.size.x,
		0.6
	)
	_tween.play()
	await _tween.finished
	_tween.stop()
	inventory_visible = false
