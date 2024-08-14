package editor

import "../deps/todin"
import "core:flags"
import "core:log"
import "core:os"

Viewport :: struct {
	min_x, max_x, min_y, max_y, scroll: i32,
}

Editor :: struct {
	buffer:      Buffer,
	cursor:      Cursor,
	viewport:    Viewport,
	text_buffer: TextBuffer,
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
		case todin.BackSpace:
			delete_char(&editor.buffer, editor.cursor, editor.viewport)
			todin_event = todin.BackSpace{}
			new_event = todin_event
		case todin.Key:
			switch todin.event_to_string(e) {
			case "<c-q>":
				return Quit{}
			}
		case todin.ArrowKey:
			switch event {
			case .up:
				log.info(editor.cursor.y)
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

					if editor.viewport.scroll + editor.viewport.max_y <=
					   cast(i32)len(editor.text_buffer.line_idx) {
						editor.viewport.scroll = saturating_add(
							editor.viewport.scroll,
							1,
							cast(i32)len(editor.text_buffer.line_idx),
						)
					}

				}
				log.info(editor.viewport.scroll, len(editor.text_buffer.line_idx))
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
	context.logger = log.create_file_logger(arg_info.log_file, log.Level.Info)
	editor.buffer = init_buffer_from_file(arg_info.file)
	editor.viewport.max_y, editor.viewport.max_x = todin.get_max_cursor_pos()
	todin.init()
	todin.enter_alternate_screen()
	editor.text_buffer = init_text_buffer(editor.buffer)
	log.info(editor.text_buffer.line_idx)
	render(editor.buffer, editor.viewport, editor.text_buffer)
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
			render(editor.buffer, editor.viewport, editor.text_buffer)
			todin.move(editor.cursor.y, editor.cursor.x)
		}
	}
	deinit()
}

render :: proc(buff: Buffer, viewport: Viewport, text_buffer: TextBuffer) {
	todin.clear_screen()
	todin.reset_cursor()

	// scroll amount is an offset into a 1d array, it allows us to do scrolling while having all the fun of manually dealing with adding "lines" to a 1d array!

	idx: int

	if viewport.scroll > 0 && viewport.scroll <= cast(i32)len(text_buffer.line_idx) {
		idx = text_buffer.line_idx[viewport.scroll]
	}

	if idx >= len(buff) {
		return
	}

	lines_count: i32 = 0
	last_idx: int
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
}
