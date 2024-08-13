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

// Move_List :: [dynamic] Move_Direction

// RecordMove :: proc(direction: Move_Direction, moves: Move_List^) {
// 	append(&moves, direction)
// }

Record :: struct {
	// tiles: []u8,
	moves: [dynamic]Move_Type,
	// chars: [dynamic]u8
}

MakeMoveChars :: proc(moves: []Move_Type) -> [dynamic]u8 {
	chars := [dynamic]u8 {}
	for move in moves {
		WriteMoveChar(&chars, move)
	}
	return chars
}

CharFromMove :: proc(move: Move_Type) -> u8 {
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
	return char
}

WriteMoveChar :: proc(move_chars: ^[dynamic]u8, move: Move_Type) {
	char := CharFromMove(move)
	append(move_chars, char)
}






