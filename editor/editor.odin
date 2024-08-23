package editor

import "../todin"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"

Viewport :: struct {
	max_x, max_y, scroll: i32,
}

EditorMode :: enum {
	normal,
	insert,
	command,
}

Editor :: struct {
	file_data: []byte,
	mode:      EditorMode,
	buffer:    Buffer,
	cursor:    Cursor,
	viewport:  Viewport,
}

Quit :: struct {}

Event :: union {
	todin.Event,
	Quit,
}

init :: proc(file: string) -> (editor: Editor) {
	editor.viewport.max_y, editor.viewport.max_x = todin.get_max_cursor_pos()
	editor.file_data, _ = os.read_entire_file(file)
	editor.buffer = init_buffer_from_bytes(editor.file_data)
	todin.init()
	todin.enter_alternate_screen()
	return editor
}

deinit :: proc() {
	todin.leave_alternate_screen()
	todin.deinit()
}

update :: proc(editor: ^Editor, event: Event) -> (new_event: Event) {
	todin_event: todin.Event = todin.Nothing{}
	switch e in event {
	case Quit:
		return Quit{}
	case todin.Event:
		#partial switch event in e {
		case todin.Key:
			key_to_string := todin.event_to_string(event)
			switch key_to_string {
			case "<c-q>":
				return Quit{}
			}
		case todin.ArrowKey:
			switch event {
			case .up:
				editor_move_up(editor)
			case .down:
				editor_move_down(editor)
			case .left:
				editor_move_left(editor)
			case .right:
				editor_move_right(editor)
			}
			todin_event = event
			return todin_event
		}
	}
	switch editor.mode {
	case .insert:
		insert_mode(editor, event)
	case .normal:
		normal_mode(editor, event)
	case .command:
		unimplemented()
	}
	return nil
}

run :: proc(editor: ^Editor) {
	arg_info: Args_Info
	error := parse_cli_arguments(&arg_info)
	switch e in error {
	case EditorError:
		switch e {
		case .file_doesnt_exist, .no_file, .none:
		}
	case flags.Error:
		switch error in e {
		case flags.Parse_Error, flags.Help_Request, flags.Open_File_Error, flags.Validation_Error:
			print_error(error)
			os.exit(1)
		}
	}
	editor.file_data, _ = os.read_entire_file(arg_info.file)
	context.logger = init_logger_from_fd(arg_info.log_file)

	editor^ = init(arg_info.file)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer log_leaks(&track)
	}

	render(editor.buffer, editor.viewport)
	todin.reset_cursor()
	log.info(editor.cursor)

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
			todin.move(
				saturating_add(editor.cursor.y, 1, editor.viewport.max_y),
				saturating_add(editor.cursor.x, 1, editor.viewport.max_x),
			)
		}
	}
	deinit()
}
