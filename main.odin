package main

import "./cursor"
import "./editor"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:os"
import ncurses "deps/ncurses/"
import "editor/events"

Args_Info :: struct {
	file:     string `args:"pos=0,required" usage:"File for editing"`,
	log_file: os.Handle `args:"pos=1,file=cwt,perms=0644,name=log_file" usage:"optional file for logging"`,
}

set_file_logger :: proc(handle: os.Handle) -> log.Logger {
	fd := handle
	if handle == 0 {
		fd, _ = os.open("/dev/null") // makes it so that if the log file is not givenit does not write to stdin and logs go nowhere
	}
	return log.create_file_logger(fd)
}

main :: proc() {
	args_info: Args_Info
	flags.parse_or_exit(&args_info, os.args)
	context.logger = set_file_logger(args_info.log_file)
	state := editor.init_editor()
	state = {
		buffer = editor.load_buffer_from_file(args_info.file),
	}
	state.pos = {0, 0, 40, 40}
	state.viewport = {state.buffer[:], [4]i32{0, 0, 3, 4}}
	events.init_keyboard_poll()
	editor.render(state)
	state.keymap = events.init_keymap()
	for k, v in state.keymap {
		log.info(k, v)
	}
	for {
		ev := events.poll_keypress()
		if ev.key != "" {
			log.info(ev.key)
			if ev.key == "control+q" {
				break
			}
			editor.handle_keymap(&state, ev)
			editor.render(state)
		}
	}
	editor.deinit_editor()
}
