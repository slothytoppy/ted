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
	handle := handle
	switch handle {
	case 0:
		//	handle, _ := os.open("/dev/null") // makes it so that if the log file is not givenit does not write to stdin and logs go nowhere
		return log.create_file_logger(1)
	}
	return log.create_file_logger(handle)
}

main :: proc() {
	args_info: Args_Info
	flags.parse_or_exit(&args_info, os.args)
	context.logger = set_file_logger(args_info.log_file)
	state := editor.init_editor()
	state = {
		buffer = editor.load_buffer_from_file(args_info.file),
	}
	state.viewport = {state.buffer[:], [2]i32{0, 40}}
	cursor.move_cursor_event(&state.pos, .up)
	events.init_keyboard_poll()
	editor.render(state)
	for {
		ev := events.poll_keypress()
		if ev.key != "" {
			if ev.key == "ctrl+q" {
				break
			}
			log.info(state.viewport)
			editor.render(state)
		}
	}
	editor.deinit_editor()
}
