package editor

import "../todin"
import "./command_line"
import "./cursor"
import "./renderer"
import "./status_line"
import "buffer"
import "core:flags"
import "core:log"
import "core:mem"
import "core:os"
import "core:time"
import "viewport"

BufferId :: distinct u8

BufferList :: map[BufferId]buffer.Buffer

Pane :: struct {
	viewport:    viewport.Viewport,
	status_line: status_line.StatusLine,
	pos:         Pos,
	buffer:      ^buffer.Buffer,
}

Pos :: struct {
	start, end: [2]i32,
}

Editor :: struct {
	list:         BufferList,
	current_file: string,
	buffer:       buffer.Buffer,
	cursor:       cursor.Cursor,
	viewport:     viewport.Viewport,
	// global editor wide
	mode:         status_line.EditorMode,
	command_line: command_line.CommandLine,
}

Init :: struct {}
Quit :: struct {}

Event :: union {
	todin.Event,
	Init,
	Quit,
}

init :: proc(file: string) -> (editor: Editor) {
	width := todin.get_max_cols()
	height := todin.get_max_rows()
	log.info(width, height)
	editor.viewport.max_y =
		height - (status_line.STATUS_LINE_HEIGHT + command_line.COMMAND_LINE_HEIGHT)
	editor.viewport.max_x = width

	editor.buffer = buffer.init_buffer(file)

	todin.init()
	todin.enter_alternate_screen()
	status_line.set_status_line_position(editor.viewport.max_y)
	command_line.set_command_line_position(&editor.command_line, editor.viewport.max_y + 1)
	editor.current_file = file
	renderer.init_render_buffers(width, height)
	renderable: renderer.Renderable = {
		current_file = editor.current_file,
		cursor       = editor.cursor,
		viewport     = editor.viewport,
		mode         = editor.mode,
		command_line = editor.command_line,
		buffer       = editor.buffer,
	}
	/*render(renderable)
	todin.reset_cursor()
  */
	return editor
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
			editor.viewport.max_y -=
				status_line.STATUS_LINE_HEIGHT + command_line.COMMAND_LINE_HEIGHT
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

run :: proc(file_name: string) {
	log_file: os.Handle
	editor := init(file_name)
	log.info(editor.cursor)

	target_fps: f64 = 60.0
	target_frame_time: time.Duration = time.Millisecond * 1000 / cast(time.Duration)(target_fps)
	last_time := time.now()
	delta_time: time.Duration
	renderable: renderer.Renderable = {
		current_file = editor.current_file,
		cursor       = editor.cursor,
		viewport     = editor.viewport,
		mode         = editor.mode,
		command_line = editor.command_line,
		buffer       = editor.buffer,
	}
	renderer.render(renderable)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer log_leaks(&track)
	}

	loop: for {
		current_time := time.now()
		delta_time = time.diff(last_time, current_time)
		last_time = current_time

		if todin.poll() {
			input_event: Event = todin.read()
			event := update(&editor, input_event)
			renderable: renderer.Renderable = {
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
			renderer.render(renderable)
		}

		frame_time := time.diff(last_time, current_time)
		if frame_time < target_frame_time {
			//log.info(target_frame_time - frame_time)
			time.sleep(target_frame_time - frame_time)
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

move_dir :: proc(
	cur: ^cursor.Cursor,
	viewport: ^viewport.Viewport,
	arrow: todin.ArrowKey,
	buffer: buffer.Buffer,
) {
	switch arrow {
	case .up:
		editor_move_up(buffer, cur, viewport)
	case .down:
		editor_move_down(buffer, cur, viewport)
	case .left:
		editor_move_left(buffer, cur)
	case .right:
		editor_move_right(buffer, cur, viewport^)
	}
}
