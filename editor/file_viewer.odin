package editor

import "../deps/ncurses"
import "../editor/events"
import "../file_viewer"
import "../viewport"
import "core:strings"

update_file_viewer :: proc(
	fv: ^file_viewer.FileViewer,
	event: events.Event,
) -> file_viewer.Command {
	command: file_viewer.Command
	switch event.(events.KeyboardEvent).key {
	case "KEY_UP":
		command = .up
	case "KEY_DOWN":
		command = .down
	case "^J":
		command = .select
	case "-":
		command = .go_to_parent_dir
	case "control+q":
		command = .quit
	}
	fv^ = file_viewer.update(fv^, command)
	fv.vp.cursor.cur_y = clamp(fv.vp.cursor.cur_y, 0, fv.vp.max_y)
	return command
}

render_file_viewer :: proc(fv: file_viewer.FileViewer, command: file_viewer.Command) {
	renderer_event: file_viewer.RendererEvent
	switch command {
	case .select, .go_to_parent_dir:
		renderer_event = .render_whole
	case .up, .down:
		renderer_event = .update_cursor
	case .quit:
	}
	file_viewer.render(fv, renderer_event)
}
