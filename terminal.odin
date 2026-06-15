package main
import "base:runtime"
import "core:c"
import "core:os"
import "core:strconv"
import "core:strings"
import psx "core:sys/posix"

ENTER_ALT_SCREEN :: string("\033[?1049h")
EXIT_ALT_SCREEN :: string("\033[?1049l")

CLEAR_SCREEN :: string("\x1b[2J")
RESET_CURSOR_POSITION :: string("\x1b[H")
HIDE_CURSOR :: string("\x1b[?25l")
SHOW_CURSOR :: string("\x1b[?25h")

ERASE_LINE :: string("\x1b[K")

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
	context = runtime.default_context()
	clear_screen()
	reset_cursor_position()
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

refresh_screen :: proc(editor: ^Editor, sb: ^strings.Builder) {
	strings.builder_reset(sb)

	strings.write_string(sb, HIDE_CURSOR)
	strings.write_string(sb, RESET_CURSOR_POSITION)

	editor_draw_rows(editor, sb)

	strings.write_string(sb, RESET_CURSOR_POSITION)
	strings.write_string(sb, SHOW_CURSOR)

	os.write_string(os.stdout, strings.to_string(sb^))
}

@(private = "file")
clear_screen :: proc() {
	os.write(os.stdout, transmute([]byte)CLEAR_SCREEN)
}

@(private = "file")
reset_cursor_position :: proc() {
	os.write(os.stdout, transmute([]byte)RESET_CURSOR_POSITION)
}

Winsize :: struct {
	ws_row:    u16,
	ws_col:    u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
}

when ODIN_OS == .Linux {
	TIOCGWINSZ :: 0x5413
} else when ODIN_OS ==
	.Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
	TIOCGWINSZ :: 0x40087468
}

foreign import libc "system:c"

@(default_calling_convention = "c")
foreign libc {
	ioctl :: proc(fd: c.int, request: c.ulong, #c_vararg args: ..rawptr) -> c.int ---
}

get_window_size :: proc() -> (rows: u64, cols: u64, ok: bool) {
	ws: Winsize
	if ioctl(1, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0 {
		if n, _ := os.write_string(os.stdout, "\x1b[999C\x1b[999B"); n != 12 {
			return 0, 0, false
		}
		return get_cursor_position()
	}
	return u64(ws.ws_row), u64(ws.ws_col), true

}

get_cursor_position :: proc() -> (rows: u64, cols: u64, ok: bool) {
	if n, _ := os.write_string(os.stdout, "\x1b[6n"); n != 4 {
		return 0, 0, false
	}

	buf: [32]byte
	i := 0
	for i < len(buf) - 1 {
		n, _ := os.read(os.stdin, buf[i:i + 1])
		if n != 1 do break
		if buf[i] == 'R' do break
		i += 1
	}

	if buf[0] != '\x1b' || buf[1] != '[' {
		return 0, 0, false
	}

	// buf[2:i] looks like "24;80"
	response := string(buf[2:i])
	semi := strings.index_byte(response, ';')
	if semi < 0 {
		return 0, 0, false
	}

	r, r_ok := strconv.parse_u64(response[:semi])
	c, c_ok := strconv.parse_u64(response[semi + 1:])
	if !r_ok || !c_ok {
		return 0, 0, false
	}

	return r, c, true
}
