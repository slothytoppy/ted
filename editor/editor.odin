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
	current_file: string,
	mode:         EditorMode,
	buffer:       Buffer,
	cursor:       Cursor,
	viewport:     Viewport,
	command_line: CommandLine,
}

Init :: struct {}
Quit :: struct {}

Event :: union {
	todin.Event,
	Init,
	Quit,
}

init :: proc(file: string) -> (editor: Editor) {
	editor.viewport.max_y, editor.viewport.max_x =
		todin.get_max_cols() - (STATUS_LINE_HEIGHT + COMMAND_LINE_HEIGHT), todin.get_max_rows()
	editor.buffer = init_buffer(file)
	todin.init()
	todin.enter_alternate_screen()
	set_status_line_position(editor.viewport.max_y)
	set_command_line_position(&editor.command_line, editor.viewport.max_y + 1)
	render(editor)
	todin.reset_cursor()
	todin.refresh()
	editor.current_file = file
	return editor
}

deinit :: proc() {
	todin.leave_alternate_screen()
	todin.deinit()
}

update :: proc(editor: ^Editor, event: Event) -> (new_event: Event) {
	todin_event: todin.Event = todin.Nothing{}
	switch e in event {
	case Init:
	case Quit:
		return Quit{}
	case todin.Event:
		#partial switch event in e {
		case todin.Resize:
			editor.viewport.max_y, editor.viewport.max_x = todin.get_max_cursor_pos()
			editor.viewport.max_y -= STATUS_LINE_HEIGHT + COMMAND_LINE_HEIGHT
		case todin.ArrowKey:
			dir: CursorEvent
			switch event {
			case .up:
				dir = .up
			case .down:
				dir = .down
			case .left:
				dir = .left
			case .right:
				dir = .right
			}
			editor_move(dir, editor.buffer, &editor.cursor, &editor.viewport)
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
		new_event = command_mode(editor, event)
	}
	return new_event
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

	context.logger = init_logger_from_fd(arg_info.log_file)
	editor^ = init(arg_info.file)
	log.info(editor.cursor)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer log_leaks(&track)
	}

	loop: for {
		if todin.poll() {
			event: Event = todin.read()
			event = update(editor, event)
			switch e in event {
			case todin.Event:
			case Init:
			case Quit:
				break loop
			}
			render(editor^)
			// TODO: remove the need for todin.move() and do rendering where it can remember or not interfere with the tui's cursor
		}
	}
	deinit()
}
