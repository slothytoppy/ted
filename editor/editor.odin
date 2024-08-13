package editor

import "../deps/todin"
import "core:flags"
import "core:log"
import "core:os"

Viewport :: struct {
	min_x, max_x, min_y, max_y, scroll: i32,
}

Editor :: struct {
	buffer:   Buffer,
	cursor:   Cursor,
	viewport: Viewport,
}

Quit :: struct {}

Event :: union {
	todin.Event,
	Quit,
}

deinit :: proc() {
	todin.leave_alternate_screen()
	todin.deinit()
}

update :: proc(editor: ^Editor, event: Event) -> (new_event: Event) {
	todin_event: todin.Event = todin.Nothing{}
	switch e in event {
	case todin.Event:
		#partial switch event in e {
		case todin.Key:
			switch todin.event_to_string(e) {
			case "backspace":
				delete_char(&editor.buffer, editor.cursor, editor.viewport)
				todin_event = todin.BackSpace{}
				new_event = todin_event
			case "<c-q>":
				return Quit{}
			}
		case todin.ArrowKey:
			switch event {
			case .up:
				move_up(&editor.cursor)
				log.info(editor.viewport.scroll)
				todin.move_up()
				if editor.cursor.y == 0 {
					editor.viewport.scroll = saturating_sub(editor.viewport.scroll, 1, 0)
				}
			case .down:
				move_down(&editor.cursor, editor.viewport)
				todin.move_down()
				if editor.cursor.y >= editor.viewport.max_y {
					editor.viewport.scroll += 1
				}
				log.info(editor.viewport.scroll)
			case .left:
				move_left(&editor.cursor)
				todin.move_left()
			case .right:
				move_right(&editor.cursor, editor.viewport)
				todin.move_right()
			}
			todin_event = event
			new_event = todin_event
			return new_event
		}
	case Quit:
		return Quit{}
	}
	return nil
}

run :: proc(editor: ^Editor) {
	arg_info: Args_Info
	error := parse_cli_arguments(&arg_info)
	switch e in error {
	case flags.Parse_Error, flags.Help_Request, flags.Open_File_Error, flags.Validation_Error:
		print_error(error)
		os.exit(1)
	}
	context.logger = log.create_file_logger(arg_info.log_file)
	editor.buffer = init_buffer_from_file(arg_info.file)
	editor.viewport.max_y, editor.viewport.max_x = todin.get_max_cursor_pos()
	todin.init()
	todin.enter_alternate_screen()

	render(editor.buffer, editor.viewport)
	todin.move(editor.cursor.y, editor.cursor.x)
	loop: for {
		if todin.poll() {
			event: Event = todin.read()
			event = update(editor, event)
			switch e in event {
			case todin.Event:
			case Quit:
				break loop
			}
			render(editor.buffer, editor.viewport)
			todin.move(editor.cursor.y, editor.cursor.x)
		}
	}
	deinit()
}

render :: proc(buff: Buffer, viewport: Viewport) {
	todin.clear_screen()
	todin.reset_cursor()

	// scroll amount is an offset into a 1d array, it allows us to do scrolling while having all the fun of manually dealing with adding "lines" to a 1d array!

	idx: int
	scroll_amount := viewport.scroll

	if viewport.scroll > 0 {
		for cell, i in buff {
			if scroll_amount <= 0 {
				break
			}
			if cell.datum.keyname == '\n' {
				idx = i
				scroll_amount -= 1
			}
		}
	}

	if idx >= len(buff) {
		return
	}

	lines_count: i32 = 0
	for i in idx ..< len(buff[:]) {
		cell := buff[i]
		if lines_count >= viewport.max_y {
			break
		}
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
	log.info("renderer:", lines_count, idx, viewport.scroll)
}

@(require_results)
saturating_add :: proc(val, amount, max: $T) -> T {
	if val + amount < max {
		return val + amount
	}
	return max
}

@(require_results)
saturating_sub :: proc(val, amount, min: $T) -> T {
	if val - amount > min {
		return val - amount
	}
	return min
}

delete_char :: proc(buffer: ^Buffer, cursor: Cursor, viewport: Viewport) {
	ordered_remove(buffer, cast(int)(cursor.y * cursor.x * viewport.max_x))
}
