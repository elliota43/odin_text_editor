package main

import "core:strings"

main :: proc() {
	enable_raw_mode()
	enter_alt_screen()
	defer disable_raw_mode()
	defer exit_alt_screen()

	editor := editor_init()
	sb := new(strings.Builder)

	for {
		refresh_screen(editor, sb)
		if process_keypress(editor, read_key()) do break
	}
}
