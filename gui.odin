package sokoban

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:slice"


GuiData :: struct {
	font: rl.Font,
	edit_mode: bool,
	set_result: i32,
	change_set: bool,
	show_controls: bool,
	sets_param: cstring,
	tilemap_inc: bool,
	tilemap_dec: bool,
	randomize: bool,
}


GetSetsParam :: proc(set_of_sets: []string) -> cstring {
	set_titles := make([]string, len(set_of_sets))
	defer delete(set_titles)
	for set, i in set_of_sets {
		set_titles[i] = get_set_title(set)
	}
	j := strings.join(set_titles[:], ";")
	defer delete (j)
	return to_cstring(j)
}

InitGui :: proc(set_of_sets: []string, set_index: int) -> GuiData {
	// rl.GuiLoadStyle("./rgui/style_sunny.rgs")
	// rl.GuiSetStyle(.STATUSBAR, .TEXT_ALIGNMENT, .TEXT_ALIGN_CENTER)

	return GuiData {
		font = rl.GuiGetFont(),
		set_result = i32(set_index),
		sets_param = GetSetsParam(set_of_sets),
		randomize = false
	}
}

unit : f32 = 24
pad : f32 = 2

DrawGui :: proc(window: ^Window, data: ^GuiData) {
	using data


	//FROM LEFT
	w:f32 = f32(window.width / 2) * 2

	x:f32 = pad
	r:f32 = w - pad
	y:f32 = -1

	// rl.GuiStatusBar({x, y, f32(rl.MeasureText(window.title, 14)), unit}, window.title)
	statusbar_width := rl.MeasureTextEx(font, window.title, 18, 0)
	rl.GuiStatusBar({x, y, statusbar_width[0], unit}, window.title)

	// // c:f32 = f32(window.width / 2)

	// //close
	// if rl.GuiButton({pad,pad,unit,unit}, "#159#") {
	// 	rl.CloseWindow()
	// }

	// x += unit + pad

	// //minimize
	// if rl.GuiButton({x,pad,unit, unit}, "#120#") {
	// 	rl.MinimizeWindow()
	// }

	// x += unit + pad

	// //fullscreen
	// if rl.GuiButton({x,pad,unit, unit}, "#069#") {
	// 	if rl.IsWindowMaximized() do rl.RestoreWindow()
	// 	else do rl.MaximizeWindow()

	// 	window.resize_flag = true
	// }

	// x += unit + pad



	//FROM RIGHT


	if rl.GuiDropdownBox({r - unit*6, y, unit*6, unit}, sets_param, &set_result, edit_mode) {
		edit_mode = !edit_mode
		change_set = true
	}
	r -= unit*6 + pad

	if rl.GuiButton({r - unit*6, y, unit*6, unit}, "#191#Show Controls") do show_controls = true
	r -= unit*6 + pad


	if rl.GuiButton({r - unit, y, unit, unit}, "#119#") do tilemap_inc = true
	r -= unit + pad

	if rl.GuiButton({r - unit, y, unit, unit}, "#118#") do tilemap_dec = true
	r -= unit + pad

	if !randomize {
		if rl.GuiButton({r - unit, y, unit, unit}, "#62#") do randomize = !randomize
	} else {
		if rl.GuiButton({r - unit, y, unit, unit}, "#78#") do randomize = !randomize
	}
	r -= unit + pad

	//FROM CENTER

	// max: f32 = w - x - (w-r)
	// c :f32 = (max / 2) + x

	// // tw := clamp(unit*6, 24, max)
	// if rl.GuiButton({x, pad, max, unit}, window.title) do show_controls = true





	//FLOTING

	if show_controls {
		result := rl.GuiMessageBox({ f32(window.width) / 2 - 125, f32(window.height) / 2 - 100, 250, 200 }, "",controls_message,"OK")
		if result >= 0 do show_controls = false
	}
}

controls_message :: 
`Move: Arrow Keys
Restart: R
Undo: Z
Zoom: +/-
Advance: Space
Next/Prev Level: []`
