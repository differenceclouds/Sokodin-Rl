package sokoban

import rl "vendor:raylib"

showSetSelect : bool
collectSets : bool

set_result :i32

draw_gui :: proc(window: Window) {

		if rl.GuiDropdownBox({24,24,144,24}, "#16#select map set", &set_result, false) {
			collectSets = false
		}


}