package main

import "./event"
import "./keyboard"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sync/chan"
import "cursor"
import ncurses "deps/ncurses/src"
import "editor"
import "viewport"

Thread_Data :: struct {
	channel: chan.Chan(rune),
}

main :: proc() {
	cli_args := os.args[1:]
	if len(cli_args) <= 0 {
		panic("file to edit was not given")
	}
	if !os.exists(cli_args[0]) {
		panic(fmt.tprint("file:", cli_args[0], "does not exist"))
	}

	fd, error := os.open("log", os.O_RDWR | os.O_CREATE | os.O_TRUNC, 0o611)
	if error != os.ERROR_NONE {
		panic(fmt.tprint(os.get_last_error()))
	}
	logger := log.create_file_logger(fd)
	context.logger = logger

	state: editor.Editor_State = editor.new()

	win := ncurses.initscr()
	ncurses.raw()
	ncurses.noecho()
	ncurses.cbreak()
	ncurses.keypad(ncurses.stdscr, true)
	cur := cursor.new(ncurses.getmaxyx(ncurses.stdscr))
	event.poll(rune)

	//state.buffer.data = make([dynamic]strings.Builder, 0, cur.max_row)
	state.mode = .normal
	state.running = true
	state.buffer = editor.load_file_into_buffer(#file)
	log.info(len(state.buffer.data))
	log.info(state.buffer)
	for data, i in state.buffer.data {
		ncurses.printw("%s", data)
		ncurses.move(i32(i + 1), 0)
	}
	cursor.move(&cur, .reset)
	ncurses.refresh()
	for {
		data := event.poll_next()
		//data := keyboard.get_char(channel)
		if data != nil {
			log.info(data)
			switch state.mode {
			case .normal:
				handle_normal(&state, data.(rune), &cur)
			case .insert:
				handle_insert(&state, data.(rune), &cur)
				log.info(cur)
			}
			ncurses.refresh()
			if state.running == false {
				ncurses.endwin()
				return
			}
		}
	}
	ncurses.endwin()
	return
}

handle_normal :: proc(state: ^editor.Editor_State, data: rune, cur: ^cursor.Cursor) {
	if ncurses.keyname(i32(rune(data))) == "^Q" {
		state.running = false
		return
	}
	// TODO: ^I and ^J, ^I is tab and ^J is enter 
	switch data {
	case 'a', 'h', ncurses.KEY_LEFT:
		cursor.move(cur, .left)
	case 'd', 'l', ncurses.KEY_RIGHT:
		cursor.move(cur, .right)
	case 's', 'j', ncurses.KEY_DOWN:
		cursor.move(cur, .down)
	case 'w', 'k', ncurses.KEY_UP:
		cursor.move(cur, .up)
	case 'g':
		cursor.move(cur, .column_end)
	case 'G':
		cursor.move(cur, .column_top)
	case 'i':
		state.mode = .insert
		log.info(state.mode)
	case ncurses.KEY_RESIZE:
		y, x := ncurses.getmaxyx(ncurses.stdscr)
		cur.max_col = u16(y)
		cur.max_row = u16(x)
	}
}

handle_insert :: proc(state: ^editor.Editor_State, data: rune, cur: ^cursor.Cursor) {
	key := ncurses.keyname(i32(data))
	if key == "KEY_LEFT" {
		cursor.move(cur, .left)
	} else if key == "KEY_RIGHT" {
		cursor.move(cur, .right)
	} else if key == "KEY_UP" {
		cursor.move(cur, .up)
	} else if key == "KEY_DOWN" {
		cursor.move(cur, .down)
	} else if key == "KEY_RESIZE" {
		y, x := ncurses.getmaxyx(ncurses.stdscr)
		cur.max_col = u16(y)
		cur.max_row = u16(x)
	} else if key == "KEY_BACKSPACE" {
		cursor.move(cur, .left)
		ncurses.delch()
	} else if key == "^C" {
		state.mode = .normal
	} else {
		ncurses.printw("%c", data)
		cursor.move(cur, .right)
	}
}
