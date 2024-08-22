package todin

Color :: struct {
	fg, bg: u8,
}

@(require_results)
set_fg :: proc(arg: string, color: Color) -> string {
	unimplemented()
}

@(require_results)
set_bg :: proc(arg: string, color: Color) -> string {
	unimplemented()
}
