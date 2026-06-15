package main

import "core:os"

main :: proc() {
	enable_raw_mode()
	enter_alt_screen()
	defer disable_raw_mode()
	defer exit_alt_screen()

	buffer: [1]byte

	for {
		bytes_read, err := read_key(buffer[:])
		if err == .EAGAIN || bytes_read == 0 do continue

		if process_keypress(buffer[0]) do break
	}
}
