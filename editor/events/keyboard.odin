package keyboard

import "../../deps/ncurses"
import "core:log"
import "core:strings"
import "core:sync/chan"
import "core:thread"
import "core:unicode"
import "core:unicode/utf8"


Event :: struct {
	key:                  string,
	is_control, is_shift: bool,
}

@(private)
keyboard_channel_type :: chan.Chan(Maybe(string))
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
		ev.key = maybe_key.?
		if ev.key[0] == '^' {
			ev.is_control = true
			ev.key = strings.concatenate({"ctrl+", strings.to_lower(ev.key[1:])})
		} else {
			for r in ev.key {
				if !unicode.is_upper(r) {
					return ev
				}
			}
			ev.is_shift = true
		}
	}
	return ev
}
