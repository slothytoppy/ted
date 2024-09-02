package editor

import "../todin"
import "core:log"
import "core:strconv"
import "core:strings"

render_buffer_line :: proc(line: Line, viewport: Viewport, #any_int tab_width: i32, offset := 0) {
	for i in 0 ..< offset {
		todin.move_right()
	}
	for cell, idx in line {
		if cast(i32)idx > viewport.max_x - cast(i32)offset {
			break
		}
		switch cell.datum {
		// for not printing newlines, it interferes with rendering the actual text
		case '\n':
			break
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

format_line_num :: proc(#any_int line_num: int) -> string {
	s: [6]byte = 32
	line_str := strconv.itoa(s[:], line_num)
	offset := saturating_sub(len(s), 1, 0)
	s[0] = line_str[0]
	#reverse for r, i in line_str {
		s[offset] = byte(r)
		s[i] = 32
		offset -= 1
	}
	log.info(s)
	return strings.clone(string(s[:]))
}

render_buffer_with_scroll :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()
	offset := 1
	tab_width := 4
	line_num: string
	for line_idx, i in viewport.scroll ..= viewport.max_y + viewport.scroll - 1 {
		if line_idx >= saturating_sub(cast(i32)len(buff), 1, 0) || cast(i32)i >= viewport.max_y {
			break
		}
		line_num = format_line_num(line_idx)
		defer delete(line_num)
		todin.print(line_num, " ")
		render_buffer_line(buff[line_idx], viewport, tab_width, offset)
		todin.move_to_start_of_next_line()
	}
}

render :: proc(editor: Editor) {
	todin.clear_screen()
	todin.reset_cursor()
	y, x :=
		saturating_add(editor.cursor.y, 1, editor.viewport.max_y),
		saturating_add(editor.cursor.x, 1, editor.viewport.max_x)
	render_buffer_with_scroll(editor.buffer, editor.viewport)
	write_status_line(editor.mode, editor.current_file, editor.cursor, editor.viewport.scroll)
	if editor.mode == .command {
		print_command_line(editor.command_line)
	}
	todin.move(y, x)
	todin.refresh()
}
