package editor

import "core:os"

FileViewer :: []os.File_Info

init_file_viewer :: proc(dir: string) -> Maybe(FileViewer) {
	return read_dir(dir)
}

read_dir :: proc(dir: string) -> Maybe(FileViewer) {
	fd, err := os.open(dir)
	if err != os.ERROR_NONE {
		return nil
	}
	fv, dir_err := os.read_dir(fd, -1)
	if err != os.ERROR_NONE {
		return nil
	}
	return fv
}

render_file_viewer_entries :: proc(viewer: FileViewer, viewport: Viewport) {
	tmp: [dynamic][]byte
	defer delete(tmp)
	for view, i in viewer {
		append(&tmp, transmute([]byte)view.name)
	}
	render_bytes_with_scroll(tmp[:], viewport)
}
