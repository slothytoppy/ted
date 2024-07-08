package main

import "./keyboard"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:sync/chan"
import "core:thread"
import "cursor"
import "deps/ncurses/"

Thread_Data :: struct {
	channel: chan.Chan(rune),
}

read_stdin :: proc(th: ^thread.Thread) {
	ncurses.raw()
	ncurses.noecho()
	ncurses.cbreak()
	Data := (cast(^Thread_Data)th.data)
	channel := Data.channel
	data: [1]byte
	for {
		ok := chan.send(channel, cast(rune)ncurses.getch())
		if !ok {
		}
	}
	fmt.panicf("unreachable in procedure %s", #procedure)
}

main :: proc() {
	ncurses.raw()
	ncurses.noecho()
	ncurses.cbreak()
	win := ncurses.initscr()
	ncurses.keypad(win, true)
	th := thread.create(read_stdin)
	channel, err := chan.create_unbuffered(chan.Chan(rune), context.allocator)
	th.data = &Thread_Data{channel}
	thread.start(th)
	if err != nil {
		panic("failed to create buffered channel")
	}
	for {
		if data, ok := chan.recv(channel); ok == true {
			data := cast(rune)data
			if ncurses.keyname(i32(data)) == "^Q" {
				ncurses.endwin()
				return
			}
			if ncurses.keyname(i32(data)) == "^I" {
				ncurses.endwin()
				fmt.print(#location(), "not yet implemented: tab key")
				os.exit(1)
			}
			if ncurses.keyname(i32(data)) == "^J" {
				//ncurses.endwin()
				//fmt.print(#location(), "not yet implemented: enter key")
				//os.exit(1)
			}

			if keyboard.is_shift(data) {
				ncurses.printw("shift detected")
			}
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
				fmt.print(ncurses.keyname(i32(data)))
			}
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
			ncurses.refresh()
		}
	}
	ncurses.endwin()
	return
}
