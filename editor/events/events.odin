package events

KeyboardEvent :: struct {
	key:                  string,
	is_control, is_shift: bool,
}

Nothing :: struct {}
Quit :: struct {}
GoToLineStart :: struct {}
GoToLineEnd :: struct {}
Enter :: struct {}
UpdateCursorEvent :: struct {}
/*
Scroll :: struct {
	Direction: enum {
		up,
		down,
	},
	amount:    i32,
}
*/

Event :: union {
	Nothing,
	KeyboardEvent,
	Quit,
	Enter,
	UpdateCursorEvent,
}

Renderer :: struct($T: typeid) {
	data:   T,
	init:   proc() -> T,
	update: proc(model: ^T, event: Event) -> Event,
	render: proc(model: T),
}

ChangeRenderer :: proc(
	$T: typeid,
	init: proc() -> T,
	update: proc(t: ^T, event: Event) -> Event,
	render: proc(t: T),
) -> Renderer(T) {
	return Renderer(T){{}, init, update, render}
}
