package sokoban

File :: struct {
	title: string,
	notes: string,
	puzzles: [dynamic]Puzzle,
}

Puzzle :: struct {
	title: cstring,
	notes: cstring,
	snapshots: [dynamic]Snapshot,
	tiles: []u8,
	width: i32,
	height: i32,
}



Snapshot :: struct {
	title: string,
	notes: string,
}


readPuzzleString :: proc(puzzlestring: string, _title: cstring) -> Puzzle {
	puzzle: Puzzle = {
		title = _title,
		tiles = transmute([]u8)string(puzzlestring)
	}
	measure_puzzle(&puzzle)
	return puzzle
}

// Notes :: struct {
// 	contents: string,
// }

readPuzzleFile :: proc() -> File {
	file := File{}
	file.notes = readNotes()

	// for ; found-puzzle-board

	return file
}

readNotes :: proc() -> string {
	notes := string {}
	return notes
}