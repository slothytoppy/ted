package todin

foreign import c_ffi "./lib/c_ffi.a"

@(private)
WINDOW_SIZE :: struct {
	cols, rows: i32,
}

foreign c_ffi {
	init :: proc() ---
	deinit :: proc() ---
	enable_no_echo :: proc() ---
	disable_no_echo :: proc() ---
	enable_raw_mode :: proc() ---
	disable_raw_mode :: proc() ---
	@(private)
	GLOBAL_WINDOW_SIZE: WINDOW_SIZE
	has_resized :: proc() -> bool ---
	@(link_name = "poll_stdin")
	poll :: proc() -> bool ---
}
