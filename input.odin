package main


ctrl_key :: #force_inline proc(k: byte) -> byte {
	return k & 0x1f
}

Modifier :: enum u8 {
	Ctrl,
	Alt,
	Shift,
}

Mods :: bit_set[Modifier;u8]

Special :: enum u8 {
	Arrow_Left,
	Arrow_Right,
	Arrow_Up,
	Arrow_Down,
	Page_Up,
	Page_Down,
	Home,
	End,
	Delete,
	Backspace,
	Enter,
	Tab,
	Escape,
}

Key_Code :: union {
	rune,
	Special,
}

Key :: struct {
	code: Key_Code,
	mods: Mods,
}

special :: proc(s: Special, mods: Mods = {}) -> Key {
	return Key{code = s, mods = mods}
}

decode_byte :: proc(b: byte) -> Key {
	switch b {
	case 13:
		return special(.Enter)
	case 9:
		return special(.Tab)
	case 127:
		return special(.Backspace)
	case 1 ..= 26:
		return Key{code = rune('a' + b - 1), mods = {.Ctrl}}
	case:
		return rune_key(rune(b))
	}
}

process_keypress :: proc(editor: ^Editor, key: Key) -> (should_quit: bool) {
	switch code in key.code {
	case rune:
		if .Ctrl in key.mods && code == 'q' do return true

	case Special:
		#partial switch code {
		case .Arrow_Up, .Arrow_Down, .Arrow_Left, .Arrow_Right:
			move_cursor(editor, code)
		case .Page_Down, .Page_Up:
			dir: Special = code == .Page_Up ? .Arrow_Up : .Arrow_Down
			for _ in 0 ..< editor.screen_rows do move_cursor(editor, dir)
		case .Home:
			editor.cursorX = 0
		case .End:
			editor.cursorX = int(editor.screen_cols) - 1
		}
	}
	return
}
