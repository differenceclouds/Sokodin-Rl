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
	puzzle_inc: bool,
	puzzle_dec: bool,
	randomize: bool,
	undo: bool,
	reset: bool,
	mute: bool,
	zoom_in: bool,
	zoom_out: bool
}


GetSetsParam :: proc(set_of_sets: []string) -> cstring {
	set_titles := make([]string, len(set_of_sets))
	defer delete(set_titles)
	for set, i in set_of_sets {
		set_titles[i] = get_set_title(set)
	}
	j := strings.join(set_titles[:], ";")
	defer delete (j)
	return fmt.ctprint(j)
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



DrawMainMenu :: proc(window: Window, data: ^GuiData) {

}

DrawGui :: proc(window: Window, data: ^GuiData, tilemap: Tilemap) {
	unit : f32 = 24
	pad : f32 = 2
	using data


	//FROM LEFT
	w:f32 = f32(window.width / 2) * 2

	x:f32 = 8
	r:f32 = w - pad - 8
	y:f32 = -1

	if rl.GuiButton({x, y, unit, unit}, "#129#") do puzzle_dec = true
	x += unit + pad

	if rl.GuiButton({x, y, unit, unit}, "#134#") do puzzle_inc = true
	x += unit + pad

	// rl.GuiStatusBar({x, y, f32(rl.MeasureText(window.title, 14)), unit}, window.title)
	statusbar_width := rl.MeasureTextEx(font, window.title, 16, 0)[0] + 16
	rl.GuiStatusBar({x, y, statusbar_width, unit}, window.title)

	bottom := f32(window.height - 22)
	x = 8
	if rl.GuiButton({x, bottom, unit, unit}, "#118#") do tilemap_dec = true
	x += unit + pad

	if rl.GuiButton({x, bottom, unit, unit}, "#119#") do tilemap_inc = true
	x += unit + pad

	if !randomize {
		if rl.GuiButton({x, bottom, unit, unit}, "#62#") do randomize = !randomize
	} else {
		if rl.GuiButton({x, bottom, unit, unit}, "#78#") do randomize = !randomize
	}
	x += unit + pad

	tilemap_name_size := rl.MeasureTextEx(font, tilemap.name, 16, 0)[0] + 16
	rl.GuiStatusBar({x, bottom, tilemap_name_size, unit}, tilemap.name)

	//FROM RIGHT


	if rl.GuiDropdownBox({r - unit*6, y, unit*6, unit}, sets_param, &set_result, edit_mode) {
		edit_mode = !edit_mode
		change_set = true
	}
	r -= unit*6 + pad
	if rl.GuiButton({r - unit, y, unit, unit}, "#224#") do zoom_in = true
	r -= unit + pad
	if rl.GuiButton({r - unit, y, unit, unit}, "#225#") do zoom_out = true
	r -= unit + pad

	if !mute {
		if rl.GuiButton({r - unit, y, unit, unit}, "#122#") do mute = true
	} else {
		if rl.GuiButton({r - unit, y, unit, unit}, "#220#") do mute = false
	}
	r -= unit + pad
	if rl.GuiButton({r - unit, y, unit, unit}, "#191#") do show_controls = true
	r -= unit + pad
	if rl.GuiButton({r - unit, y, unit, unit}, "#72#") do undo = true
	r -= unit + pad
	if rl.GuiButton({r - unit, y, unit, unit}, "#152#") do reset = true
	r -= unit + pad


	//FLOTING

	if show_controls {
		result := rl.GuiMessageBox({ f32(window.width) / 2 - 125, f32(window.height) / 2 - 100, 250, 200 }, "",controls_message,"OK")
		if result >= 0 do show_controls = false
	}
}

controls_message :: 
"Move: Arrow Keys\nRestart: R\nUndo: Z\nZoom: +/-\nAdvance: Space\nNext/Prev Level: brackets"
