package tui

import "core:c"

when ODIN_OS == .Linux {
	foreign import libc "system:libc.a"
} else {
	#panic("unsupported os")
}

TCSAFLUSH :: 2
ECHO: int : 0b0000010
ICANON: int : 0b10

Termios :: struct {
	c_iflag:  int,
	c_oflag:  int,
	c_cflag:  int,
	c_lflag:  int,
	c_cc:     [32]byte,
	c_ispeed: int,
	c_ospeed: int,
}

@(default_calling_convention = "c")
foreign libc {

	tcgetattr :: proc(fd: int, termios: ^Termios) -> int ---
	tcsetattr :: proc(fd, optional_attr: int, termios: ^Termios) -> int ---
	cfmakeraw :: proc(termios_p: ^Termios) ---
}
