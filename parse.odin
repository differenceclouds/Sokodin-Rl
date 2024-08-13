package sokoban

import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"


// PreSet :: struct {
// 	title: string,
// 	notes: 
// }

Set :: struct {
	title: string,
	notes: [dynamic]string,
	puzzles: [dynamic]Puzzle,
}

InvalidFile: Set = {
	title = "invalid puzzle set file"
}

PrePuzzle :: struct {
	title: string,
	lines: [dynamic]string,
	set_index: string,
	set_title: string,
}



Snapshot :: struct {
	title: string,
	notes: string,
}

ParsingState :: enum {
	notes,
	puzzleInit,
	puzzleRead,
}

read_puzzle_file :: proc(filepath: string) -> Set {
    text, ok := os.read_entire_file(filepath)
    if !ok {
        panic("Unable to read data.txt")
    }

    it: string
    {
		a := [?]string { string(text), "\n"}
		it = strings.concatenate(a[:])
    }


	set : Set = {}
	
	{
		titlepath := strings.trim_right(filepath, ".txt")
		ss := strings.split(titlepath, "/")
		set.title = ss[len(ss) - 1]
	}


	state : ParsingState = .notes
	
	holdingPuzzle : PrePuzzle = {}

	puzzle_index : int = 1

	for line in strings.split_lines_after_iterator(&it) {
		if check_prefixes(line, puzzle_title_prefixes) {
			state = .puzzleInit
		} else if check_prefixes(line, puzzle_line_prefixes) {
			state = .puzzleRead
		}

		switch(state) {
			case .notes:
				if strings.has_prefix(line, ";") {
					trim := strings.trim_left(line, "; ")
					append(&set.notes, trim)
				} else {
					state = .puzzleInit
				}
			case .puzzleInit:
				if check_prefixes(line, puzzle_title_prefixes) {
					holdingPuzzle.title = line
				}
				holdingPuzzle.set_title = set.title
				buf: [64]u8 = ---
				holdingPuzzle.set_index = strconv.itoa(buf[:], puzzle_index)
			case .puzzleRead:
				if line == "\n" {
					append(&set.puzzles, puzzle_from_prepuzzle(holdingPuzzle))
					puzzle_index += 1
					holdingPuzzle = PrePuzzle {}
					state = .puzzleInit
				} else {
					trim := strings.trim_right_space(line)
					append(&holdingPuzzle.lines, trim)
				}
		}

	}
	return set
}

puzzle_line_prefixes: []string = {
	" ","-", "_", "#", "@", "$", "*","."
}

puzzle_title_prefixes: []string = {
	`'`, `"`
}

puzzle_from_prepuzzle :: proc(pre: PrePuzzle) -> Puzzle {
	combine: string = strings.join(pre.lines[:], "\n")
	titlebaritems := [?]string {pre.set_title, " #", pre.set_index, "  ", pre.title }
	titlebar: string = strings.concatenate(titlebaritems[:])
	// return readPuzzleString(combine, strings.clone_to_cstring(title))
	puzzle: Puzzle = {
		title = strings.clone_to_cstring(pre.title),
		title_bar = strings.clone_to_cstring(titlebar),
		tiles = transmute([]u8)string(combine)
	}
	measure_puzzle(&puzzle)
	return puzzle
}

check_prefixes :: proc(line: string, prefixes: []string) -> bool {
	for prefix in prefixes {
		if strings.has_prefix(line, prefix) {
			return true
		}
	}
	return false
}


// readPuzzleString :: proc(puzzlestring: string, _title: cstring) -> Puzzle {
// 	puzzle: Puzzle = {
// 		title = _title,
// 		tiles = transmute([]u8)string(puzzlestring)
// 	}
// 	measure_puzzle(&puzzle)
// 	return puzzle
// }


readNotes :: proc() -> string {
	notes := string {}
	return notes
}