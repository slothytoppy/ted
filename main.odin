package main

import "./editor"
import "core:flags"
import "core:log"
import "core:os"
import "editor/events"

Args_Info :: struct {
	file:     string `args:"pos=0,required" usage:"File for editing"`,
	log_file: os.Handle `args:"pos=1,file=cwt,perms=0644,name=log_file" usage:"optional file for logging"`,
}

set_file_logger :: proc(handle: os.Handle) -> log.Logger {
	fd := handle
	if handle == 0 {
		fd, _ = os.open("/dev/null") // makes it so that if the log file is not given it does not write to stdin and logs go nowhere
	}
	return log.create_file_logger(fd)
}

main :: proc() {
	args_info: editor.Args_Info
	editor.parse_cli_arguments(&args_info)
	context.logger = set_file_logger(args_info.log_file)
	state := editor.init_editor()
	state.buffer = editor.load_buffer_from_file(args_info.file)
	editor.render(&state)
	events.init_keyboard_poll()
	state.keymap = events.init_keymap(
		"KEY_UP",
		"KEY_DOWN",
		"KEY_LEFT",
		"KEY_RIGHT",
		"control+c",
		"control+q",
		"shift+a",
	)
	assert(state.keymap != nil)
	for {
		state.event = events.poll_keypress()
		if state.event.key != "" {
			editor.handle_keymap(&state, state.event)
			editor.render(&state)
		}
	}
	editor.deinit_editor()
}
