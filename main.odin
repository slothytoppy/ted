package main

import "core:fmt"
import "core:os"
import "core:sync/chan"
import "core:thread"
import "tui"

enable_raw_mode :: proc() {
	termios: tui.Termios = ---
	tui.tcgetattr(0, &termios)
	tui.cfmakeraw(&termios)
	tui.tcsetattr(0, tui.TCSAFLUSH, &termios)
}

Thread_Data :: struct {
	channel: chan.Chan([]byte),
}

read_stdin :: proc(th: ^thread.Thread) {
	Data := (cast(^Thread_Data)th.data)
	channel := Data.channel
	data: [1]byte
	for {
		num_read, err := os.read(os.stdin, data[:])
		if num_read > 0 && err == os.ERROR_NONE {
			ok := chan.send(channel, data[:])
			if !ok {

			}
		}
	}
	fmt.panicf("unreachable in procedure %s", #procedure)
}

main :: proc() {
	enable_raw_mode()
	th := thread.create(read_stdin)
	channel, err := chan.create_unbuffered(chan.Chan([]byte), context.allocator)
	th.data = &Thread_Data{channel}
	thread.start(th)
	if err != nil {
		panic("failed to create buffered channel")
	}
	for {
		if data, ok := chan.recv(channel); ok == true {
			fmt.print(data)
		}
	}
	return
}
