package cursor

import "../deps/ncurses"
import "core:log"

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
	column_top,
	column_end,
	row_start,
	row_end,
	reset,
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
		if cursor.row > 0 {
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
	case .row_start:
		cursor.row = 0
	case .row_end:
		cursor.row = cursor.max_row - 1
	case .column_top:
		cursor.col = 0
	case .column_end:
		cursor.col = cursor.max_col - 1
	case .reset:
		cursor.row = 0
		cursor.col = 0
	}
	ncurses.move(auto_cast cursor.col, auto_cast cursor.row)
	log.info(cursor.row, cursor.col)
	return .none
}

move_to :: proc(cursor: ^Cursor, x, y: u16) {
	if x < 0 || x > cursor.max_row || y < 0 || y > cursor.max_row {
		return
	}
	ncurses.move(auto_cast x, auto_cast y)
}

move_to_line_start :: proc(cursor: ^Cursor, col: u16) {
	move_to(cursor, cursor.col, 0)
}

move_to_line_end :: proc(cursor: ^Cursor, col: u16) {
	move_to(cursor, cursor.col, cursor.max_row - 1)
}
