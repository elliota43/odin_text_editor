package main

import "core:fmt"
import "core:os"


main :: proc() {
	enable_raw_mode()
	enter_alt_screen()
	defer disable_raw_mode()
	defer exit_alt_screen()

	buffer: [1]byte

	for {
		bytes_read, err := os.read(os.stdin, buffer[:])


		// handle timeout
		if err == .EAGAIN || bytes_read == 0 {
			continue
		}

		c := buffer[0]

		if c < 32 || c == 127 {
			fmt.printf("%d\r\n", c)
		} else {
			fmt.printf("%d ('%c')\r\n", c, c)
		}

		if c == 'q' {
			break
		}
	}
}
