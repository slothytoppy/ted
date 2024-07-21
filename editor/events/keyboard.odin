package keyboard

import "../../deps/ncurses"
import "core:strings"
import "core:sync/chan"
import "core:thread"

Event :: struct {
	key:                  string,
	is_control, is_shift: bool,
}

// mapping of strings to keyboard events
Keymap :: map[string]Event

@(private)
keyboard_channel_type :: chan.Chan(Maybe(string))
@(private)
keyboard_channel: keyboard_channel_type

init_keyboard_poll :: proc() {
	keyboard_channel, _ = chan.create_unbuffered(keyboard_channel_type, context.allocator)
	get_keypress :: proc(t: ^thread.Thread) {
		for {
			_ = chan.try_send(keyboard_channel, string(ncurses.keyname(ncurses.getch())))
		}
	}
	th := thread.create(get_keypress)
	thread.start(th)
}

poll_keypress :: proc() -> (ev: Event) {
	maybe_key, _ := chan.try_recv(keyboard_channel)
	if maybe_key != nil {
		key := maybe_key.?
		switch key[0] {
		case '^':
			if len(key) > 1 {
				switch key[1] {
				case 'J':
					ev.key = "enter"
				case 'Q':
					ev.is_control = true
				}
				ev.key = strings.concatenate({"control+", strings.to_lower(key[1:])})
			}
		case:
			/*
			for r in ev.key {
				if !unicode.is_upper(r) {
					return ev
				}
			}
			ev.is_shift = true
			ev.key = strings.concatenate({"shift+", strings.to_lower(ev.key)})
      */
			ev.key = key
		}
	}
	return ev
}

init_keymap :: proc(strs: ..string) -> Keymap {
	keymap := make(Keymap)
	for s in strs {
		map_insert(&keymap, s, Event{key = s, is_control = true, is_shift = false})
	}
	return keymap
}
