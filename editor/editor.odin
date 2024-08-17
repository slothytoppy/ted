package editor

import "../deps/todin"
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

Editor :: struct {
	mode:     EditorMode,
	buffer:   Buffer,
	cursor:   Cursor,
	viewport: Viewport,
}

Quit :: struct {}

Event :: union {
	todin.Event,
	Quit,
}

init :: proc(arg_info: ^Args_Info) -> (editor: Editor) {
	error := parse_cli_arguments(arg_info)
	editor.viewport.max_y, editor.viewport.max_x = todin.get_max_cursor_pos()
	switch e in error {
	case EditorError:
		switch e {
		case .none:
			editor.buffer = init_buffer_from_file(arg_info.file)
		case .file_doesnt_exist, .no_file:
		//init_empty_text_buffer(editor.viewport)
		}
	case flags.Error:
		switch error in e {
		case flags.Parse_Error, flags.Help_Request, flags.Open_File_Error, flags.Validation_Error:
			print_error(error)
			os.exit(1)
		}
	}
	return editor
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
			key_to_string := todin.event_to_string(event)
			defer delete(key_to_string)
			switch key_to_string {
			case "<c-q>":
				return Quit{}
			}
		case todin.ArrowKey:
			switch event {
			case .up:
				move_up(&editor.cursor)
				todin.move_up()
				if editor.cursor.y == 0 {
					editor.viewport.scroll = saturating_sub(editor.viewport.scroll, 1, 0)
				}
			case .down:
				move_down(&editor.cursor, editor.viewport)
				todin.move_down()
				if editor.cursor.y >= editor.viewport.max_y {
					if editor.viewport.scroll + editor.viewport.max_y <=
					   cast(i32)len(editor.buffer.metadata.line_end) - 1 {
						editor.viewport.scroll = saturating_add(
							editor.viewport.scroll,
							1,
							cast(i32)len(editor.buffer.metadata.line_end) - 1,
						)
					}

				}
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
	editor^ = init(&arg_info)
	context.logger = log.create_file_logger(arg_info.log_file, log.Level.Info)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				memory_lost: int
				log.warnf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					log.warnf("- %v bytes @ %v\n", entry.size, entry.location)
					memory_lost += entry.size
				}
				log.warnf("leaked %d bytes", memory_lost)
			}
			if len(track.bad_free_array) > 0 {
				log.warnf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					log.warnf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	todin.init()
	todin.enter_alternate_screen()
	log.info(editor.cursor)

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
