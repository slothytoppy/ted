package editor

import "../buffer"
import "../deps/ncurses/"
import "../tui"
import "core:log"
import "core:os"

Mode :: enum {
	normal,
	insert,
}

Editor :: struct {
	current_file: string,
	cursor:       tui.Cursor,
	viewport:     tui.Viewport,
	buffer:       buffer.Buffer,
	mode:         Mode,
}

run :: proc(editor: ^Editor) {
	args_info: Args_Info
	error := parse_cli_arguments(&args_info)
	switch error {
	case .parse_error, .open_file_error, .validation_error:
		os.exit(1)
	case .none, .help_request:
		break
	}
	context.logger = logger_init(args_info.log_file)
	tui.init()
	editor^ = default_init()
	vp: tui.Viewport = {
		max_x = editor.viewport.max_x,
		max_y = editor.viewport.max_y,
	}
	log.info(args_info)
	tui_event: tui.Event = tui.Cursor{0, 0}
	tui.render(editor.buffer[:], vp, tui_event)
	log.info(vp)
	loop: for {
		event := tui.update(editor.buffer[:], &editor.cursor, vp)
		if tui_event == nil {
			continue
		}
		#partial switch e in event {
		case tui.None:
			continue
		}
		log.info(event)
		switch e in event {
		case tui.None:
			continue
		case tui.Cursor:
			log.info("cursor")
			tui.move(e.y, e.x)
			tui.refresh()
		case tui.KeyEvent:
			log.info("key", e.key)
		case tui.Render:
			log.info("render")
			tui.render(editor.buffer[:], vp, e)
		case tui.Quit:
			log.info("quit")
			break loop
		}
	}
	tui.deinit()
}
