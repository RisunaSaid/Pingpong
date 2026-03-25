
@tool
extends Node2D

@export_group("Menu")
@export_tool_button("New game","PlayScene")
var permainan_baru = Callable(self,"new_game")

@export_tool_button("Pause / Continue","Stop")
var jeda = Callable(self,"pause_game")

@export_group("Interaction")
@export_tool_button("A","Node")
var a = Callable(self,"new_match")

@export_group("Input")
@export_tool_button("Top","ControlAlignTopWide")
var atas = Callable(self,"change_direction").bind("top")

@export_tool_button("stop","ControlAlignHCenterWide")
var diam = Callable(self,"change_direction").bind("stop")

@export_tool_button("Down","ControlAlignBottomWide")
var bawah = Callable(self,"change_direction").bind("down")


var timer = Timer.new()

var width = 400
var height= 200

var player = Node2D.new()
var enemy = Node2D.new()
var ball = Node2D.new()

var player_dir = Vector2.ZERO
var enemy_dir = Vector2.ZERO

var speed = 200
var ball_speed = Vector2.ZERO

var length = 40
var thickness = 5

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
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 4
	timer.timeout.connect(play_game)
	
	add_child(player)
	add_child(enemy)
	add_child(ball)
	
	new_game()
	
	queue_redraw()
	
func new_game():
	timer.stop()
	is_playing = false
	is_paused = false
	is_over = false
	show_name = true
	show_score = false
	player.position = Vector2(width,0)
	enemy.position = Vector2(-width,0)
	ball.position = Vector2.ZERO
	
	score["player"] = 0
	score["enemy"] = 0
	

func new_match():
	if !is_playing:
		is_over = false
		show_name = false
		show_score = true
		
		player.position = Vector2(width,0)
		enemy.position = Vector2(-width,0)
		ball.position = Vector2.ZERO
		
		player_dir = Vector2.ZERO
		enemy_dir = Vector2.ZERO
		
		ball_speed = Vector2([-250,250].pick_random(),[randf_range(-200,-210),randf_range(200,210)].pick_random())
		
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
	],Color.WHITE)
	
	draw_line(Vector2(0,-length) + player.position,Vector2(0,length) + player.position,Color.WHITE,thickness)
	draw_line(Vector2(0,-length) + enemy.position,Vector2(0,length) + enemy.position,Color.WHITE,thickness)
	draw_circle(Vector2.ZERO + ball.position,thickness,Color.WHITE)
	
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
		
		if abs((enemy.position - ball.position).x) <= 280:
			if !enemy_stop:
				if ball.position.y < enemy.position.y:
					enemy_dir = Vector2(0, 1)
				else:
					enemy_dir = Vector2(0, -1)
			else:
				enemy_dir = Vector2.ZERO
		else:
			enemy_dir = Vector2.ZERO
		
		if ball.position.x > 0:
			enemy_stop = false
		
		var player_col = abs((ball.position - player.position))
		var enemy_col = abs((ball.position - enemy.position))
		
		if !is_colliding and ((player_col.x <= thickness and player_col.y <= length) or (enemy_col.x <= thickness and enemy_col.y <= length)):
			is_colliding = true
			enemy_stop = true
			ball_speed.x = -ball_speed.x
			if ball_speed.y > 0:
				ball_speed.y = randf_range(200,210)
			else:
				ball_speed.y = randf_range(-200,-210) 
			
		elif is_colliding and (player_col.x >= thickness or enemy_col.x >= thickness):
			is_colliding = false
		
		if in_area and abs(ball.position.y) >= height - thickness:
			ball_speed.y = -ball_speed.y
			in_area = false
		
		elif !in_area and abs(ball.position.y) <= height - thickness:
			in_area = true
			
		if abs(ball.position.x) >= width + 10:
			if ball.position.x < 0:
				score["player"] += 1
			else:
				score["enemy"] += 1
			is_playing = false
			is_over = true
			
		player.position -= player_dir * speed * delta
		enemy.position -= enemy_dir * speed * delta
		ball.position -= ball_speed * delta
		
		var clamp_pos = abs(height - length)
		player.position.y = clamp(player.position.y,-clamp_pos,clamp_pos)
		enemy.position.y = clamp(enemy.position.y,-clamp_pos,clamp_pos)
		
	queue_redraw()
