package tui

import "../deps/ncurses"
import "core:log"
import "core:sync/chan"
import "core:thread"

@(private)
keyboard_channel_type :: chan.Chan(string)
@(private)
keyboard_channel: keyboard_channel_type


@(init)
init_keypoll :: proc() {
	keyboard_channel, _ = chan.create_unbuffered(keyboard_channel_type, context.allocator)
	get_keypress :: proc(t: ^thread.Thread) {
		for {
			_ = chan.try_send(keyboard_channel, string(ncurses.keyname(ncurses.getch())))
		}
	}
	th := thread.create(get_keypress)
	thread.start(th)
}

poll_keypress :: proc() -> (event: KeyEvent) {
	data, ok := chan.try_recv(keyboard_channel)
	if !ok || data == "" {
		return KeyEvent{""}
	}
	switch data {
	case "^Q":
		log.info("control+q")
		event = KeyEvent{"control+q"}
	case "^J":
	case " ":
		event = KeyEvent {
			key = "space",
		}
	case "KEY_UP":
		event = KeyEvent{"up"}
	case "KEY_DOWN":
		event = KeyEvent{"down"}
	case "KEY_LEFT":
		event = KeyEvent{"left"}
	case "KEY_RIGHT":
		event = KeyEvent{"right"}
	case:
		event = KeyEvent{data}
	}
	return event
}

get_key_event :: proc() -> (event: Event) {
	keyevent := poll_keypress()
	switch keyevent.key {
	case "":
		event = None{}
	case "control+q":
		event = Quit{}
	case " ", "space":
		event = KeyEvent{"space"}
	case "up":
		event = KeyEvent{"up"}
	case:
		event = keyevent
	}
	return event
}

update :: proc(data: [][dynamic]byte, cursor: ^Cursor, viewport: Viewport) -> (event: Event) {
	keyevent := poll_keypress()
	switch keyevent.key {
	case "":
		return None{}
	case "control+q":
		event = Quit{}
	case " ":
		event = KeyEvent{"space"}
	case "enter":
		event = KeyEvent{"enter"}
	case "up":
		cursor.y = saturating_sub(cursor.y, 1)
		event = Cursor {
			y = cursor.y,
			x = cursor.x,
		}
		event = cursor^
	case "down":
		cursor.y = saturating_add(cursor.y, 1, viewport.max_y)
		event = Cursor {
			y = cursor.y,
			x = cursor.x,
		}
		event = cursor^
	case "left":
		cursor.x = saturating_sub(cursor.x, 1)
		event = Cursor {
			y = cursor.y,
			x = cursor.x,
		}
		event = cursor^
	case "right":
		cursor.x = saturating_add(cursor.x, 1, viewport.max_x)
		event = Cursor {
			y = cursor.y,
			x = cursor.x,
		}
		event = cursor^
	case:
		log.info(transmute([]u8)(keyevent.key))
		event = keyevent
	}
	return event
}

render :: proc(data: [][dynamic]byte, viewport: Viewport, event: Event) {
	clear()
	move(0, 0)
	should_log := true
	switch e in event {
	case KeyEvent, None:
		break
	case Quit:
		log.info("quiting")
		ncurses.move(0, 0)
		ncurses.printw("%s", "Quiting, goodbye!")
		ncurses.refresh()
	case Render:
		for i in 0 ..< viewport.max_y + viewport.scroll_y {
			idx: i32 = saturating_add(i, viewport.scroll_y, cast(i32)len(data) - 1)
			line_len := min(cast(i32)len(data[idx]), viewport.max_x)
			for b in data[idx][:line_len] {
				ncurses.printw("%s", format_to_cstring(rune(b)))
			}
			if idx == cast(i32)len(data) - 1 && should_log == true {
				should_log = false
				log.info("idx", idx, string(data[idx][:]))
			}
			move(i + 1, 0)
			if idx == cast(i32)len(data) - 1 {
				break
			}
		}
		refresh()
	case Cursor:
		move(e.y, e.x)
		refresh()
	}
}
