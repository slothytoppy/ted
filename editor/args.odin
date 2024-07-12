package editor

import "core:os"

get_args :: proc() -> []string {
	return os.args[1:]
}
