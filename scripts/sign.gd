extends Area2D


var alert_radius = 60

@export var par = 4
@export var hole = 1



var message = "Hole %d\nPar %d" % [hole, par]


func _ready() -> void:
	$Dialog.visible = false
	$Dialog/text.text = message
	
	
func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group(&"player") as Node2D
	
	if player != null:
		if global_position.distance_to(player.global_position) <= alert_radius:
			$Dialog.visible = true
		else:
			$Dialog.visible = false
