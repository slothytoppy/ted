package todin

import "core:fmt"

reset_cursor :: proc() {
	_buffer.pos = {0, 0}
	//os.write_string(os.stdin, "\e[H")
}

move :: proc(#any_int y, x: i32) {
	_buffer.pos = {
		y = y,
		x = x,
	}
}

move_up :: proc() {
	if _buffer.pos.y > 0 {
		_buffer.pos.y -= 1
	}
	//fmt.printf("\e[1A")
}

move_down :: proc() {
	if _buffer.pos.y < GLOBAL_WINDOW_SIZE.cols - 1 {
		line_amount := cast(i32)len(_buffer.data) - 1
		if line_amount < _buffer.pos.y {
			inject_at(&_buffer.data, cast(int)_buffer.pos.y, Line{})
		}
		_buffer.pos.y += 1
	}
	//fmt.printf("\e[1B")
}

move_right :: proc() {
	if _buffer.pos.x < GLOBAL_WINDOW_SIZE.rows {
		_buffer.pos.x += 1
	}
	//fmt.printf("\e[1C")
}

move_left :: proc() {
	if _buffer.pos.x > 0 {
		_buffer.pos.x -= 1
	}
	//fmt.printf("\e[1D")
}

move_to_start_of_next_line :: proc() {
	move_down()
	_buffer.pos.x = 0
	//fmt.printf("\e[1E")
}

scroll_up :: proc() {
	fmt.printf("\e[1S")
}

scroll_down :: proc() {
	fmt.printf("\e[1T")
}

save_cursor_pos :: proc() {
	fmt.printf("\e[7")
}

restore_cursor_pos :: proc() {
	fmt.printf("\e[8")
}

get_current_cols :: proc() -> i32 {
	columns, _ := get_cursor_pos()
	return cast(i32)columns
}

get_current_rows :: proc() -> i32 {
	_, rows := get_cursor_pos()
	return cast(i32)rows
}

get_cursor_pos :: proc() -> (cols, rows: int) {
	/*
	buf: [20]byte
	os.write_string(os.stdin, "\e[6n")
	os.read(os.stdin, buf[:])
	if string(buf[:2]) != "\e[" {
		panic("could not find the proper escape sequence: \"\\e[\"")
	}
	start, start_idx: int
	for b, i in buf {
		if b == '[' {
			start_idx = i + 1
			break
		}
	}
	i := start_idx
	for b in buf[start_idx:] {
		i += 1
		if b == ';' {
			cols = strconv.atoi(string(buf[start_idx:i]))
			start = i
		} else if b == 'R' {
			rows = strconv.atoi(string(buf[start:i]))
			break
		}
	}
  */
	cols = cast(int)_buffer.pos.y
	rows = cast(int)_buffer.pos.x
	return cols, rows
}

get_max_cols :: proc() -> i32 {
	return GLOBAL_WINDOW_SIZE.cols
}

get_max_rows :: proc() -> i32 {
	return GLOBAL_WINDOW_SIZE.rows
}

get_max_cursor_pos :: proc() -> (max_lines, max_rows: i32) {
	return GLOBAL_WINDOW_SIZE.cols, GLOBAL_WINDOW_SIZE.rows
}
