package main

import "./keyboard"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:sync/chan"
import "core:thread"
import "cursor"
import ncurses "deps/ncurses/src"

Thread_Data :: struct {
	channel: chan.Chan(rune),
}

read_stdin :: proc(th: ^thread.Thread) {
	ncurses.raw()
	ncurses.noecho()
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
				return
			}
			switch data {
			case cast(rune)127:
				y, x := ncurses.getyx(win)
				ncurses.move(y, x - 1)
				ncurses.printw(" ")
				ncurses.move(y, x - 2)
			}
			if keyboard.is_ctrl(data) {
				ncurses.printw(
					strings.clone_to_cstring(
						fmt.tprint("ctrl+", int(data)),
						context.temp_allocator,
					),
				)
			}
			ncurses.refresh()
			fmt.print(rune(data))
		}
	}
	ncurses.endwin()
	return
}
