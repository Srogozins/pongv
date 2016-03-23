extends KinematicBody2D

export(Texture) var pad_texture

func _ready():
	if pad_texture:
		get_node("pad_sprite").set_texture(pad_texture)