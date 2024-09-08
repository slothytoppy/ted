package editor

import "../todin"
import "buffer"
import "core:flags"
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

BufferId :: distinct u8

BufferList :: map[BufferId]buffer.Buffer

Pane :: struct {
	viewport:    Viewport,
	status_line: StatusLine,
	pos:         Pos,
	buffer:      ^buffer.Buffer,
}

Pos :: struct {
	start, end: [2]i32,
}

StatusLine :: struct {
	width:       u8,
	lines_count: u32,
}

Editor :: struct {
	list:         BufferList,
	current_file: string,
	buffer:       buffer.Buffer,
	cursor:       Cursor,
	viewport:     Viewport,
	// global editor wide
	mode:         EditorMode,
	command_line: CommandLine,
}

Init :: struct {}
Quit :: struct {}

Event :: union {
	todin.Event,
	Init,
	Quit,
}

init :: proc() -> (editor: Editor, log_file: os.Handle) {
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

	width := todin.get_max_cols()
	height := todin.get_max_rows()
	editor.viewport.max_y = height - (STATUS_LINE_HEIGHT + COMMAND_LINE_HEIGHT)
	editor.viewport.max_x = width

	editor.buffer = buffer.init_buffer(arg_info.file)

	todin.init()
	todin.enter_alternate_screen()
	set_status_line_position(editor.viewport.max_y)
	set_command_line_position(&editor.command_line, editor.viewport.max_y + 1)
	editor.current_file = arg_info.file
	if cast(i32)arg_info.position < buffer.buffer_length(editor.buffer) {
		editor.cursor.y = cast(i32)arg_info.position
	}
	init_render_buffers(width, height)
	renderable: Renderable = {
		current_file = editor.current_file,
		cursor       = editor.cursor,
		viewport     = editor.viewport,
		mode         = editor.mode,
		command_line = editor.command_line,
		buffer       = editor.buffer,
	}
	/*
     render(renderable)
	todin.reset_cursor()
  */
	return editor, arg_info.log_file
}

deinit :: proc() {
	todin.leave_alternate_screen()
	todin.deinit()
}

@(require_results)
update :: proc(editor: ^Editor, event: Event) -> Event {
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
		}
	}
	switch editor.mode {
	case .normal:
		return normal_mode(editor, event)
	case .insert:
		return insert_mode(editor, event)
	case .command:
		return command_mode(editor, event)
	}
	return nil
}

run :: proc(editor: ^Editor) {
	log_file: os.Handle
	editor^, log_file = init()
	context.logger = init_logger_from_fd(log_file)
	log.info(editor.cursor)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer log_leaks(&track)
	}

	loop: for {
		if todin.poll() {
			input_event: Event = todin.read()
			event := update(editor, input_event)
			renderable: Renderable = {
				current_file = editor.current_file,
				cursor       = editor.cursor,
				viewport     = editor.viewport,
				mode         = editor.mode,
				command_line = editor.command_line,
				buffer       = editor.buffer,
			}
			#partial switch e in event {
			case Quit:
				break loop
			}
			render(renderable)
		}
	}
	deinit()
}

/* converts an Event into an easily used string*/
event_to_string :: proc(event: Event) -> string {
	switch e in event {
	case Init:
		return "Init"
	case Quit:
		return "Quit"
	case todin.Event:
		#partial switch event in e {
		case todin.Key:
			if event.control {
				return todin.event_to_string(e)
			}
			if event.keyname == 'k' {
				return "up"
			}
			if event.keyname == 'j' {
				return "down"
			}
			if event.keyname == 'l' {
				return "right"
			}
			if event.keyname == 'h' {
				return "left"
			}
		}
		return todin.event_to_string(e)
	}
	return ""
}

move_dir :: proc(cursor: ^Cursor, viewport: Viewport, arrow: todin.ArrowKey) {
	switch arrow {
	case .up:
		move_up(cursor)
	case .down:
		move_down(cursor, viewport)
	case .left:
		move_left(cursor)
	case .right:
		move_right(cursor, viewport)
	}
}
