package sokoban

import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"


Move_Type :: enum {
	Wait,

	up,
	right,
	down,
	left,

	UpBox,
	RightBox,
	DownBox,
	LeftBox

}


Record :: struct {
	moves: [dynamic]Move_Type,
}

RecordData :: struct {
	set_title: string,
	puzzle_index: int,
	chars: []u8,
	tilemap_index: int
}

Save_Location :: "./save_log.txt"

SimpleSave :: proc(record: Record, puzzle_index: int, set_title: string, tilemap_index: int) {
	buf: [64]u8 = ---

	chars := MakeMoveChars(record.moves[:])

	log_entry := strings.concatenate({
		"\r\n",
		";set: ", set_title,
		" ;index: ", fmt.tprint(puzzle_index),
		" ;moves: ", string(chars),
		" ;tilemap: ", fmt.tprint(tilemap_index)
	})

	when ODIN_OS == .Windows {
		f, err := os.open(Save_Location, os.O_CREATE | os.O_APPEND | os.O_WRONLY)
	} else {
		f, err := os.open(Save_Location, os.O_CREATE | os.O_APPEND | os.O_WRONLY, os.S_IRWXU)
	}

	defer os.close(f)
	if err != os.ERROR_NONE {
		fmt.eprintln("Could not read save file", err)
		os.exit(2)
	}
	os.write_string(f, log_entry)
	delete(log_entry)
	delete(chars)

}

SimpleLoad :: proc(set_of_sets: []string, set_select : string = "") -> (set_index: int, puzzle_index: int, tilemap_index: int) {
	s, p, t := -1, -1, 0

	data, ok := os.read_entire_file(Save_Location)
	if !ok {
		return s, p, t
	}
	defer delete(data)


	last_line: string
	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		j := strings.join({";set:", set_select}, " ")
		if strings.has_prefix(line, j) do last_line = line
		delete(j)
	}

	if last_line == "" {
		return -1, -1, 0
	}

	for prop in strings.split(last_line, ";", context.temp_allocator) {
		if strings.has_prefix(prop, "set:") {
			set_title := strings.trim_space(
				strings.trim_prefix(prop, "set:"))
			for title, i in set_of_sets {
				if set_title == title {
					s = i
				}
			}
		}
		if strings.has_prefix(prop, "tilemap:") {
			_tilemap := strings.trim_space(strings.trim_prefix(prop, "tilemap:"))
			if _t, ok3 := strconv.parse_int(_tilemap); ok3 {
				t = _t
			} else {
				fmt.println("bad tile index in save_log.txt")
			}
		}
		if strings.has_prefix(prop, "index:") {
			_title := strings.trim_space(strings.trim_prefix(prop, "index:"))
			ok2 := false
			p, ok2 = strconv.parse_int(_title)
			if !ok2 {
				fmt.printfln("bad level index in save_log.txt")
				return -1, -1, t
			}
		}
	}

	return s, p, t
}



MakeMoveChars :: proc(moves: []Move_Type) -> []u8 {
	chars := make([]u8, len(moves))
	for move, i in moves {
		char: u8
		switch move {
			case .Wait: 	char = 'W'
			case .up: 		char = 'u'
			case .right: 	char = 'r'
			case .down: 	char = 'd'
			case .left: 	char = 'l'
			case .UpBox: 	char = 'U'
			case .RightBox: char = 'R'
			case .DownBox: 	char = 'D'
			case .LeftBox: 	char = 'L'
		}
		chars[i] = char
	}
	return chars[:]
}






