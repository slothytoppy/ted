//+private
package renderer

import "core:log"
import "core:slice"
import "core:strconv"

format_line_num :: proc(#any_int line_num: int) -> string {
	s := make([dynamic]byte, 6)
	slice.fill(s[:], 32)

	line_str := strconv.itoa(s[:], line_num)
	line_len := len(line_str)

	if line_len >= len(s) {
		return string(s[:])
	}

	right := len(s) - 1 - 1
	left := line_len - 1

	for {
		slice.swap(s[:], left, right)
		if left == 0 {
			s[saturating_sub(len(s), 1, 0)] = 32
			break
		}
		right -= 1
		left -= 1
	}

	log.debug(s[:])
	return string(s[:])
}

RenderCell :: struct {
	datum: rune,
}

RenderBuffer :: struct {
	cells: [dynamic]RenderCell,
}

_width := 0
_height := 0

render_buffer: [2]RenderBuffer

saturating_sub :: proc(value, amount, min: $T) -> T {
	if value > 0 && value - amount > min {
		return value - amount
	}
	return min
}

get_diffs :: proc() -> [dynamic]Changed {
	changed_cells: [dynamic]Changed
	for cell, i in render_buffer[0].cells {
		y := i / _width
		x := i % _width
		prev_cell := render_buffer[1].cells[i]
		if cell != prev_cell {
			append(&changed_cells, Changed{cell, x, y})
		}
	}
	log.debug(changed_cells)
	return changed_cells
}

Changed :: struct {
	datum: RenderCell,
	x:     int,
	y:     int,
}
