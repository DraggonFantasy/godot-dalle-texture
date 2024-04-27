extends TextureProgressBar

@export var delta = 100

func _ready():
	var tween = get_tree().create_tween().set_loops()
	tween.tween_property(self, "radial_initial_angle", delta, 1).as_relative()


func _on_finished_generating(prompt, model):
	visible = false


func _on_dalle_texture_rect_started_generating(prompt, model):
	visible = true
