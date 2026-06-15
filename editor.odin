package main

import "core:fmt"
import "core:os"
import "core:strings"

ODIN_EDITOR_VERSION :: "1.0"

Editor :: struct {
	screen_rows: u64,
	screen_cols: u64,
	cursorX:     int,
	cursorY:     int,
}

editor_init :: proc() -> ^Editor {
	editor := new(Editor)

	ws_row, ws_col, ok := get_window_size()
	if !ok {
		os.exit(25)
	}

	editor.screen_cols = ws_col
	editor.screen_rows = ws_row
	editor.cursorX = 0
	editor.cursorY = 0

	return editor
}

editor_draw_rows :: proc(editor: ^Editor, sb: ^strings.Builder) {
	y: u64

	for y = 0; y < editor.screen_rows; y += 1 {

		if y == editor.screen_rows / 3 {
			welcome_buf: [80]u8

			welcome := fmt.bprintf(
				welcome_buf[:],
				"Odin editor -- version %s",
				ODIN_EDITOR_VERSION,
			)

			welcome_len := len(welcome)
			if welcome_len > int(editor.screen_cols) {
				welcome_len = int(editor.screen_cols)
			}

			padding := (int(editor.screen_cols) - welcome_len) / 2
			if padding > 0 {
				strings.write_string(sb, "~")
				padding -= 1
			}

			for _ in 0 ..< padding {
				strings.write_string(sb, " ")
			}

			strings.write_string(sb, welcome[:welcome_len])
		} else {
			strings.write_string(sb, "~")
		}


		strings.write_string(sb, ERASE_LINE)
		if y < editor.screen_rows - 1 {
			strings.write_string(sb, "\r\n")
		}
	}
}

move_cursor :: proc(editor: ^Editor, key: Special) {
	#partial switch key {
	case .Arrow_Left:
		if editor.cursorX != 0 do editor.cursorX -= 1
	case .Arrow_Right:
		if editor.cursorX != int(editor.screen_cols) - 1 do editor.cursorX += 1
	case .Arrow_Up:
		if editor.cursorY != 0 do editor.cursorY -= 1
	case .Arrow_Down:
		if editor.cursorY != int(editor.screen_rows) - 1 do editor.cursorY += 1
	case: // ignore non-arrow specials
	}
}

refresh_screen :: proc(editor: ^Editor, sb: ^strings.Builder) {
	strings.builder_reset(sb)

	strings.write_string(sb, HIDE_CURSOR)
	strings.write_string(sb, RESET_CURSOR_POSITION)

	editor_draw_rows(editor, sb)

	buf: [32]u8
	cmd := fmt.bprintf(buf[:], "\x1b[%d;%dH", editor.cursorX + 1, editor.cursorY + 1)
	strings.write_string(sb, cmd)

	strings.write_string(sb, SHOW_CURSOR)

	os.write_string(os.stdout, strings.to_string(sb^))
}
