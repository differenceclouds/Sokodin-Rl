package sokoban


import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import rl "vendor:raylib"

//memory debug imports
import "core:log"
import "core:mem"



DEBUG_MEM :: true

Window :: struct { 
	title:          cstring,
	width:         i32, 
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
	resize_flag: bool,
}

World :: struct {
	width:   i32,
	height:  i32,
	tiles:   []Tile,

}

Puzzle :: struct {
	title: cstring,
	title_bar: cstring,
	tiles: string,
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

	tilemap_inc: bool,
	tilemap_dec: bool,
}





draw_world_tiles :: #force_inline proc(world: World, tilemap: Tilemap, rects: [64]rl.Rectangle, player: Player, processPlayer: bool) {
	x, y : i32

	

	for y = 0; y < world.height; y += 1 {
		for x = 0; x < world.width; x += 1 {
			
			index := y * world.width + x
			tileType := world.tiles[index]

			source_rect: rl.Rectangle
			if tileType == .Wall && tilemap.options.drawBlobWalls {

			} else {
				source_rect = rects[tileType]
			}

			rotation:f32 = 0
			
			if processPlayer && (tileType == .Player || tileType == .PlayerOnGoal) {
				switch tilemap.options.playerTileStyle {
					case .TwoTile:
					case .SingleTile: 
					case .FourTileDirectional: 
					case .EightTileDirectional:
						restingPose: bool
						if tilemap.options.defaultPlayerOnRest && player.state == .resting {
							restingPose = true
						}
						if !restingPose {
							if tileType == .Player {
								source_rect = rects[14 + int(player.direction)]
							} else if tileType == .PlayerOnGoal {
								source_rect = rects[18 + int(player.direction)]
							}
						}

					case .SingleDirectionWithPoses: 
						source_rect = rects[8 + int(player.state)]
					case .TwoDirectionWithPoses, .FourDirectionWithPoses:
						source_rect = rects[22 + 6 * int(player.direction) + int(player.state)]

				}
				if !tilemap.options.fixedPlayerRotation do rotation += f32(player.direction) * 90

				if tilemap.options.mirrorPlayerSprites {
					if player.direction == .left do source_rect.width *= -1
					else if player.direction == .down do source_rect.height *= -1
				}
				// source_rect.x += f32((rand.float32() - 0.5) * 100) * source_rect.width
				// source_rect.y += f32((rand.float32() - 0.5) * 100) * source_rect.width
			}



			dest_rect := rl.Rectangle {
				f32(x) * tilemap.w,
				f32(y) * tilemap.h,
				tilemap.w,
				tilemap.h,
			}

			color := rl.WHITE
			if source_rect == {} do color = rl.BLANK

			// if !tilemap.options.singleLayer {
			// 	b_source: rl.Rectangle
			// 	switch tileType {
			// 		case .Void:
			// 		case .Wall, .Box, .Player:
			// 			b_source 
			// 		case .PlayerOnGoal:
			// 		case .BoxOnGoal:
			// 		case .Goal:
			// 		case .Floor:
			// 		case .Void2:
			// 	}
			// }

			rl.DrawTexturePro(tilemap.texture, source_rect, dest_rect, {tilemap.w/2,tilemap.h/2}, rotation, color)				
		}
	}
}

drawtile :: proc() {

}

check_for_win :: proc(world: World) -> bool {
	boxes := 0
	goals := 0
	boxesOnGoals := 0
	for y:i32 = 0; y < world.height; y += 1 {
		for x:i32 = 0; x < world.width; x += 1 {
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

		tilemap_inc = rl.IsKeyPressed(.PERIOD),
		tilemap_dec = rl.IsKeyPressed(.COMMA)
	}
}



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





UpdateWindowTitle :: proc(title:cstring, window: ^Window) {
	window.title = title
	rl.SetWindowTitle(title)
}

SetCamera :: proc(camera: ^rl.Camera2D, window: Window, world: World, tilemap: Tilemap) {
	camera.target = {f32(world.width) / 2.0 * tilemap.w,f32(world.height)/2 * tilemap.h}
	camera.offset = {f32(window.width) / 2.0, f32(window.height) / 2.0}
	if tilemap.options.defaultZoom > 0 do camera.zoom = tilemap.options.defaultZoom
	else {
		if tilemap.w <= 32 do camera.zoom = 2
		else do camera.zoom = 1
	}
}




// run_game :: proc(tracking_allocator : mem.Tracking_Allocator) {
run_game :: proc() {
// main :: proc() {
	window := Window{"Welcome to the Sokoban", 960, 720, 60, rl.ConfigFlags{.WINDOW_RESIZABLE }, false}

	rl.ChangeDirectory(rl.GetApplicationDirectory())
	rl.InitWindow(window.width, window.height, window.title)
	// rl.ToggleBorderlessWindowed()
	// rl.SetWindowSize(960,720)
	// rl.SetWindowPosition(100, 100)
	rl.SetWindowState( window.control_flags )
	rl.SetTargetFPS(window.fps)
	rl.GuiLoadStyle("./rgui/style_sunny.old.rgs")
	rl.InitAudioDevice()

	Sounds : []rl.Sound = {
		rl.LoadSound("./sounds/chip/bummer.wav"),
		rl.LoadSound("./sounds/chip/exit.wav"),
		rl.LoadSound("./sounds/chip/push.wav"),
		rl.LoadSound("./sounds/chip/socket.wav"),
		rl.LoadSound("./sounds/stone1.wav")
	}

	game := Game {
		pause     = true,
		width     = 64,
		height    = 64,
		state = .Gameplay
	}

	world		:= World{game.width, game.height, make([]Tile, game.width * game.height)}
	next_world	:= World{game.width, game.height, make([]Tile, game.width * game.height)}

	defer delete(world.tiles)
	defer delete(next_world.tiles)

	user_input : User_Input

	initial_player : Player
	player : Player
	record := Record {}
	// defer clear_dynamic_array(&record.moves)
	defer delete(record.moves)



	set_of_sets := GetSetOfSets("levels")
	defer delete(set_of_sets)

	set_index :int
	set_index, game.puzzle_index = SimpleLoad(set_of_sets)
	if set_index == -1  {
		game.puzzle_index = 0
		set_index = 0
		for title, i in set_of_sets {
			if strings.has_suffix(title, "Microban.txt")  do set_index = i
		}
	} else {
		if game.puzzle_index == -1 {
			game.puzzle_index = 0
		} else {
			game.puzzle_index += 1
		}
	}


	puzzle_set := SelectPuzzleSet("levels", set_of_sets[set_index])
	// fmt.println(puzzle_set)

	for pz in puzzle_set {
		fmt.println(pz.title_bar)
	}

	puzzle := set_puzzle(puzzle_set[game.puzzle_index], &world, &next_world, &player, &record)
	defer delete(puzzle_set)


	world, next_world = next_world, world
	UpdateWindowTitle(puzzle.title_bar, &window)

	tilemap_list := make([dynamic]Tilemap)
	LoadVariousTilemaps(&tilemap_list)
	InitSheets("sheets-0", &tilemap_list)
	InitSheets("sheets-1", &tilemap_list)
	InitSheets("sheets-2", &tilemap_list)
	InitSheets("sheets-3", &tilemap_list)

	defer delete(tilemap_list)

	tilemap_index := 0
	tilemap := tilemap_list[tilemap_index]
	tilerenderer := SetTileRenderer(tilemap)

	gui_data := InitGui(set_of_sets, set_index)

	camera : rl.Camera2D
	SetCamera(&camera, window, world, tilemap)

	rest_timer: f32
	hud_timer: f32

	show_hud_message: bool

	for !rl.WindowShouldClose() {
		using game

		if rl.IsWindowResized() || window.resize_flag {
			window.width = rl.GetScreenWidth()
			window.height = rl.GetScreenHeight()
			camera.offset = {f32(window.width/2), f32(window.height/2)}

			window.resize_flag = false
		}


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
						game.moveCount -= 1
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



		//single frame states
		moved := false
		movedBox := false
		movedBoxOntoGoal := false
		justWon := false

		if (player != front && !undo) {
			prevTile := world.tiles[player.y    * world.width + player.x]
			nextTile := world.tiles[front.y 	* world.width + front.x]
			leapTile := world.tiles[leap.y 		* world.width + leap.x]

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
						movedBoxOntoGoal = true
						if check_for_win(world) {
							justWon = true
							state = .YouWin
							// hi_score = DoWin(record, puzzle_index, &game.save)
							SimpleSave(record, puzzle_index, set_of_sets[set_index])	
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

			if (moved) {
				moveCount += 1
				append(&record.moves, possible_move)
			}
		}

 		if movedBoxOntoGoal {
			rl.PlaySound(Sounds[3])
		} else if movedBox {
			rl.PlaySound(Sounds[2])
		}
		else if moved {
			rl.PlaySound(Sounds[4])
		}

		if justWon {
			rl.PlaySound(Sounds[1])
		} else if user_input.reset {
			rl.PlaySound(Sounds[0])
		}


		randomize : bool

		next_index := game.puzzle_index
		if user_input.next_level || (user_input.advance && state == .YouWin) {
			next_index = (next_index + 1) %% len(puzzle_set)
		}
		if user_input.prev_level {
			next_index = (next_index - 1) %% len(puzzle_set)
		}
		if (next_index != game.puzzle_index || user_input.reset) {
			game.puzzle_index = next_index
			if gui_data.randomize {
				randomize = true				
			}
			// SetWindowIcon(tilemap)
			puzzle = set_puzzle(puzzle_set[game.puzzle_index], &world, &next_world, &player, &record)
			world, next_world = next_world, world
			UpdateWindowTitle(puzzle_set[game.puzzle_index].title_bar, &window)
			state = .Gameplay
		}

		if gui_data.change_set {
			if set_index != int(gui_data.set_result) {
				set_index = int(gui_data.set_result)

				game.puzzle_index = 0
				_, p := SimpleLoad(set_of_sets, set_of_sets[set_index])
				if p != -1 {
					game.puzzle_index = p + 1
				}
				delete(puzzle_set)
				puzzle_set = SelectPuzzleSet("./levels/", set_of_sets[set_index])
				puzzle = set_puzzle(puzzle_set[game.puzzle_index], &world, &next_world, &player, &record)
				world, next_world = next_world, world
				UpdateWindowTitle(puzzle.title_bar, &window)
				state = .Gameplay
			}
			gui_data.change_set = false
		}

		tilemap_updated : bool

		do_mix := gui_data.randomize && movedBox

		if gui_data.tilemap_inc || user_input.tilemap_inc {
			tilemap_index = (tilemap_index + 1) %% len(tilemap_list)
			gui_data.tilemap_inc = false
			tilemap_updated = true
		} else if gui_data.tilemap_dec || user_input.tilemap_dec{
			tilemap_index = (tilemap_index - 1) %% len(tilemap_list)
			gui_data.tilemap_dec = false
			tilemap_updated = true

		} else if user_input.up && do_mix {
			tilemap_index = (tilemap_index + 7) %% len(tilemap_list)
			gui_data.tilemap_dec = false
			tilemap_updated = true
		} else if user_input.right && do_mix {
			tilemap_index = (tilemap_index + 6) %% len(tilemap_list)
			gui_data.tilemap_dec = false
			tilemap_updated = true
		} else if user_input.down && do_mix  {
			tilemap_index = (tilemap_index - 7) %% len(tilemap_list)
			gui_data.tilemap_dec = false
			tilemap_updated = true
		} else if user_input.left && do_mix {
			tilemap_index = (tilemap_index - 6) %% len(tilemap_list)
			gui_data.tilemap_dec = false
			tilemap_updated = true

		} else if randomize {
			tilemap_index = int(rand.float32() * 100) %% len(tilemap_list)
			tilemap_updated = true
			randomize = false
		}
		if tilemap_updated {
			tilemap = tilemap_list[tilemap_index]
			tilerenderer = SetTileRenderer(tilemap)
			SetCamera(&camera, window, world, tilemap)
			tilemap_updated = false
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
				if !tilemap.options.singleLayer {
			    	draw_world_tiles(world, tilemap, tilerenderer.baseLayerRects, player, false)
				}
		    	draw_world_tiles(world, tilemap, tilerenderer.objectLayerRects, player, true)
		    rl.EndMode2D()

		    if state == .YouWin {
		    	message := YouWinMessage(len(record.moves))

		    	x := window.width/2 - rl.MeasureText(message, 30)/2
		    	rl.DrawText(message, x - 2, 94, 30, rl.BLACK)
		    	rl.DrawText(message, x, 96, 30, rl.RAYWHITE)

		    	if hi_score {
		    		hs :cstring = "NEW RECORD"
		    		x = window.width / 2 - rl.MeasureText(hs, 30) / 2
		    		rl.DrawText(hs, x - 2, 130, 30, rl.MAGENTA)
		    		rl.DrawText(hs, x, 132, 30, rl.YELLOW)
		    	}
		    }
		    if puzzle.probably_unwinnable {
		    	rl.DrawText(UnsolvableMessage, 22, window.height - 50, 30, rl.BLACK)
		    	rl.DrawText(UnsolvableMessage, 24, window.height - 48, 30, rl.WHITE)
		    }

		    DrawGui(&window, &gui_data)

		    if show_hud_message {
		    	buf: [64]u8 = ---
		    	ss : []string = {
		    		"zoom: ",
		    		strconv.itoa(buf[:], int(camera.zoom * 100) )
		    	}
		    	hud_message := to_cstring(strings.concatenate(ss[:], context.temp_allocator))
		    	
		    	rl.DrawText(hud_message, window.width - 177, 13, 30,  rl.BLACK)
				rl.DrawText(hud_message, window.width - 175, 15, 30,  rl.WHITE)
		    }
			
		rl.EndDrawing()
	}
}

hi_score := false

YW : []string = {"Solved in ",""," moves! Try the next one?"}
YouWinMessage :: proc(moves: int) -> cstring {
	buf: [64]u8 = ---
	YW[1] = strconv.itoa(buf[:], moves )
	m := strings.concatenate(YW[:])
	defer delete(m)
	return to_cstring(m)
}
UnsolvableMessage :: "this puzzle is unsolvable... press ] to skip"


main :: proc() {
    tracking_allocator : mem.Tracking_Allocator
    // when DEBUG_MEM {
        context.logger = log.create_console_logger()
        default_allocator := context.allocator
        mem.tracking_allocator_init(&tracking_allocator, default_allocator)
        context.allocator = mem.tracking_allocator(&tracking_allocator)
        reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
            err := false

            for _, value in a.allocation_map {
                fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
                err = true
            }

            mem.tracking_allocator_clear(a)
            return err
        }
    // }

    // run_game(tracking_allocator)
    run_game()


    when DEBUG_MEM {
        if len(tracking_allocator.bad_free_array) > 0 {
            for b in tracking_allocator.bad_free_array {
                log.errorf("Bad free at: %v", b.location)
            }

            // libc.getchar()
            panic("Bad free detected")
        }
        if reset_tracking_allocator(&tracking_allocator) {
            // libc.getchar()
        }
    }
    mem.tracking_allocator_destroy(&tracking_allocator)
}





