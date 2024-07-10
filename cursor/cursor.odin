package cursor

import "core:log"
import "core:testing"

Error :: enum {
	none,
	invalid,
}

Cursor :: struct {
	row, col:         u16,
	max_row, max_col: u16,
}

Cursor_Command :: enum {
	left,
	right,
	up,
	down,
}

new :: proc() -> Cursor {
	return {}
}

@(private)
move_left :: proc(cursor: ^Cursor, amount: u16) -> Error {
	cursor.row -= amount
	cursor.row = clamp(cursor.row, 0, cursor.max_row)
	return .none
}

@(private)
move_right :: proc(cursor: ^Cursor, amount: u16) -> Error {
	cursor.row += amount
	cursor.row = clamp(cursor.row, 0, cursor.max_row)
	return .none
}

@(private)
move_up :: proc(cursor: ^Cursor, amount: u16) -> Error {
	cursor.col -= amount
	cursor.col = clamp(cursor.col, 0, cursor.max_col)
	return .none
}

@(private)
move_down :: proc(cursor: ^Cursor, amount: u16) -> Error {
	cursor.col += amount
	cursor.col = clamp(cursor.col, 0, cursor.max_col)
	return .none
}

move :: proc(cursor: ^Cursor, command: Cursor_Command) -> (err: Error) {
	switch (command) {
	case .left:
		if cursor.row - 1 > 0 {
			cursor.row -= 1
		}
	case .right:
		if cursor.row + 1 < cursor.max_row {
			cursor.row += 1
		}
	case .up:
		if cursor.col - 1 < cursor.max_col && cursor.col > 0 {
			cursor.col -= 1
		}
	case .down:
		if cursor.col + 1 < cursor.max_col {
			cursor.col += 1
		}
	}
	return .none
}

move_to_line_start :: proc(cursor: ^Cursor, col: u16) {
	cursor.row = 0
	cursor.col = col
}

move_to_line_end :: proc(cursor: ^Cursor, col: u16) {
	cursor.row = cursor.max_row - 1
	cursor.col = col
}
