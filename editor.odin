package main

import "core:fmt"

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
