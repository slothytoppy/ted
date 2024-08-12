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
				if editor.cursor.y == 0 {
					editor.viewport.scroll = saturating_sub(editor.viewport.scroll, 1, 0)
				}
				move_up(&editor.cursor)
				todin.move_up()
			case .down:
				if editor.cursor.y == editor.viewport.max_y {
					editor.viewport.scroll += 1
				}
				move_down(&editor.cursor, editor.viewport)
				todin.move_down()
			case .left:
				move_left(&editor.cursor)
				todin.move_left()
			case .right:
				move_right(&editor.cursor, editor.viewport)
				todin.move_right()
			}
			todin_event = event
			new_event = todin_event
		}
	case Quit:
		break
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
		}
	}
	deinit()
}

render :: proc(buff: Buffer, viewport: Viewport) {
	todin.save_cursor_pos()
	todin.clear_screen()
	todin.reset_cursor()

	scroll_lines := viewport.scroll
	scroll_amount := 0
	for cell, i in buff {
		if cell.datum.keyname == '\n' {
			scroll_amount = i
			scroll_lines -= 1
		}
		if scroll_lines == 0 {
			break
		}
	}
	log.info("scroll amount:", scroll_amount)

	col := 0
	// scroll amount is an offset into a 1d array, it allows us to do scrolling while having all the fun of manually dealing with adding "lines" to a 1d array!
	log.info(scroll_amount, cast(int)(viewport.max_y * viewport.max_x) + scroll_amount)
	for i in scroll_amount ..< cast(int)(viewport.max_y * viewport.max_x) + scroll_amount {
		if i > len(buff) - 1 {
			break
		}

		if cast(i32)col > viewport.max_x {
			col = 0
			continue
		}

		cell := buff[i]
		switch cell.datum.keyname {
		case '\n':
			col = 0
			todin.move_to_start_of_next_line()
		case '\t':
			// TODO: make this configurable
			todin.print("   ")
		case:
			if cell.datum.control {
				continue
			}
			todin.print(cell.datum.keyname)
		}
		col += 1
	}
	todin.restore_cursor_pos()
}

@(require_results)
saturating_add :: proc(val, amount, max: $T) -> T {
	return val + amount > max ? val - amount : max
}

@(require_results)
saturating_sub :: proc(val, amount, min: $T) -> T {
	return val - amount < min ? val - amount : min
}

delete_char :: proc(buffer: ^Buffer, cursor: Cursor, viewport: Viewport) {
	ordered_remove(buffer, cast(int)(cursor.y * cursor.x * viewport.max_x))
}
