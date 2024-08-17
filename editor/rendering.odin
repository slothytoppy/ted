package editor

import "../deps/todin"

render :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()

	idx: int

	if viewport.scroll > 0 && viewport.scroll <= cast(i32)len(buff.metadata.line_end) - 1 {
		idx = cast(int)buff.metadata.line_start[viewport.scroll]
	}

	if idx >= len(buff.data) {
		return
	}

	lines_count: i32 = 0
	// TODO: fix rendering parts of the next line
	for i in idx ..< len(buff.data[:]) {
		if lines_count > viewport.max_y {
			break
		}
		cell := buff.data[i]
		switch cell.datum.keyname {
		case '\n':
			lines_count += 1
			todin.move_to_start_of_next_line()
		case '\t':
			// TODO: make this configurable
			todin.print("   ")
		case:
			todin.print(cell.datum.keyname)
		}
	}
}
