package main

import "core:fmt"
import "core:os"
import psx "core:sys/posix"


@(private = "file")
orig_mode: psx.termios


main :: proc() {
	enable_raw_mode()
	defer disable_raw_mode()

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


enable_raw_mode :: proc() {
	res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	psx.atexit(disable_raw_mode)

	raw := orig_mode
	raw.c_lflag -= {.ECHO, .ICANON, .ISIG, .IEXTEN}
	raw.c_oflag -= {.OPOST}

	raw.c_cflag += {.CS8}
	raw.c_cc[.VMIN] = 0
	raw.c_cc[.VTIME] = 1
	res = psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &raw)
	assert(res == .OK)
}

disable_raw_mode :: proc "c" () {
	psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &orig_mode)
}
