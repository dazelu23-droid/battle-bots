extends Label3D


func setup(amount: float) -> void:
	text = str(int(round(amount)))
	var target_y := position.y + 1.2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
