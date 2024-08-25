package editor

import "../todin"
import "core:log"

render_buffer_line :: proc(line: Line, viewport: Viewport, #any_int tab_width: i32) {
	for cell, idx in line {
		if cast(i32)idx > viewport.max_x {
			break
		}
		switch cell.datum.keyname {
		// for not printing newlines, it interferes with rendering the actual text
		case '\n':
		case '\t':
			// TODO: make this configurable
			for i in 0 ..< tab_width {
				todin.print(" ")
			}
		case:
			todin.print(cell.datum.keyname)
		}
	}
}

render_buffer_with_scroll :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()
	for line_idx, i in viewport.scroll ..= viewport.max_y + viewport.scroll - 1 {
		if line_idx > saturating_sub(cast(i32)len(buff), 1, 0) || cast(i32)i >= viewport.max_y {
			break
		}
		render_buffer_line(buff[line_idx], viewport, 4)
		todin.move_to_start_of_next_line()
	}
}

render :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()

	// subtracting one from scroll and from max_y+scroll makes it so that it only prints one less than max_y, also allows you to not scroll past the end of the file
	for offset, i in saturating_sub(
		viewport.scroll,
		1,
		0,
	) ..= viewport.max_y + viewport.scroll - 1 {
		if offset > saturating_sub(cast(i32)len(buff), 1, 0) || cast(i32)i >= viewport.max_y {
			break
		}
		line := buff[offset]
		for cell, idx in line {
			if cast(i32)idx > viewport.max_x {
				break
			}
			switch cell.datum.keyname {
			// for not printing newlines, it interferes with rendering the actual text
			case '\n':
			case '\t':
				// TODO: make this configurable
				todin.print("    ")
			case:
				todin.print(cell.datum.keyname)
			}
		}
		todin.move_to_start_of_next_line()
	}
}
