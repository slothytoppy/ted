package editor

import "../buffer"
import "../deps/todin"
import "core:log"
import "core:os"

Mode :: enum {
	normal,
	insert,
}

Cursor :: struct {
	y, x: i32,
}

Viewport :: struct {
	min_x, min_y, max_x, max_y, scroll_amount: i32,
}

Editor :: struct {
	current_file: string,
	cursor:       Cursor,
	viewport:     Viewport,
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
	todin.init()
	todin.enter_alternate_screen()
	editor^ = default_init()
	vp: Viewport = {
		max_x = editor.viewport.max_x,
		max_y = editor.viewport.max_y,
	}
	log.info(args_info)
	tui_event: todin.Event
	renderer(editor^)
	log.info(vp)
	loop: for {
		if !todin.poll() {
			continue
		}
		tui_event = todin.read()
		event := updater(editor, tui_event)
		if tui_event == nil {
			continue
		}
		#partial switch e in event {
		case todin.Nothing:
			continue
		}
		log.info(event)
		switch e in event {
		case todin.Nothing:
			continue
		case todin.Key:
			key_str := todin.key_to_string(e)
			if key_str == "<c-q>" {
				break loop
			}
			log.info("key", e.keyname)
		case todin.Resize:
		case todin.ArrowKey:
		case todin.EscapeKey:
		case todin.BackSpace:
		case todin.FunctionKey:
		/*
		case tui.Cursor:
			log.info("cursor")
			tui.move(e.y, e.x)
			tui.refresh()
      */
		/*
		case todin.Render:
			log.info("render")
			tui.render(editor.buffer[:], vp, e)
		case tui.Quit:
			log.info("quit")
			break loop
      */
		}
	}
	todin.leave_alternate_screen()
	todin.deinit()
}
