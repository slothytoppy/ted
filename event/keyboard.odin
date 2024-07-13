package event

import ncurses "../deps/ncurses/src"
import "core:sync/chan"
import "core:thread"

Modifiers :: struct {
	ctrl, shift, alt: bool,
}

// uses something like ncurses.keyname for finding keys in keymap
KeyMap :: map[string]string

Event :: struct {
	key:       string,
	modifiers: Modifiers,
	keymap:    KeyMap,
}

is_ctrl :: proc(event: ^Event, key: string) -> bool {
	if key == event.keymap["control"] {
		event.modifiers.ctrl = true
		return true
	}
	return false
}

is_shift :: proc(key: rune) -> bool {
	unimplemented()
}

@(private)
keyboard_channel: chan.Chan(rune)

// creates a thread with a channel of type rune to read characters from ncurses, manages an internal channel that isnt exposed to the user
poll :: proc() {
	poll_char :: proc(th: ^thread.Thread) {
		channel := (cast(^chan.Chan(rune))th.data)
		for {
			_ = chan.try_send(channel^, cast(rune)ncurses.getch())
		}
	}
	keyboard_channel, _ = chan.create_unbuffered(chan.Chan(rune), context.allocator)
	th := thread.create(poll_char)
	th.data = &keyboard_channel
	thread.start(th)
}

poll_next :: proc() -> Maybe(rune) {
	data, ok := chan.try_recv(keyboard_channel)
	if !ok {
		return nil
	}
	return data
}
