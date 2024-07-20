package main

import "core:fmt"

Interface :: struct($T: typeid) {
	update: proc(self: T, args: ..any),
	view:   proc(self: T),
}

Viewport :: struct {
	using interface: Interface(Viewport),
	cursor:          [2]i32,
}

Renderer :: struct {
	using _: Interface(Renderer),
	data:    [dynamic]byte,
	cursor:  [2]i32,
	lines:   i32,
}

viewport_update :: proc(v: Viewport, s: ..any) {
	fmt.println(v, s)
}

renderer_update :: proc(r: Renderer, s: ..any) {

}

main :: proc() {
	v: Viewport
	r: Renderer
	v.update = viewport_update
	r.update = renderer_update
	v.update(v, "hello")
}
