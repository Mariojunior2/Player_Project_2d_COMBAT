extends CharacterBody2D

@export var max_health := 10
var current_health : int

func _ready():
	current_health = max_health
	$Hurtbox.connect("area_entered", Callable(self, "_on_Hurtbox_area_entered"))

func _process(delta):
	velocity.x = 30.0
	move_and_slide()

func _on_Hurtbox_area_entered(area):
	if area.name == "AttackHitbox":  
		take_damage()
	if area.name == "DamageArea":
		take_damage()

func take_damage():
	current_health -= 1
	print("Inimigo recebeu dano! HP: ", current_health)
	if current_health <= 0:
		die()

func die():
	print("Enemy defeated!")
	queue_free()
