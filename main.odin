package main

import "./keyboard"
import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "core:sync/chan"
import "core:thread"
import "cursor"
import "deps/ncurses/"
import "editor_buffer"

Thread_Data :: struct {
	channel: chan.Chan(rune),
}

Editor_Mode :: enum {
	normal,
	insert,
	search,
	command,
}

Editor_State :: struct {
	buffer: editor_buffer.Buffer,
	mode:   Editor_Mode,
}

read_stdin :: proc(th: ^thread.Thread) {
	Data := (cast(^Thread_Data)th.data)
	channel := Data.channel
	for {
		ok := chan.send(channel, cast(rune)ncurses.getch())
		if !ok {
		}
	}
	fmt.panicf("unreachable in procedure %s", #procedure)
}

main :: proc() {
	fd, error := os.open("log", os.O_RDWR | os.O_CREATE | os.O_TRUNC, 0o611)
	logger := log.create_file_logger(fd)
	context.logger = logger
	th := thread.create(read_stdin)
	channel, err := chan.create_unbuffered(chan.Chan(rune), context.allocator)
	th.data = &Thread_Data{channel}
	thread.start(th)
	if err != nil {
		panic("failed to create buffered channel")
	}

	state: Editor_State
	cli_args := os.args[1:]
	if len(cli_args) <= 0 {
		panic("file to edit was not given")
	}
	if !os.exists(cli_args[0]) {
		panic(fmt.tprint("file:", cli_args[0], "does not exist"))
	}
	win := ncurses.initscr()
	ncurses.raw()
	ncurses.noecho()
	ncurses.cbreak()
	ncurses.keypad(ncurses.stdscr, true)
	cur := cursor.new()
	y, x := ncurses.getmaxyx(ncurses.stdscr)
	cur.max_col = u16(y)
	cur.max_row = u16(x)
	data, _ := os.read_entire_file_from_filename(cli_args[0])
	data_arr := strings.split(string(data), "\n")
	/*
	y, x := ncurses.getmaxyx(win)
	state.buffer.data = make([dynamic]strings.Builder, 0, x)
	for data, i in data_arr {
		if i32(i) < y {
			append(&state.buffer.data, strings.Builder{})
			strings.write_string(&state.buffer.data[i], data)
		} else {
			break
		}
	}

	str: [dynamic]string
	for builder in state.buffer.data {
		if builder.buf == nil {
			append(&str, "\n")
		} else {
			append(&str, string(builder.buf[:]))
		}
		log.info(string(builder.buf[:]))
	}

	for data, i in str {
		ncurses.printw("%s", data)
		ncurses.move(i32(i + 1), 0)
	}
	ncurses.refresh()
  */
	for {

		data := keyboard.get_char(channel)

		if data != nil {
			if ncurses.keyname(i32(rune(data.(rune)))) == "^Q" {
				ncurses.endwin()
				return
			}
			if ncurses.keyname(i32(rune(data.(rune)))) == "^I" {
				/*
				ncurses.endwin()
				fmt.print(#location(), "not yet implemented: tab key")
				os.exit(1)
        */
			}
			if ncurses.keyname(i32(rune(data.(rune)))) == "^J" {
				/*
				ncurses.endwin()
				fmt.print(#location(), "not yet implemented: enter key")
				os.exit(1)
        */
			}
			switch data {
			case ncurses.KEY_LEFT:
				cursor.move(&cur, .left)
			case ncurses.KEY_RIGHT:
				cursor.move(&cur, .right)
			case ncurses.KEY_UP:
				cursor.move(&cur, .up)
			case ncurses.KEY_DOWN:
				cursor.move(&cur, .down)
			case 'j':
				cursor.move_to_line_start(&cur, cur.col)
			case 'k':
				cursor.move_to_line_end(&cur, cur.col)
			case ncurses.KEY_RESIZE:
				y, x = ncurses.getmaxyx(ncurses.stdscr)
				cur.max_col = u16(y)
				cur.max_row = u16(x)
			}
			ncurses.move(auto_cast cur.col, auto_cast cur.row)
			log.info(cur)
			ncurses.refresh()
		}

		/*
         switch data {
			// 127 is DELETE
			case ncurses.KEY_BACKSPACE:
				y, x := ncurses.getyx(win)
				ncurses.move(y, x - 1)
				ncurses.printw(" ")
				ncurses.move(y, x - 2)
			case cast(rune)27:
				ncurses.printw("caught escape")
			case ncurses.KEY_ENTER:
				ncurses.printw("caught enter")
			case ncurses.KEY_LEFT:
				ncurses.printw("caught arrow_key left\n")
			case ncurses.KEY_RIGHT:
				ncurses.printw("caught arrow_key right\n")
			case ncurses.KEY_UP:
				ncurses.printw("caught arrow_key up\n")
			case ncurses.KEY_DOWN:
				ncurses.printw("caught arrow_key down\n")
			case:
			//fmt.print(ncurses.keyname(i32(data)))
			}
      */
		/*
			if keyboard.is_ctrl(data) {
				ncurses.printw(
					strings.clone_to_cstring(
						fmt.tprint("ctrl+", data, "\n"),
						context.temp_allocator,
					),
				)
			}
      */
	}
	ncurses.endwin()
	return
}
