package keyboard

import "../../deps/ncurses"
import "core:log"
import "core:strings"
import "core:sync/chan"
import "core:thread"
import "core:unicode"

KeyboardEvent :: struct {
	key:                  string,
	is_control, is_shift: bool,
}

// mapping of strings to keyboard events
Keymap :: map[string]KeyboardEvent

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

poll_keypress :: proc() -> (ev: KeyboardEvent) {
	maybe_key, _ := chan.try_recv(keyboard_channel)
	if maybe_key != nil {
		key := maybe_key.?
		if len(key) > 1 && key[0] == '^' && key[1] != 'J' {
			if key[1] == 'J' {
				ev.key = "enter"
			} else {
				ev.key = strings.concatenate({"control+", strings.to_lower(key[1:])})
			}
			log.info("found:", ev.key)
			ev.is_control = true
		} else {
			bytes: []byte = transmute([]byte)ev.key
			found_shift := false
			for &b in bytes {
				if b > 65 || b <= 90 {
					b += 32
					found_shift = true
				}
			}
			if found_shift {
				ev.key = strings.concatenate({"shift+", strings.clone_from_bytes(bytes)})
				ev.is_shift = true
			} else {
				ev.key = key
			}
		}
	}
	return ev
}

init_keymap :: proc(strs: ..string) -> Keymap {
	keymap := make(Keymap)
	for s in strs {
		map_insert(&keymap, s, KeyboardEvent{key = s, is_control = true, is_shift = false})
	}
	return keymap
}
