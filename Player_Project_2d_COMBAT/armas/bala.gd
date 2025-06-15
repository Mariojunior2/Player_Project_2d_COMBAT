extends Node2D

const SPEED: int = 300


func _ready():
	$DamageArea.connect("area_entered", Callable(self, "_on_area_entered"))

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_area_entered(area):
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage()
		queue_free()  
