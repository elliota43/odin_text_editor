package main

import "core:os"
import psx "core:sys/posix"

ENTER_ALT_SCREEN :: string("\033[?1049h")
EXIT_ALT_SCREEN :: string("\033[?1049l")


@(private = "file")
orig_mode: psx.termios

enable_raw_mode :: proc() {
	res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	psx.atexit(disable_raw_mode)

	raw := orig_mode
	raw.c_iflag -= {.IXON, .ICRNL, .BRKINT, .INPCK, .ISTRIP}
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

enter_alt_screen :: proc() {
	os.write(os.stdout, transmute([]byte)ENTER_ALT_SCREEN)
}

exit_alt_screen :: proc() {
	os.write(os.stdout, transmute([]byte)EXIT_ALT_SCREEN)
}

read_key :: proc(buf: []byte) -> (n: int, err: os.Error) {
	return os.read(os.stdin, buf)
}
