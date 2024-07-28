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
	GoToLineStart,
	GoToLineEnd,
	Enter,
}

Renderer :: struct($T: typeid) {
	data:   T,
	init:   proc() -> T,
	update: proc(model: ^T, event: Event) -> Event,
	render: proc(model: T) -> []string,
}

ChangeRenderer :: proc(
	$T: typeid,
	init: proc() -> T,
	update: proc(t: ^T, event: Event) -> Event,
	render: proc(t: T) -> []string,
) -> Renderer(T) {
	return Renderer(T){{}, init, update, render}
}
