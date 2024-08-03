package tui

import "../deps/ncurses"
import "core:fmt"
import "core:log"

format_to_cstring :: proc(val: any) -> cstring {
	return fmt.ctprint(val)
}

Direction :: enum {
	none,
	up,
	down,
}

Render :: struct {
	viewport: Viewport,
}

KeyEvent :: struct {
	key: string,
}

Quit :: struct {}
None :: struct {}

EventType :: #type union {
	None,
	KeyEvent,
	Cursor,
	Render,
	Quit,
}

Event :: EventType

@(require_results)
saturating_add :: proc(#any_int value: i32, amount: i32, max: i32) -> i32 {
	if value + amount > max {
		return amount
	}
	return value + amount
}

@(require_results)
saturating_sub :: proc(#any_int a, b: i32) -> i32 {
	if a - b > 0 {
		return a - b
	}
	return 0
}

@(private = "file")
can_scroll :: proc(viewport: Viewport) -> bool {
	if viewport.scroll_y > 0 {
		return true
	}
	return false
}

scroll :: proc(
	y: i32,
	direction: Direction,
	viewport: Viewport,
) -> (
	vp: Viewport,
	scrolled: bool,
) {
	vp = viewport
	switch direction {
	case .none:
		return viewport, false
	case .up:
		if y == 0 && direction == .up {
			if can_scroll(viewport) {
				vp.scroll_y -= 1
				return vp, true
			}
		}
	case .down:
		if y > viewport.max_y {
			if can_scroll(viewport) {
				vp.scroll_y += 1
				return vp, true
			}
		}
	}
	return viewport, false
}
