package sokoban

import "core:fmt"
import "core:strings"
import "core:strconv"
import rl "vendor:raylib"


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

Puzzle :: struct {
	title: cstring,
	title_bar: cstring,
	tiles: []u8,
	width: i32,
	height: i32,
	probably_unwinnable: bool,

	worldOrigin: Coord,
}

Cell :: struct { 
	width:  f32,
	height: f32,
}

Coord :: struct {
	x: i32,
	y: i32,
}


Game :: struct {
	pause:		bool,
	width:		i32,
	height:		i32,
	state:		GameState,
	puzzle_index: int,
	moveCount: int,

}

GameState :: enum {
	Gameplay,
	YouWin,
	SetSelect,

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

	zoom_in: bool,
	zoom_out: bool,
}





draw_world_tiles :: #force_inline proc(world: ^World, tilemap: Tilemap, options: TileRendererOptions, rects: []rl.Rectangle, player: Player, processPlayer: bool) {
	x, y : i32
	for y = 0; y < world.height; y += 1 {
		for x = 0; x < world.width; x += 1 {
			index := y * world.width + x
			source_rect := rects[world.tiles[index]]

			rotation:f32 = 0
			if processPlayer && (world.tiles[index] == Tile.Player || world.tiles[index] == Tile.PlayerOnGoal) {
				source_rect = rects[8 + int(player.state)]
				if !options.fixedPlayerRotation do rotation += f32(player.direction) * 90
			}

			dest_rect := rl.Rectangle {
				f32(x) * tilemap.w,
				f32(y) * tilemap.h,
				tilemap.w,
				tilemap.h,
			}
			rl.DrawTexturePro(tilemap.texture, source_rect, dest_rect, {tilemap.w/2,tilemap.h/2}, rotation, rl.WHITE)
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

set_puzzle :: #force_inline proc(_puzzle: Puzzle, world: ^World, next_world: ^World, player: ^Player, record: ^Record) -> Puzzle {

	puzzle := _puzzle

	clear(&record.moves)

	for tile, index in next_world.tiles {
		next_world.tiles[index] = Tile.Void
	}

	x, y : i32
	puzzle.worldOrigin = { (world.width - puzzle.width) / 2, (world.height - puzzle.height) / 2 }
	initX, initY := puzzle.worldOrigin.x, puzzle.worldOrigin.y
	x, y = initX, initY

	encountered_tile_on_row := false

	boxes := 0
	goals := 0

	for tile in puzzle.tiles {
		switch tile {
			case '\n', '|':
				y += 1
				x = initX
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
				goals += 1
			case '$':
				next_world.tiles[y * world.width + x] = Tile.Box
				encountered_tile_on_row = true
				x += 1
				boxes += 1
			case '*':
				next_world.tiles[y * world.width + x] = Tile.BoxOnGoal
				encountered_tile_on_row = true
				x += 1
				boxes += 1
				goals += 1
			case '.':
				next_world.tiles[y * world.width + x] = Tile.Goal
				encountered_tile_on_row = true
				x += 1
				goals += 1
			case ' ':
				if (encountered_tile_on_row) {
					next_world.tiles[y * world.width + x] = Tile.Floor
				} else {
					next_world.tiles[y * world.width + x] = Tile.Void
				}
				
				x += 1
		}
	}

	if (boxes != goals) {
		puzzle.probably_unwinnable = true
	}

	return puzzle
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

		zoom_in 	= rl.IsKeyPressed(.EQUAL),
		zoom_out 	= rl.IsKeyPressed(.MINUS),

		undo 		= rl.IsKeyPressed(.Z),
	}
}



// do_move :: proc(move: Move_Type, _player: Player, world: ^World) -> (new_player: Player) {

// }



reverse_move :: proc(move: Move_Type, _player: Player, world: ^World) -> (new_player: Player, ok: bool) {
	player := _player
	front := player
	rear := player

	movedBox: bool

	switch move {
		case .Wait:
		case .up, .UpBox:
			front.y -= 1
			rear.y += 1
			player.direction = .up
			rear.direction = .up
		case .right, .RightBox:
			front.x += 1
			rear.x -= 1
			player.direction = .right
			rear.direction = .right
		case .down, .DownBox:
			front.y += 1
			rear.y -= 1
			player.direction = .down
			rear.direction = .down
		case .left, .LeftBox:
			front.x -= 1
			rear.x += 1
			player.direction = .left
			rear.direction = .left
	}
	#partial switch move {
		case .UpBox, .RightBox, .DownBox, .LeftBox: movedBox = true
	}

	currTile := world.tiles[player.y    * world.width + player.x]
	frontTile := world.tiles[front.y 	* world.width + front.x]
	rearTile := world.tiles[rear.y 	* world.width + rear.x]


	if rearTile == Tile.Floor 				do world.tiles[rear.y * world.width + rear.x] = Tile.Player
	else if rearTile == Tile.Goal 			do world.tiles[rear.y * world.width + rear.x] = Tile.PlayerOnGoal
	else do return player, false

	if !movedBox {
		if 		currTile == .Player 		do world.tiles[player.y * world.width + player.x] = .Floor
		else if currTile == .PlayerOnGoal 	do world.tiles[player.y * world.width + player.x] = .Goal
		else do return player, false
	} else {
		if 		currTile == .Player 		do world.tiles[player.y * world.width + player.x] = .Box
		else if currTile == .PlayerOnGoal 	do world.tiles[player.y * world.width + player.x] = .BoxOnGoal
		else do return player, false

		if 		frontTile == .Box 			do world.tiles[front.y * world.width + front.x] = .Floor
		else if frontTile == .BoxOnGoal 	do world.tiles[front.y * world.width + front.x] = .Goal
		else do return player, false
	}
	return rear, true
}


main :: proc() {
	window := Window{"Welcome to the Sokoban", 960, 720, 60, rl.ConfigFlags{ }}

	rl.ChangeDirectory(rl.GetApplicationDirectory())
	rl.InitWindow(window.width, window.height, window.name)
	rl.SetWindowState( window.control_flags )
	rl.SetTargetFPS(window.fps)

	puzzle_file := read_puzzle_file("./levels/Sasquatch.txt")

	puzzleSet := puzzle_file.puzzles

	// puzzleSet : []Puzzle = {
	// 	readPuzzleString(simplestpuzzle, "simplest possible sokoban"),
	// 	readPuzzleString(claire, "Claire, by Lee J Haywood"),
	// 	readPuzzleString(coffeepuzzle, "coffe sokoban"),
	// 	readPuzzleString(courtyard, "courtyard")
	// }

	// for board, index in puzzleSet {
	// 	fmt.print(board.title)
	// }


	game := Game {
		pause     = true,
		width     = 64,
		height    = 64,
		state = .Gameplay
	}

	world			:= World{game.width, game.height, make([]Tile, game.width * game.height)}
	next_world		:= World{game.width, game.height, make([]Tile, game.width * game.height)}

	defer delete(world.tiles)
	defer delete(next_world.tiles)

	user_input : User_Input

	initial_player : Player
	player : Player

	
	record := Record {}

	puzzle := set_puzzle(puzzleSet[game.puzzle_index], &world, &next_world, &player, &record)
	world, next_world = next_world, world
	rl.SetWindowTitle(puzzle.title_bar)

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
		rl.LoadTexture("./tilesets/Sokoban Perfect.png"),
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

	sneezingTiger := Tilemap {
		rl.LoadTexture("./tilesets/sneezing_tiger.png"),
		16, 16,
		0, 0,
		{
			{0,0},
			{6,0},
			{2,7},
			{3,7},
			{0,7},
			{1,7},
			{4,7},
			{0,6},

			{2,7},
			{2,7},
			{2,7},
			{2,7},
			{2,7},
			{2,7},
		}

	}

	tilemap := shoveIt

	// tilerenderer := SetTileRenderer(tilemap, {disableVoidTile = false, floorTileAsVoid = true, fixedPlayerRotation = true})
	tilerenderer := SetTileRenderer(tilemap, {})



	camera : rl.Camera2D
	camera.target = {f32(world.width) / 2.0 * tilemap.w,f32(world.height)/2 * tilemap.h}
	camera.offset = {f32(window.width) / 2.0, f32(window.height) / 2.0}
	camera.zoom = 2.0




	rest_timer: f32
	hud_timer: f32

	show_hud_message: bool

	for !rl.WindowShouldClose() {
		using game

		process_user_input(&user_input, window, world)

		
		if player.state != .resting {
			rest_timer += rl.GetFrameTime()
			if(rest_timer >= 1) {
				player.state = .resting
			}
		}
		

		if(show_hud_message) {
			hud_timer += rl.GetFrameTime()
			if(hud_timer >= 1) {
				show_hud_message = false
			}
		}


		front := player
		leap := player

		possible_move : Move_Type

		undo: bool

		if (state == GameState.Gameplay) {

			if user_input.left {
				front.x -= 1
				leap.x -= 2
				player.direction = .left
				front.direction = .left
				possible_move = Move_Type.left
			}
			else if user_input.right {
				front.x += 1
				leap.x += 2
				player.direction = .right
				front.direction = .right
				possible_move = Move_Type.right
			}
			else if user_input.up {
				front.y -= 1
				leap.y -= 2
				player.direction = .up
				front.direction = .up
				possible_move = Move_Type.up
			}
			else if user_input.down {
				front.y += 1
				leap.y += 2
				player.direction = .down
				front.direction = .down
				possible_move = Move_Type.down
			}
			else if user_input.undo {
				m, ok := pop_safe(&record.moves)
				if ok {
					undo = true
					new_player, success := reverse_move(m, player, &world)
					if success {
						player = new_player
					} else {
						fmt.printf("Invalid Undo")
					}
				} 
			}


			if user_input.zoom_in {
				if camera.zoom < 1 {
					camera.zoom = clamp(camera.zoom + 0.25, 0.5, 10)
				} else {
					camera.zoom = clamp(camera.zoom + 0.5, 0.50, 10)
				}
				hud_timer = 0
				show_hud_message = true
			}
			else if user_input.zoom_out {
				if camera.zoom <= 1 {
					camera.zoom = clamp(camera.zoom - 0.25, 0.25, 10)
				} else {
					camera.zoom = clamp(camera.zoom - 0.5, 0.25, 10)
				}
				hud_timer = 0
				show_hud_message = true
			}
		}


		if (player != front && !undo) {
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
				
				if moveCount % 2 == 0 {
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
							state = .YouWin
						}
				}
				if moveCount % 2 == 0 {
					player.state = .pushingEven
					rest_timer = 0
				} else {
					player.state = .pushingOdd
					rest_timer = 0
				}

				#partial switch possible_move {
					case .up: 		possible_move = .UpBox
					case .right: 	possible_move = .RightBox
					case .down: 	possible_move = .DownBox
					case .left: 	possible_move = .LeftBox
				}

			}

			if (moved || movedBox) {
				moveCount += 1
				append(&record.moves, possible_move)
				// chars := MakeMoveChars(record.moves[:])
				// fmt.println(strings.clone_from_bytes(chars[:]))
			}
		}



		next_index := game.puzzle_index
		if user_input.next_level || (user_input.advance && state == .YouWin) {
			next_index = (next_index + 1) %% len(puzzleSet)
		}
		if user_input.prev_level {
			next_index = (next_index - 1) %% len(puzzleSet)
		}
		if (next_index != game.puzzle_index || user_input.reset) {
			game.puzzle_index = next_index
			puzzle = set_puzzle(puzzleSet[game.puzzle_index], &world, &next_world, &player, &record)
			world, next_world = next_world, world
			rl.SetWindowTitle(puzzleSet[game.puzzle_index].title_bar)
			state = .Gameplay
		}
		
		//move camera
		{
			world_center : rl.Vector2 = {f32(world.width)/2, f32(world.height)/2}
			if puzzle.width % 2 != 0 {
				world_center.x -= 0.5
			}
			if puzzle.height % 2 == 0 {
				world_center.y += 0.5
			}

			if f32(window.width) > f32(puzzle.width + 2) * tilemap.w * camera.zoom {
				camera.target.x = world_center.x * tilemap.w
			} else {
				playerX:f32 = (f32(player.x) + 0.5) * tilemap.w
				minX:f32 = (f32(puzzle.worldOrigin.x) - 1.5) * tilemap.w + (camera.offset.x / camera.zoom)
				maxX:f32 = (f32(puzzle.worldOrigin.x + puzzle.width + 1) + 0.5) * tilemap.w - (camera.offset.x / camera.zoom)
				camera.target.x = clamp(playerX, minX, maxX)
			}
			if f32(window.height) > f32(puzzle.height + 2) * tilemap.h * camera.zoom {
				camera.target.y = world_center.y * tilemap.h
			} else {
				playerY:f32 = (f32(player.y) + 0.5) * tilemap.h
				minY:f32 = (f32(puzzle.worldOrigin.y) - 1.5) * tilemap.h + (camera.offset.y / camera.zoom)
				maxY:f32 = (f32(puzzle.worldOrigin.y + puzzle.height) + 2.5) * tilemap.h - (camera.offset.y / camera.zoom)
				camera.target.y = clamp(playerY, minY, maxY)
			}
		}

		rl.BeginDrawing()
			rl.ClearBackground(rl.PINK)


			rl.BeginMode2D(camera)
		    	draw_world_tiles(&world, tilemap, tilerenderer.options, tilerenderer.baseLayerRects, player, false)
		    	draw_world_tiles(&world, tilemap, tilerenderer.options, tilerenderer.objectLayerRects, player, true)
		    rl.EndMode2D()

		    if state == .YouWin {
		    	rl.DrawText(YouWinMessage, 94, 94, 30, rl.BLACK)
		    	rl.DrawText(YouWinMessage, 96, 96, 30, rl.GREEN)
		    }
		    if puzzle.probably_unwinnable {
		    	rl.DrawText(UnsolvableMessage, 22, window.height - 50, 30, rl.BLACK)
		    	rl.DrawText(UnsolvableMessage, 24, window.height - 48, 30, rl.WHITE)
		    }

		    if state == .SetSelect {

		    }

		    // draw_gui(window)

		    if show_hud_message {
		    	buf: [64]u8 = ---
		    	ss : []string = {
		    		"zoom: ",
		    		strconv.itoa(buf[:], int(camera.zoom * 100) )
		    	}
		    	hud_message := strings.clone_to_cstring(strings.concatenate(ss[:]))
		    	rl.DrawText(hud_message, window.width - 177, 13, 30,  rl.BLACK)
				rl.DrawText(hud_message, window.width - 175, 15, 30,  rl.WHITE)
		    }
			
		rl.EndDrawing()
	}
}


YouWinMessage :: "Solved it! Try the next one?"
UnsolvableMessage :: "this puzzle is unsolvable... press ] to skip"








