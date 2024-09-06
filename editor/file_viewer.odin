package editor

import "../todin"
import "buffer"
import "core:os"

FileViewer :: struct {
	data:   buffer.Buffer,
	cursor: Cursor,
}

init_file_viewer :: read_dir

read_dir :: proc(dir: string) -> FileViewer {
	fv: FileViewer
	fd, err := os.open(dir)
	if err != nil {
		return {}
	}
	fis, fi_err := os.read_dir(fd, -1)
	if fi_err != nil {
		return {}
	}
	fv.data = buffer.init_buffer_with_empty_lines(len(fis))
	for fi, h in fis {
		for r, w in fi.fullpath {
			buffer.append_rune(&fv.data, cast(i32)h, cast(i32)w, r)
			//append(&fv.data[i], buffer.Cell{datum = r})
		}
	}
	return fv
}

update_file_viewer :: proc(fv: ^FileViewer, event: Event, viewport: Viewport) {
	#partial switch e in event {
	case todin.Event:
		#partial switch event in e {
		case todin.Key, todin.ArrowKey:
			handle_file_viewer_movement(fv, event, viewport)
		}
	case Init, Quit:
		break
	}
}

@(private = "file")
handle_file_viewer_movement :: proc(fv: ^FileViewer, event: Event, viewport: Viewport) {
	switch event_to_string(event) {
	case "up":
		move_up(&fv.cursor)
	case "down":
		move_down(&fv.cursor, viewport)
	case "right":
		move_right(&fv.cursor, viewport)
	case "left":
		move_left(&fv.cursor)
	}
}
