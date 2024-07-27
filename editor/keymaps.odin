package editor

Keymap :: map[string]KeyboardEvent

init_keymap :: proc(strs: ..string) -> Keymap {
	keymap := make(Keymap)
	for s in strs {
		map_insert(&keymap, s, KeyboardEvent{key = s, is_control = true, is_shift = false})
	}
	return keymap
}
