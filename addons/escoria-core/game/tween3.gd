extends Object
class_name Tween3

static func interpolate_property(	tween: Tween,
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
