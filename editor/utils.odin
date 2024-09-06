package editor

import "buffer"
import "core:log"
import "core:mem"
import "core:os"

@(require_results)
saturating_add :: proc(val, amount, max: $T) -> T {
	if val + amount < max {
		return val + amount
	}
	return max
}

@(require_results)
saturating_sub :: proc(val, amount, min: $T) -> T {
	if val > 0 && val - amount > min {
		return val - amount
	}
	return min
}

log_leaks :: proc(track: ^mem.Tracking_Allocator) {
	if len(track.allocation_map) > 0 {
		memory_lost: int
		log.warnf("=== %v allocations not freed: ===\n", len(track.allocation_map))
		for _, entry in track.allocation_map {
			log.warnf("- %v bytes @ %v\n", entry.size, entry.location)
			memory_lost += entry.size
		}
		log.warnf("leaked %d bytes", memory_lost)
	}
	if len(track.bad_free_array) > 0 {
		log.warnf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
		for entry in track.bad_free_array {
			log.warnf("- %p @ %v\n", entry.memory, entry.location)
		}
	}
	mem.tracking_allocator_destroy(track)
}

// creates a logger from a given fd, ensures it wont log to stdout
init_logger_from_fd :: proc(fd: os.Handle) -> log.Logger {
	if fd <= 2 {
		return log.nil_logger()
	} else {
		return log.create_file_logger(fd, log.Level.Info)
	}
}

append_rune :: proc(buf: ^buffer.Buffer, cursor: Cursor, r: rune) {
	buffer.append_rune(buf, cursor.y, cursor.x, r)
}

remove_rune :: proc(buf: ^buffer.Buffer, cursor: Cursor) {
	buffer.delete_char(&buf[cursor.y], cursor.x)
}
