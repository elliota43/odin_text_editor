package main

import "core:fmt"
import "core:os"
import "core:strings"

Editor :: struct {
	screen_rows: u64,
	screen_cols: u64,
}

editor_init :: proc() -> ^Editor {
	editor := new(Editor)

	ws_row, ws_col, ok := get_window_size()
	if !ok {
		os.exit(25)
	}

	editor.screen_cols = ws_col
	editor.screen_rows = ws_row

	return editor
}

editor_draw_rows :: proc(editor: ^Editor, sb: ^strings.Builder) {
	y: u64

	for y = 0; y < editor.screen_rows; y += 1 {
		strings.write_string(sb, "~")
		strings.write_string(sb, ERASE_LINE)
		if y < editor.screen_rows - 1 {
			strings.write_string(sb, "\r\n")
		}
	}
}

process_keypress :: proc(c: byte) -> (should_quit: bool) {

	fmt.printf("c=%d ctrl_q=%d\r\n", c, ctrl_key('q'))
	if c < 32 || c == 127 {
		fmt.printf("%d\r\n", c)
	} else {
		fmt.printf("%d ('%c')\r\n", c, c)
	}

	if c == ctrl_key('q') {
		return true
	}
	return false
}
