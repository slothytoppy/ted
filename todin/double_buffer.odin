package todin

import "core:fmt"
import "core:log"
import "core:os"

@(private)
Cell :: struct {
	datum: rune,
	dirty: bool,
}

@(private)
Line :: [dynamic]Cell

@(private)
Position :: struct {
	y, x: i32,
}

@(private)
Buffer :: struct {
	data:  [dynamic]Line,
	pos:   Position,
	dirty: bool,
}

@(private)
_buffer: Buffer

append_rune :: proc(r: rune) {
	_buffer.dirty = true
	if _buffer.pos.y > cast(i32)len(_buffer.data) - 1 {
		inject_at(&_buffer.data, cast(int)_buffer.pos.y, Line{})
	}
	append(&_buffer.data[_buffer.pos.y], Cell{datum = r, dirty = true})
	_buffer.pos.x += 1
}

append_string :: proc(s: string) {
	for r in s {
		append_rune(r)
	}
}

remove_rune :: proc() {
	if len(_buffer.data[_buffer.pos.y]) == 0 ||
	   _buffer.pos.x > cast(i32)len(_buffer.data[_buffer.pos.y]) {
		return
	}
	ordered_remove(&_buffer.data[_buffer.pos.y], cast(int)_buffer.pos.x)
	if _buffer.pos.x - 1 > 0 {
		_buffer.pos.x -= 1
	}
}

refresh :: proc() {
	if _buffer.dirty {
		cell_amount: int
		os.write_string(os.stdin, "\e[H")
		_buffer.dirty = false
		for line in _buffer.data {
			for &cell, i in line {
				if cell.dirty {
					cell_amount += 1
					if cast(i32)i > GLOBAL_WINDOW_SIZE.rows {
						move_to_start_of_next_line()
					}
					os.write_rune(os.stdin, cell.datum)
					cell.dirty = false
				}
			}
			os.write_string(os.stdin, "\e[1E")
		}
		fmt.printf("\e[%d;%dH", _buffer.pos.y, _buffer.pos.x)
		log.info("amount drawn:", cell_amount)
	}
}

@(private)
saturating_sub :: proc(val, amount, min: $T) -> T {
	if val > 0 && val - amount > min {
		return val - amount
	}
	return min
}
