
@tool
extends Node2D

@export_group("Menu")
@export_tool_button("New game","PlayScene")
var game = Callable(self,"new_game")

@export_tool_button("Pause / Continue","Stop")
var pause = Callable(self,"pause_game")

@export_group("Interaction")
@export_tool_button("A","Node")
var a = Callable(self,"new_match")

@export_group("Input")
@export_tool_button("Top","ControlAlignTopWide")
var top = Callable(self,"change_direction").bind("top")

@export_tool_button("stop","ControlAlignHCenterWide")
var stop = Callable(self,"change_direction").bind("stop")

@export_tool_button("Down","ControlAlignBottomWide")
var down = Callable(self,"change_direction").bind("down")


var timer = Timer.new()

var width = 500
var height= 250
var thickness = 2

var player : Vector2
var enemy : Vector2
var ball : Vector2

var player_dir = Vector2.ZERO
var enemy_dir = Vector2.ZERO

var move_speed = 200

var ball_speed = Vector2.ZERO

var speed_x = 300
var speed_y = 150

var length = 45
var size = 5

var show_name = true

var is_playing = false
var is_paused = false
var is_over = false

var score = {
	"player" : 0,
	"enemy" : 0
}
var show_score = true

func _ready() -> void:
	randomize()
	
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 4
	timer.timeout.connect(play_game)
	
	new_game()
	
	queue_redraw()
	
func new_game():
	timer.stop()
	is_playing = false
	is_paused = false
	is_over = false
	show_name = true
	show_score = false
	player = Vector2(abs(width),0)
	enemy = Vector2(-abs(width),0)
	ball = Vector2.ZERO
	
	score["player"] = 0
	score["enemy"] = 0
	

func new_match():
	if !is_playing:
		is_over = false
		show_name = false
		show_score = true
		
		player = Vector2(abs(width),0)
		enemy = Vector2(-abs(width),0)
		ball = Vector2.ZERO
		
		player_dir = Vector2.ZERO
		enemy_dir = Vector2.ZERO
		
		ball_speed = Vector2([-speed_x,speed_x].pick_random() + randf_range(-30,30),[-speed_y,speed_y].pick_random() + randi_range(-30,30))
		
		timer.start()

func play_game():
	is_playing = true

func pause_game():
	if is_playing:
		is_paused = !is_paused

func _draw() -> void:
	if show_name:
		draw_string(ThemeDB.fallback_font, Vector2(-171.5,-32), "PINGPONG",HORIZONTAL_ALIGNMENT_CENTER,-1, 64)
	
	if show_name or is_over:
		draw_string(ThemeDB.fallback_font, Vector2(-163.5,128), 'Press "A" to continue',HORIZONTAL_ALIGNMENT_CENTER,-1, 32)
	
	if timer.time_left != 0:
		draw_string(ThemeDB.fallback_font, Vector2(-18,-32), str(int(timer.time_left)),
		HORIZONTAL_ALIGNMENT_FILL,-1, 64)
	
	if is_paused:
		draw_string(ThemeDB.fallback_font, Vector2(-124,-32),"PAUSED", HORIZONTAL_ALIGNMENT_FILL,-1, 64)
		
	if show_score:
		draw_string(ThemeDB.fallback_font, Vector2(-width,-height - 48),
			"Player Score :  " + str(score["player"]),
			HORIZONTAL_ALIGNMENT_LEFT,-1, 32)
		draw_string(ThemeDB.fallback_font, Vector2(-width,-height - 14),
			"Enemy Score : " + str(score["enemy"]),
			HORIZONTAL_ALIGNMENT_LEFT,-1, 32)
	
	draw_multiline([
		Vector2(width,height),
		Vector2(-width,height),
		Vector2(-width,-height),
		Vector2(width,-height)
	],Color.WHITE,thickness)
	
	draw_line(Vector2(0,-length) + player,Vector2(0,length) + player,Color.WHITE,size)
	draw_line(Vector2(0,-length) + enemy,Vector2(0,length) + enemy,Color.WHITE,size)
	draw_circle(Vector2.ZERO + ball,size,Color.WHITE)
	
func change_direction(input):
	match input:
		"top": player_dir = Vector2(0,1)
		"down": player_dir = Vector2(0,-1)
		_: player_dir = Vector2.ZERO

var is_colliding = false
var in_area = true

var enemy_stop = false

func _process(delta: float) -> void:
	if is_playing and !is_paused and !is_over:
		
		if abs((enemy - ball).x) <= 400:
			if !enemy_stop:
				if ball.y < enemy.y:
					enemy_dir = Vector2(0, 1)
				else:
					enemy_dir = Vector2(0, -1)
			else:
				enemy_dir = Vector2.ZERO
		else:
			enemy_dir = Vector2.ZERO
		
		if ball.x > 0:
			enemy_stop = false
		
		var collider = abs((ball - player)) if ball.x > 0 else abs((ball - enemy))
		
		if !is_colliding and (collider.x <= size * 2 and collider.y <= length):
			is_colliding = true
			enemy_stop = true
			
			ball_speed.x = -ball_speed.x
			
			var speed_bonus = speed_y + abs(collider.y - ball.y / 2)
			
			if ball_speed.y > 0:
				ball_speed.y = speed_bonus
			else:
				ball_speed.y = -speed_bonus
		
		elif is_colliding and collider.x >= size:
			is_colliding = false
		
		if in_area and abs(ball.y) >= height - size * 2:
			ball_speed.y = -ball_speed.y
			in_area = false
		
		elif !in_area and abs(ball.y) <= height - size * 2:
			in_area = true
			
		if abs(ball.x) >= width + 10:
			if ball.x < 0:
				score["player"] += 1
			else:
				score["enemy"] += 1
			is_playing = false
			is_over = true
		
		player -= player_dir * move_speed * delta
		enemy -= enemy_dir * move_speed * delta
		ball -= ball_speed * delta
		
		var clamp_pos = abs(height - length - thickness / 2)
		player.y = clamp(player.y,-clamp_pos,clamp_pos)
		enemy.y = clamp(enemy.y,-clamp_pos,clamp_pos)
		
	queue_redraw()
