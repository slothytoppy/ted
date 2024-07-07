package cursor

Cursor_Mode :: enum {
	hidden,
	normal,
	high_visibility,
}

Cursor :: struct {
	x, y, rows, columns: int,
	mode:                Cursor_Mode,
}
