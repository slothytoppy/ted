package renderer

import "../../todin"
import "../buffer"
import "../command_line"
import "../cursor"
import "../status_line"
import "../viewport"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:strconv"
import "core:strings"

init_render_buffers :: proc(#any_int width, height: int) {
	_width = width
	_height = height
	render_buffer[0] = RenderBuffer {
		cells = make([dynamic]RenderCell, width * height),
	}
	render_buffer[1] = RenderBuffer {
		cells = make([dynamic]RenderCell, width * height),
	}
}

Renderable :: struct {
	current_file: string,
	cursor:       cursor.Cursor,
	buffer:       buffer.Buffer,
	viewport:     viewport.Viewport,
	mode:         status_line.EditorMode,
	command_line: command_line.CommandLine,
}

pre_diff :: proc(renderable: Renderable, viewport: viewport.Viewport) -> RenderBuffer {
	curr_buff := render_buffer[0]
	viewport := renderable.viewport
	idx := 0
	buffer_len := saturating_sub(buffer.buffer_length(renderable.buffer), 1, 0)
	height := viewport.max_y
	renderable_amount := min(buffer_len, height)
	for line in renderable.buffer[viewport.scroll:renderable_amount + viewport.scroll] {
		for cell in line {
			if idx >= len(curr_buff.cells) - 1 {
				break
			}
			switch cell.datum {
			case '\t':
				curr_buff.cells[idx].datum = ' '
				idx += 1
			case '\n':
			case:
				curr_buff.cells[idx].datum = cell.datum
				idx += 1
			}
		}
		for i in len(line) ..= _width {
			if idx >= len(curr_buff.cells) {
				break
			}
			curr_buff.cells[idx].datum = ' '
			idx += 1
		}
	}

	status_line := status_line.write_status_line(
		renderable.mode,
		renderable.current_file,
		renderable.cursor,
		viewport.scroll,
	)
	defer delete(status_line)
	status_line_start := _width * cast(int)viewport.max_y
	for s, i in status_line {
		curr_buff.cells[status_line_start + i] = RenderCell{s}
	}

	command_line := command_line.print_command_line(renderable.command_line)
	defer delete(command_line)
	command_line_start := _width * cast(int)viewport.max_y + _width
	if renderable.mode == .command {
		curr_buff.cells[command_line_start] = RenderCell{':'}
		for s, i in command_line {
			curr_buff.cells[command_line_start + i + 1] = RenderCell{s}
		}
	}
	return curr_buff
}

post_diff :: proc(buf: RenderBuffer, viewport: viewport.Viewport) {
	diffs := get_diffs()
	defer delete(diffs)

	slice.swap(render_buffer[:], 1, 0)

	render_diffs(diffs, viewport)
}

render :: proc(renderable: Renderable) {
	todin.hide_cursor()
	defer todin.unhide_cursor()
	if len(renderable.buffer) == 0 {
		return
	}
	status_line_start := _width * cast(int)renderable.viewport.max_y
	viewport := renderable.viewport
	rendered := pre_diff(renderable, viewport)
	post_diff(rendered, viewport)
	slice.fill(render_buffer[0].cells[status_line_start:], RenderCell{' '})

	x := renderable.cursor.x
	if x + 6 < viewport.max_x {
		x += 6
	}
	todin.move(renderable.cursor.y, x)
}

@(private = "file")
render_diffs :: proc(diffs: [dynamic]Changed, viewport: viewport.Viewport) {
	for diff in diffs {
		todin.move(diff.y, 0)
		line_num := format_line_num(diff.y)
		defer delete(line_num)

		if diff.y < cast(int)viewport.max_y {
			for s in line_num {
				todin.print(s)
			}
			todin.move(diff.y, diff.x + len(line_num))
		} else {
			todin.move(diff.y, diff.x)
		}
		todin.print(diff.datum.datum)
	}
}
