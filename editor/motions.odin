package editor

Motion :: Buffer

init_motion :: proc() -> (motion: Motion) {
	append(&motion, Line{})
	return motion
}

check_motion :: proc(motion: Motion) {
	if len(motion) >= 2 {
		panic("Motion data structure has too many Lines, should only have one Line")
	}
}
