package editor

import "../todin"
import "core:log"

render_buffer_line :: proc(line: Line, viewport: Viewport, #any_int tab_width: i32) {
	for cell, idx in line {
		if cast(i32)idx > viewport.max_x {
			break
		}
		switch cell.datum {
		// for not printing newlines, it interferes with rendering the actual text
		case '\n':
		case '\t':
			// TODO: make this configurable
			for i in 0 ..< tab_width {
				todin.print(" ")
			}
		case:
			todin.print(rune(cell.datum))
		}
	}
}

render_buffer_with_scroll :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()
	for line_idx, i in viewport.scroll ..= viewport.max_y + viewport.scroll - 1 {
		if line_idx >= saturating_sub(cast(i32)len(buff), 1, 0) || cast(i32)i >= viewport.max_y {
			break
		}
		todin.print(line_idx)
		render_buffer_line(buff[line_idx], viewport, 4)
		todin.move_to_start_of_next_line()
	}
}

render_bytes_with_scroll :: proc(slice: [][]byte, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()
	line: int
	for i in viewport.scroll ..= viewport.max_y + viewport.scroll - 1 {
		for datum, j in slice[i] {
			todin.print(rune(datum))
			if datum == '\n' {
				line += 1
				todin.move_to_start_of_next_line()
				break
			}
		}
	}
}
