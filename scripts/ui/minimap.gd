extends Control
class_name Minimap
## Minimapa (canto superior direito): inimigos, elites, chefão, poções e portal.

const WORLD_RADIUS := 420.0     # quanto do mundo aparece (px a partir do jogador)
var game: Game


func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _to_map(world_pos: Vector2, center: Vector2) -> Vector2:
	var r := size.x / 2.0
	var rel := (world_pos - center) / WORLD_RADIUS * (r - 6.0)
	if rel.length() > r - 6.0:
		rel = rel.normalized() * (r - 6.0)
	return Vector2(r, r) + rel


func _draw() -> void:
	if game == null or not is_instance_valid(game.player):
		return
	var r := size.x / 2.0
	var c := Vector2(r, r)
	draw_circle(c, r, Color(0.05, 0.04, 0.1, 0.55))
	draw_arc(c, r - 1.0, 0, TAU, 48, Color(1, 0.85, 0.5, 0.8), 2.0)
	var center := game.player.global_position
	# planaltos
	for pl in game.map.plateaus_near(center, WORLD_RADIUS):
		var rr: Rect2 = pl["rect"]
		var a := _to_map(rr.position, center)
		var b := _to_map(rr.end, center)
		if (b - a).length() > 1.0:
			draw_rect(Rect2(a, b - a), Color(0.75, 0.75, 0.7, 0.55))
	for e in get_tree().get_nodes_in_group("enemies"):
		var p := _to_map(e.global_position, center)
		if e.is_boss:
			draw_circle(p, 5.0, Color(0.9, 0.2, 0.8))
		elif e.is_elite:
			draw_circle(p, 3.0, Color(1.0, 0.7, 0.2))
		else:
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.3, 0.3, 0.85))
	for pk in get_tree().get_nodes_in_group("pickups"):
		if pk.kind == Pickup.Kind.POTION:
			draw_circle(_to_map(pk.global_position, center), 3.0, DB.weapon_color(pk.element))
	if game._portal and is_instance_valid(game._portal):
		var pp := _to_map(game._portal.global_position, center)
		draw_circle(pp, 5.0, Color(0.7, 0.4, 1.0))
		draw_arc(pp, 7.0, 0, TAU, 16, Color(1, 1, 1, 0.8), 1.0)
	draw_circle(c, 3.0, Color.WHITE)
