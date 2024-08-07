package sokoban

import rl   "vendor:raylib"


Window :: struct { 
	name:          cstring,
	width:         i32, 
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
}

World :: struct {
	width:   i32,
	height:  i32,
	tiles:   []Tile,
}

Cell :: struct { 
	width:  f32,
	height: f32,
}

Coord :: struct {
	x: i32,
	y: i32,
}

Tilemap :: struct {
	texture: rl.Texture2D,
	tileWidth: f32,
	tileHeight: f32,
	margin: f32,
	gutter: f32,
	tileCoords: []rl.Vector2
}

Game :: struct {
	pause:		bool,
	colors:		[]rl.Color,
	baseLayerRects:		[]rl.Rectangle,
	objectLayerRects:	[]rl.Rectangle,
	width:		i32,
	height:		i32,
	state:		GameState,
	puzzle_index: int,
	moves: int,
}

GameState :: enum {
	Gameplay,
	You_Win,
}

Player :: struct {
    x: i32,
    y: i32,
    state: PlayerState,
    direction: Direction,
}

PlayerState :: enum {
	resting,
	walking,
	pushing,
	walkingOdd,
	pushingEven,
	pushingOdd,
}

Direction :: enum {
	up,
	right,
	down,
	left,
}




User_Input :: struct {
	up: bool,
	down: bool,
	left: bool,
	right: bool,

	upHeld: bool,
	downHeld: bool,
	leftHeld: bool,
	rightHeld: bool,

	reset: bool,
	undo: bool,
	next_level: bool,
	prev_level: bool,
	advance: bool,
}

Tile :: enum {
	Void,
	Wall,
	Player,
	PlayerOnGoal,
	Box,
	BoxOnGoal,
	Goal,
	Floor,
}



draw_world_colors :: #force_inline proc(world: ^World, cell:Cell, colors: []rl.Color) {
	x, y : i32
	for y = 0; y < world.height; y += 1 {
		for x = 0; x < world.width; x += 1 {
			index := y * world.width + x
			color := colors[world.tiles[index]]

			rect := rl.Rectangle {
				x = f32(x) * cell.width,
				y = f32(y) * cell.height,
				width = cell.width,
				height = cell.height,
			}
			rl.DrawRectangleRec(rect, color)
		}
	}
}


draw_world_tiles :: #force_inline proc(world: ^World, tilemap: rl.Texture2D, cell:Cell, rects: []rl.Rectangle, player: Player, processPlayer: bool) {
	x, y : i32
	for y = 0; y < world.height; y += 1 {
		for x = 0; x < world.width; x += 1 {
			index := y * world.width + x
			source_rect := rects[world.tiles[index]]

			rotation:f32 = 0
			if processPlayer && (world.tiles[index] == Tile.Player || world.tiles[index] == Tile.PlayerOnGoal) {
				source_rect = rects[8 + int(player.state)]
				rotation += f32(player.direction) * 90
			}

			dest_rect := rl.Rectangle {
				x = f32(x) * cell.width,
				y = f32(y) * cell.height,
				width = cell.width,
				height = cell.height,
			}
			rl.DrawTexturePro(tilemap, source_rect, dest_rect, {cell.width/2,cell.height/2}, rotation, rl.WHITE)
		}
	}
}


update_world :: #force_inline proc(world: ^World, next_world: ^World) {
	x, y : i32
	for y = 0; y < world.height; y += 1 {
		for x = 0; x < world.width; x += 1 {
			// index := y * world.width + x
		}
	}
}





measure_puzzle :: #force_inline proc(puzzle: ^Puzzle) {
	x, y : i32
	width : i32 = 0
	height : i32 = 0
	for tile in puzzle.tiles {
		switch tile {
			case '\n', '|':
				y += 1
				x = 0
			case '-','_','#','@','+','$','*','.',' ':
				x += 1
		}
		if x > width do width = x
		if y > height do height = y
	}
	puzzle.width = width - 1
	puzzle.height = height - 1
}

set_puzzle :: #force_inline proc(puzzle: ^Puzzle, world: ^World, next_world: ^World, player: ^Player) {

	for tile, index in next_world.tiles {
		next_world.tiles[index] = Tile.Void
	}

	x, y : i32
	origin_x, origin_y : i32
	origin_x = (world.width - puzzle.width) / 2
	origin_y = (world.height - puzzle.height) / 2
	x, y = origin_x, origin_y

	encountered_tile_on_row := false

	for tile in puzzle.tiles {
		switch tile {
			case '\n', '|':
				y += 1
				x = origin_x
				encountered_tile_on_row = false
			case '-','_':
				next_world.tiles[y * world.width + x] = Tile.Void
				x += 1
			case '#':
				next_world.tiles[y * world.width + x] = Tile.Wall
				encountered_tile_on_row = true
				x += 1
			case '@':
				player^ = {x, y, .resting, .up}
				next_world.tiles[y * world.width + x] = Tile.Player
				encountered_tile_on_row = true
				x += 1
			case '+':
				player^ = {x, y, .resting, .up}
				next_world.tiles[y * world.width + x] = Tile.PlayerOnGoal
				encountered_tile_on_row = true
				x += 1
			case '$':
				next_world.tiles[y * world.width + x] = Tile.Box
				encountered_tile_on_row = true
				x += 1
			case '*':
				next_world.tiles[y * world.width + x] = Tile.BoxOnGoal
				encountered_tile_on_row = true
				x += 1
			case '.':
				next_world.tiles[y * world.width + x] = Tile.Goal
				encountered_tile_on_row = true
				x += 1
			case ' ':
				if (encountered_tile_on_row) {
					next_world.tiles[y * world.width + x] = Tile.Floor
				} else {
					next_world.tiles[y * world.width + x] = Tile.Void
				}
				
				x += 1
		}
	}
}

check_for_win :: proc(world: World) -> bool {
	x, y : i32
	boxes := 0
	goals := 0
	boxesOnGoals := 0
	for y = 0; y < world.height; y += 1 {
		for x = 0; x < world.width; x += 1 {
			index := y * world.width + x
			#partial switch world.tiles[index] {
				case Tile.Box:
					boxes += 1
				case Tile.BoxOnGoal:
					boxesOnGoals += 1
				case Tile.Goal:
					goals += 1
				case Tile.PlayerOnGoal:
					goals += 1
			}
		}
	}
	if boxes == 0 && goals == 0 && boxesOnGoals > 0 {
		return true
	}
	return false
}

RectFromCoord :: proc(coord: rl.Vector2, tilemap:Tilemap) -> rl.Rectangle {
	using tilemap
	return {
		gutter + coord.x * (tileWidth + gutter),
		gutter + coord.y * (tileHeight + gutter),
		tileWidth,
		tileHeight
	}
}

process_user_input :: proc(user_input: ^User_Input, window: Window, world: World) {
	user_input^ = User_Input {
		up			= rl.IsKeyPressed(.UP),
		down		= rl.IsKeyPressed(.DOWN),
		left		= rl.IsKeyPressed(.LEFT),
		right		= rl.IsKeyPressed(.RIGHT),
		upHeld		= rl.IsKeyDown(.UP),
		downHeld	= rl.IsKeyDown(.DOWN),
		leftHeld	= rl.IsKeyDown(.LEFT),
		rightHeld	= rl.IsKeyDown(.RIGHT),
		reset 		= rl.IsKeyPressed(.R),
		next_level	= rl.IsKeyPressed(.RIGHT_BRACKET),
		prev_level	= rl.IsKeyPressed(.LEFT_BRACKET),
		advance 	= rl.IsKeyPressed(.SPACE),
	}
}

main :: proc() {
	window := Window{"Welcome to the Sokoban", 960, 720, 60, rl.ConfigFlags{ }}

	game := Game {
		pause     = true,
		colors    = []rl.Color { 
			rl.BLACK,		//void				0
			rl.RAYWHITE,	//Wall				#
			rl.GREEN,		//Player			@
			rl.DARKGREEN,	//Player on goal	+
			rl.BEIGE,		//Box				$
			rl.BROWN,		//Box on goal		*
			rl.DARKGRAY,	//Goal square		.
			rl.LIGHTGRAY,	//Floor				(space)
		},
		width     = 32,
		height    = 32,
	}

	world			:= World{game.width, game.height, make([]Tile, game.width * game.height)}
	next_world		:= World{game.width, game.height, make([]Tile, game.width * game.height)}
	initial_world	:= World{game.width, game.height, make([]Tile, game.width * game.height)}

	defer delete(world.tiles)
	defer delete(next_world.tiles)

	user_input : User_Input

	initial_player : Player
	player : Player


	puzzleSet : []Puzzle = {
		readPuzzleString(simplestpuzzle, "simplest possible sokoban"),
		readPuzzleString(claire, "Claire, by Lee J Haywood"),
		readPuzzleString(coffeepuzzle, "coffe sokoban"),
		readPuzzleString(courtyard, "courtyard")
	}



	

	camera : rl.Camera2D


	rl.InitWindow(window.width, window.height, window.name)
	rl.SetWindowState( window.control_flags )
	rl.SetTargetFPS(window.fps)

	set_puzzle(&puzzleSet[game.puzzle_index], &world, &next_world, &player)
	world, next_world = next_world, world
	rl.SetWindowTitle(puzzleSet[game.puzzle_index].title)

	shoveIt := Tilemap {
		rl.LoadTexture("./tilesets/ShoveIt.png"),
		24, 24,
		4, 4,
		{
			{5,3}, //void
			{6,2}, //wall
			{0,0}, //player
			{1,0}, //player on goal
			{2,1}, //box
			{3,1}, //box on goal
			{5,2}, //goal
			{4,2}, //floor
			{1,0}, //player resting
			{0,0}, //player walking
			{4,0}, //player pushing neutral
			{2,0}, //player walking odd frame
			{3,0}, //player pushing even frame
			{5,0}, //player pushing odd frame
		}

	}

	sokobanPerfect := Tilemap {
		rl.LoadTexture("./tilesets/SokobanPerfect.png"),
		40, 54,
		4, 4,
		{
			{5,0}, //void
			{2,0}, //wall
			{4,1}, //player
			{4,1}, //player on goal
			{3,0}, //box
			{4,0}, //box on goal
			{1,0}, //goal
			{0,0}, //floor
			{4,1}, //player resting
			{3,1}, //player walking
			{4,2}, //player pushing neutral
			{5,1}, //player walking odd frame
			{5,2}, //player pushing even frame
			{3,2}, //player pushing odd frame
		}
	}

	tilemap := shoveIt

	cell := Cell {
		width  = tilemap.tileWidth,
		height = tilemap.tileHeight,
	}

	camera.target = {f32(world.width)/2 * cell.width,f32(world.height)/2 * cell.height}
	camera.offset = {f32(window.width) / 2.0, f32(window.height) / 2.0}
	camera.zoom = 2.0

	game.baseLayerRects = []rl.Rectangle {
		RectFromCoord(tilemap.tileCoords[0], tilemap), //void
		RectFromCoord(tilemap.tileCoords[1], tilemap), //wall
		RectFromCoord(tilemap.tileCoords[7], tilemap), //player, draw floor
		RectFromCoord(tilemap.tileCoords[6], tilemap), //player on goal, draw goal
		RectFromCoord(tilemap.tileCoords[7], tilemap), //box, draw floor
		RectFromCoord(tilemap.tileCoords[6], tilemap), //boxongoal, draw goal
		RectFromCoord(tilemap.tileCoords[6], tilemap), //goal
		RectFromCoord(tilemap.tileCoords[7], tilemap), //floor
		{},
		{},
		{},
		{},
		{},
		{},
	}

	game.objectLayerRects = []rl.Rectangle {
		{}, //void
		{}, //wall
		RectFromCoord(tilemap.tileCoords[2], tilemap), //player
		RectFromCoord(tilemap.tileCoords[3], tilemap), //player on goal
		RectFromCoord(tilemap.tileCoords[4], tilemap), //box
		RectFromCoord(tilemap.tileCoords[5], tilemap), //boxongoal
		{}, //goal
		{}, //floor
		RectFromCoord(tilemap.tileCoords[8], tilemap), //resting
		RectFromCoord(tilemap.tileCoords[9], tilemap), //walking
		RectFromCoord(tilemap.tileCoords[10], tilemap), //pushing
		RectFromCoord(tilemap.tileCoords[11], tilemap), //walkingOdd
		RectFromCoord(tilemap.tileCoords[12], tilemap), //pushingEven
		RectFromCoord(tilemap.tileCoords[13], tilemap), //pushingOdd
	}

	rest_timer: f32

	for !rl.WindowShouldClose() {
		using game

		rest_timer += rl.GetFrameTime()
		if(rest_timer > 1) {
			player.state = .resting
		}

		

		process_user_input(&user_input, window, world)

		front := player
		leap := player

		if (state == GameState.Gameplay) {


			if user_input.left {
				front.x -= 1
				leap.x -= 2
				player.direction = .left
				front.direction = .left
			}
			else if user_input.right {
				front.x += 1
				leap.x += 2
				player.direction = .right
				front.direction = .right
			}
			else if user_input.up {
				front.y -= 1
				leap.y -= 2
				player.direction = .up
				front.direction = .up
			}
			else if user_input.down {
				front.y += 1
				leap.y += 2
				player.direction = .down
				front.direction = .down
			}
		}




		if (player != front) {
			prevTile := world.tiles[player.y    * world.width + player.x]
			nextTile := world.tiles[front.y 	* world.width + front.x]
			leapTile := world.tiles[leap.y 		* world.width + leap.x]
			moved := false
			movedBox := false
			leapTileFree := leapTile == Tile.Floor || leapTile == Tile.Goal

			#partial switch nextTile {
				case Tile.Floor:
					world.tiles[front.y * world.width + front.x] = Tile.Player
					moved = true
				case Tile.Goal:
					world.tiles[front.y * world.width + front.x] = Tile.PlayerOnGoal
					moved = true
				case Tile.Box:
					if leapTileFree {
						world.tiles[front.y * world.width + front.x] = Tile.Player
						moved = true
						movedBox = true
					}
				case Tile.BoxOnGoal:
					if leapTileFree {
						world.tiles[front.y * world.width + front.x] = Tile.PlayerOnGoal
						moved = true
						movedBox = true
					}
			}
			if moved {
				#partial switch prevTile {
					case Tile.PlayerOnGoal:
						world.tiles[player.y * world.width + player.x] = Tile.Goal
					case Tile.Player:
						world.tiles[player.y * world.width + player.x] = Tile.Floor
				}
				player = front
				
				moves += 1
				if moves % 2 == 0 {
					player.state = .walking
					rest_timer = 0
				} else {
					player.state = .walkingOdd
					rest_timer = 0
				}
			} else {
				player.state = .pushing
				rest_timer = 0
			}
			if movedBox {
				#partial switch leapTile {
					case Tile.Floor:
						world.tiles[leap.y * world.width + leap.x] = Tile.Box
					case Tile.Goal:
						world.tiles[leap.y * world.width + leap.x] = Tile.BoxOnGoal
						if check_for_win(world) {
							state = .You_Win
						}
				}
				if moves % 2 == 0 {
					player.state = .pushingEven
					rest_timer = 0
				} else {
					player.state = .pushingOdd
					rest_timer = 0
				}

			}
		}

		next_index := game.puzzle_index
		if user_input.next_level || (user_input.advance && state == .You_Win) {
			next_index = (next_index + 1) %% len(puzzleSet)
		}
		if user_input.prev_level {
			next_index = (next_index - 1) %% len(puzzleSet)
		}
		if (next_index != game.puzzle_index || user_input.reset) {
			game.puzzle_index = next_index
			set_puzzle(&puzzleSet[game.puzzle_index], &world, &next_world, &player)
			world, next_world = next_world, world
			rl.SetWindowTitle(puzzleSet[game.puzzle_index].title)
			state = .Gameplay
		}



		rl.BeginDrawing()
			rl.ClearBackground(rl.PINK)

			rl.BeginMode2D(camera)
		    	draw_world_tiles(&world, tilemap.texture, cell, baseLayerRects, player, false)
		    	draw_world_tiles(&world, tilemap.texture, cell, objectLayerRects, player, true)
		    rl.EndMode2D()

		    if state == GameState.You_Win {
		    	rl.DrawText("you win!", 96, 96, 48, rl.GREEN)
		    }
		    // rl.DrawTexture(tilemap, 0,0,rl.WHITE)
		rl.EndDrawing()
	}
}











