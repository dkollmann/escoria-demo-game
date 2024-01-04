"""
In Godot 4, tweens cannot be resued. But if you re-create them, the bindings are lost. So this class wraps a tween and offers a reset function.
"""
extends RefCounted
class_name Tween3

static func tween_interpolate_property(
				tween: Tween,
				object: Object, property: NodePath,
				initial_val: Variant, final_val: Variant,
				duration: float,
				trans_type: Tween.TransitionType = 0, ease_type: Tween.EaseType = 2,
				delay: float = 0) -> bool:
	var t := tween.tween_property(object, property, final_val, duration)
	
	if initial_val == null:
		t.as_relative()
	else:
		t.from(initial_val)
		
	t.set_trans(trans_type)
	t.set_ease(ease_type)
	t.set_delay(delay)
	
	return true


var _tween_parent: Node
var _tween: Tween

signal finished()

func _on_finished():
	finished.emit()

func _init(tween_parent: Node):
	_tween_parent = tween_parent
	
	_create_tween()

func _create_tween():
	_tween = _tween_parent.get_tree().create_tween()
	
	_tween.finished.connect(_on_finished)

func reset():
	_tween.stop()
	_tween.kill()
	
	_create_tween()

func interpolate_property(
				object: Object, property: NodePath,
				initial_val: Variant, final_val: Variant,
				duration: float,
				trans_type: Tween.TransitionType = 0, ease_type: Tween.EaseType = 2,
				delay: float = 0) -> bool:
	return tween_interpolate_property(_tween, object, property, initial_val, final_val, duration, trans_type, ease_type, delay)

func play():
	_tween.play()

func is_running():
	return _tween.is_running()
