package editor

import "../deps/todin"
import "core:log"

render :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()

	// subtracting one from scroll and from max_y+scroll makes it so that it only prints one less than max_y, also allows you to not scroll past the end of the file
	for offset in saturating_sub(viewport.scroll, 1, 0) ..= viewport.max_y + viewport.scroll - 1 {
		if offset > cast(i32)len(buff.data) - 1 {
			break
		}
		line := buff.data[offset]
		for cell, idx in line {
			if cast(i32)idx > viewport.max_x {
				break
			}
			switch cell.datum.keyname {
			case '\n':
				todin.move_to_start_of_next_line()
			case '\t':
				// TODO: make this configurable
				todin.print("    ")
			case:
				todin.print(cell.datum.keyname)
			}
		}
	}
}
