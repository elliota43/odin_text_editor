package main

ctrl_key :: #force_inline proc(k: byte) -> byte {
	return k & 0x1f
}
