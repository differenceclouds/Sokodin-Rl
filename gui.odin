package sokoban

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:slice"


GuiData :: struct {
	edit_mode: bool,
	set_result: i32,
	change_set: bool,
	show_controls: bool,
	sets_param: cstring,
	tilemap_inc: bool,
	tilemap_dec: bool,
}


// GetSetsParam :: proc(file_list: []os.File_Info) -> cstring {
// 	filenames := [dynamic]string {}



// 	for fi in file_list {
// 		if !fi.is_dir && !strings.has_prefix(fi.name, ".") {
// 			// fmt.printfln(fi.name)
// 			append(&filenames, strings.trim_suffix(fi.name, ".txt"))
// 		}
// 	}
// 	slice.sort(filenames[:])
// 	inject_at(&filenames,0, "SELECT LEVEL SET")
// 	return strings.clone_to_cstring(strings.join(filenames[:], ";"))
// }

GetSetsParam :: proc(set_of_sets: []string) -> cstring {
	set_titles := make([dynamic]string, len(set_of_sets))
	defer delete(set_titles)
	for set, i in set_of_sets {
		set_titles[i] = strings.trim_suffix(set, ".txt")
	}
	return strings.clone_to_cstring(strings.join(set_titles[:], ";"))
}

InitGui :: proc(set_of_sets: []string, set_index: int) -> GuiData {
	// rl.GuiLoadStyle("./rgui/style_sunny.rgs")
	return GuiData {
		set_result = i32(set_index),
		sets_param = GetSetsParam(set_of_sets)
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


	if rl.GuiDropdownBox({r - unit*6, pad, unit*6, unit}, sets_param, &set_result, edit_mode) {
		edit_mode = !edit_mode
		change_set = true
	}
	r -= unit*6 + pad

	if rl.GuiButton({r - unit*6, pad, unit*6, unit}, "#191#Show Controls") do show_controls = true
	r -= unit*6 + pad


	if rl.GuiButton({r - unit, pad, unit, unit}, "#119#") do tilemap_inc = true
	r -= unit + pad

	if rl.GuiButton({r - unit, pad, unit, unit}, "#118#") do tilemap_dec = true
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
