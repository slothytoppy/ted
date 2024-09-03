package editor

import "../todin"
import "core:log"
import "core:slice"
import "core:strconv"

render_buffer_line :: proc(
	line: Line,
	viewport: Viewport,
	#any_int tab_width: i32,
	cursor: Cursor = {},
) {
	for _ in 0 ..< cursor.y {
		todin.move_to_start_of_next_line()
	}
	for _ in 0 ..< cursor.x {
		todin.move_right()
	}
	for cell, idx in line {
		if cast(i32)idx > viewport.max_x - cursor.x {
			break
		}
		switch cell.datum {
		// for not printing newlines, it interferes with rendering the actual text
		case '\n':
			break
		case '\t':
			// TODO: make this configurable
			for _ in 0 ..< tab_width {
				todin.print(" ")
			}
		case:
			todin.print(rune(cell.datum))
		}
	}
}

format_line_num :: proc(#any_int line_num: int) -> string {
	s := make([dynamic]byte, 6)
	inject_at(&s, saturating_sub(len(s), 1, 0), 32)

	//assert(line_num < 99999, "line number too big pepehands")

	//s: [6]byte = 32
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
	//slice.fill(s[:len(line_str)], 32)

	log.debug(s[:])
	return string(s[:])
}

render_buffer_with_scroll :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()
	tab_width := 4
	line_num: string
	for line_idx, i in viewport.scroll ..= viewport.max_y + viewport.scroll - 1 {
		if line_idx >= saturating_sub(cast(i32)len(buff), 1, 0) || cast(i32)i >= viewport.max_y {
			break
		}
		line_num = format_line_num(line_idx)
		defer delete(line_num)
		todin.print(line_num)
		render_buffer_line(buff[line_idx], viewport, tab_width, Cursor{x = cast(i32)len(line_num)})
		todin.move_to_start_of_next_line()
	}
}

Renderable :: struct {
	current_file: string,
	cursor:       Cursor,
	buffer:       Buffer,
	viewport:     Viewport,
	mode:         EditorMode,
	command_line: CommandLine,
}

LineNum :: distinct int
Screen :: struct {}
Scroll :: struct {}

RenderEvent :: union {
	Cursor,
	LineNum,
	Screen,
	Scroll,
}

render :: proc(renderable: Renderable) {
	render_buffer_with_scroll(renderable.buffer, renderable.viewport)
	write_status_line(
		renderable.mode,
		renderable.current_file,
		renderable.cursor,
		renderable.viewport.scroll,
	)
	if renderable.mode == .command {
		print_command_line(renderable.command_line)
	}
	y, x :=
		saturating_add(renderable.cursor.y, 1, renderable.viewport.max_y),
		saturating_add(renderable.cursor.x, 1, renderable.viewport.max_x - 6)
	todin.move(y, x + 6)
	log.debug(y, x)
	todin.refresh()
}
