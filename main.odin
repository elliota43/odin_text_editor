package main

import "core:os"
import "core:strings"

main :: proc() {
	enable_raw_mode()
	enter_alt_screen()
	defer disable_raw_mode()
	defer exit_alt_screen()

	editor := editor_init()


	buffer: [1]byte
	sb := new(strings.Builder)

	for {
		refresh_screen(editor, sb)
		bytes_read, err := read_key(buffer[:])
		if err == .EAGAIN || bytes_read == 0 do continue

		if process_keypress(buffer[0]) do break
	}
}
