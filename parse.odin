package sokoban

import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"
import "core:path/filepath"





get_set_title :: proc(filename: string) -> string {
	name := filepath.stem(filename)
	start := 0
	if strings.has_prefix(name, "_") do start = 4
	return name[start:]
}

check_prefixes :: proc(line: string, prefixes: []string) -> bool {
	for prefix in prefixes {
		if strings.has_prefix(line, prefix) {
			return true
		}
	}
	return false
}

read_puzzle_file :: proc(filepath: string, allocator := context.temp_allocator) -> []Puzzle {
	puzzle_line_prefixes: []string = {
	" ","-", "_", "#", "@", "$", "*","."
	}

	puzzle_title_prefixes: []string = {
		`'`, `"`
	}

	ParsingState :: enum {
		notes,
		puzzleInit,
		puzzleRead,
	}

    text, ok := os.read_entire_file(filepath, allocator)
    if !ok {
        panic(strings.concatenate({"Unable to read ", filepath}, allocator))
    }

	it := strings.concatenate({ string(text), "\n\n\n" }, allocator)

	// set : Set = {}

	set : [dynamic]Puzzle = {}
	set_title : string
	puzzle_title: string
	lines: [dynamic]string = make([dynamic]string, allocator)
	set_index: string

	// {
	// 	ss := strings.split(filepath, "/")
	// 	set_title = get_set_title(ss[len(ss) - 1])
	// 	delete(ss)
	// }
	set_title = get_set_title(filepath)


	state : ParsingState = .notes
	


	puzzle_index : int = 1

	for line in strings.split_lines_iterator(&it) {
		if check_prefixes(line, puzzle_title_prefixes) {
			state = .puzzleInit
		} else if check_prefixes(line, puzzle_line_prefixes) {
			state = .puzzleRead
		}

		switch(state) {
			case .notes:
				if strings.has_prefix(line, ";") {
					// trim := strings.trim_left(line, "; ")
					// append(&set.notes, trim)
					// delete (trim)
				} else {
					state = .puzzleInit
				}
			case .puzzleInit:
				if check_prefixes(line, puzzle_title_prefixes) {
					puzzle_title = strings.trim_right_space(line)
				}
				// buf: [64]u8 = ---
				// set_index = strconv.itoa(buf[:], puzzle_index)
				set_index = fmt.tprintf("%v", puzzle_index)

			case .puzzleRead:
				if len(line) == 0 {
					// fmt.println("ok")
					puzzle := puzzle_from_prepuzzle(set_title, puzzle_title, set_index, lines[:])
					append(&set, puzzle)
					puzzle_index += 1
					clear_dynamic_array(&lines)
					state = .puzzleInit
				} else {
					trim := strings.trim_right_space(line)
					append(&lines, trim)
					// delete(trim)
				}
		}

	}
	return set[:]
}





puzzle_from_prepuzzle :: proc(set_title: string, puzzle_title: string, set_index: string, lines: []string, ) -> Puzzle {
	combine: string = strings.join(lines[:], "\n")
	defer delete(combine)

	titlebar: string = strings.concatenate({set_title, " #", set_index, "  ", puzzle_title })
	defer delete(titlebar)

	puzzle: Puzzle = {
		title = to_cstring(puzzle_title),
		title_bar = to_cstring(titlebar),
		tiles = fmt.tprintf("%v", combine)
	}
	measure_puzzle(&puzzle)
	return puzzle
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

readNotes :: proc() -> string {
	notes := string {}
	return notes
}



set_puzzle :: #force_inline proc(_puzzle: Puzzle, world: ^World, next_world: ^World, player: ^Player, record: ^Record) -> Puzzle {

	puzzle := _puzzle
	delete(record.moves)
	record^ = Record{}

	for tile, index in next_world.tiles {
		next_world.tiles[index] = Tile.Void
	}


	x, y : i32
	puzzle.worldOrigin = { (world.width - puzzle.width) / 2, (world.height - puzzle.height) / 2 }
	initX, initY := puzzle.worldOrigin.x, puzzle.worldOrigin.y
	x, y = initX, initY


	boxes := 0
	goals := 0

	for tile in puzzle.tiles {
		switch tile {
			case '\n', '|':
				y += 1
				x = initX
			case '-','_':
				next_world.tiles[y * world.width + x] = Tile.Void
				x += 1
			case '#':
				next_world.tiles[y * world.width + x] = Tile.Wall
				x += 1
			case '@':
				player^ = {x, y, .resting, .up}
				next_world.tiles[y * world.width + x] = Tile.Player
				x += 1
			case '+':
				player^ = {x, y, .resting, .up}
				next_world.tiles[y * world.width + x] = Tile.PlayerOnGoal
				x += 1
				goals += 1
			case '$':
				next_world.tiles[y * world.width + x] = Tile.Box
				x += 1
				boxes += 1
			case '*':
				next_world.tiles[y * world.width + x] = Tile.BoxOnGoal
				x += 1
				boxes += 1
				goals += 1
			case '.':
				next_world.tiles[y * world.width + x] = Tile.Goal
				x += 1
				goals += 1
			case ' ':
				next_world.tiles[y * world.width + x] = Tile.Floor
				x += 1
		}
	}

	flood_fill(
		initX - 1, initY - 1,
		initX - 1, initX + puzzle.width + 1,
		initY - 1, initY + puzzle.height + 2,
		next_world,
		Tile.Void2,
		{Tile.Floor, Tile.Void})

	flood_fill(
		initX - 1, initY - 1,
		initX - 1, initX + puzzle.width + 1,
		initY - 1, initY + puzzle.height + 2,
		next_world,
		Tile.Void,
		{Tile.Void2})


	if (boxes != goals) {
		puzzle.probably_unwinnable = true
	}

	return puzzle
}

flood_fill :: proc(x:i32, y:i32, minX:i32, maxX:i32, minY:i32, maxY:i32, world: ^World, set: Tile, inside: []Tile) {
	// fmt.println("attempting flood fill")
	if x < minX || x > maxX || y < minY || y > maxY do return
	tile := world.tiles[y * world.width + x] 
	// if tile == set do return

	isInside : bool
	for ins in inside {
		if tile == ins do isInside = true
	}
	if !isInside do return

	world.tiles[y * world.width + x] = set
	// fmt.printfln("set:", x, y)

	flood_fill(x, y + 1, minX, maxX, minY, maxY, world, set, inside)
	flood_fill(x, y - 1, minX, maxX, minY, maxY, world, set, inside)
	flood_fill(x - 1, y, minX, maxX, minY, maxY, world, set, inside)
	flood_fill(x + 1, y, minX, maxX, minY, maxY, world, set, inside)
}













