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
	set_filenames: []string,
	tilemap_inc: bool,
	tilemap_dec: bool,
	puzzle_inc: bool,
	puzzle_dec: bool,
	randomize: bool,
	undo: bool,
	reset: bool,
	mute: bool,
	zoom_in: bool,
	zoom_out: bool,
	set_info_window: bool,
	set_panel: ScrollPanel,
	set_panel_font: rl.Font,
}


ScrollPanel :: struct {
	scroll_view: rl.Rectangle,
	scroll_offset: rl.Vector2,
	bounds_offset : rl.Vector2,
	content_size : rl.Vector2,
	panel_text: cstring,
	panel_title: cstring
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


InitGui :: proc(set_of_sets: []string, set_index: int, info_font: rl.Font) -> GuiData {

	gui_data := GuiData {
		font = rl.GuiGetFont(),
		set_filenames = set_of_sets,
		set_result = i32(set_index),
		sets_param = GetSetsParam(set_of_sets),
		randomize = false,
		set_panel_font = info_font
	}
	return gui_data
}



DrawMainMenu :: proc(window: Window, data: ^GuiData) {

}

DrawGui :: proc(window: ^Window, data: ^GuiData, tilemap: Tilemap) {
	unit : f32 = 24
	pad : f32 = 4
	using data


	//FROM LEFT
	w:f32 = f32(window.width / 2) * 2

	x:f32 = 8
	r:f32 = w - pad - 8
	y:f32 = -1

	if rl.GuiButton({x, y, unit, unit}, "#129#") do puzzle_dec = true
	x += unit

	if rl.GuiButton({x, y, unit, unit}, "#134#") do puzzle_inc = true
	x += unit + pad

	statusbar_width := rl.MeasureTextEx(font, window.title, 16, 0)[0] + 16
	rl.GuiStatusBar({x, y, statusbar_width, unit}, window.title)
	x += statusbar_width + pad


	//FROM BOTTOM LEFT

	bottom := f32(window.height - 22)
	x = 8
	if rl.GuiButton({x, bottom, unit, unit}, "#118#") do tilemap_dec = true
	x += unit

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
		if set_info_window do UpdateSetPanel(data)
	}
	r -= unit*6
	if rl.GuiButton({r - unit, y, unit, unit}, "#15#") {
		if !set_info_window {
			UpdateSetPanel(data)
			set_info_window = true
		} else {
			set_info_window = false
		}
	}
	r -= unit + pad

	if rl.GuiButton({r - unit, y, unit, unit}, "#224#") do zoom_in = true
	r -= unit
	if rl.GuiButton({r - unit, y, unit, unit}, "#225#") do zoom_out = true
	r -= unit + pad

	if !mute {
		if rl.GuiButton({r - unit, y, unit, unit}, "#122#") do mute = true
	} else {
		if rl.GuiButton({r - unit, y, unit, unit}, "#220#") do mute = false
	}
	r -= unit + pad
	if rl.GuiButton({r - unit, y, unit, unit}, "#193#") {
		if !show_controls do show_controls = true
		else do show_controls = false
	}
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

	if set_info_window {
		panel_width := f32(min((window.width - 60), 600))
		panel_rect := rl.Rectangle{30, 30, panel_width, f32(window.height - 60)}
		if rl.GuiWindowBox(panel_rect, set_panel.panel_title) != 0 {
			set_info_window = false
		}
		content_rect := rl.Rectangle{0,0,set_panel.content_size.x + 8,set_panel.content_size.y + 8}
		scrollbounds := panel_rect
		scrollbounds.y += 24
		scrollbounds.height -= 24
		scrollbounds.width -= set_panel.bounds_offset.x
		scrollbounds.height -= set_panel.bounds_offset.y
		rl.GuiScrollPanel(scrollbounds, nil, content_rect, &set_panel.scroll_offset, &set_panel.scroll_view)
		
		content_position:= rl.Vector2{set_panel.scroll_offset.x, set_panel.scroll_offset.y} + {scrollbounds.x, scrollbounds.y} + {4, 4}
		scissor_width := i32(scrollbounds.width)
		scissor_height := i32(scrollbounds.height)
		if content_rect.width > scrollbounds.width - 24 {
			scissor_height -= 14
		}
		if content_rect.height > scrollbounds.height - 24 {
			scissor_width -= 14
		}
		rl.BeginScissorMode(i32(scrollbounds.x), i32(scrollbounds.y), scissor_width, scissor_height)
		rl.DrawTextEx(set_panel_font, set_panel.panel_text, content_position, 14, 0, rl.BLACK)
		rl.EndScissorMode()
	}

}

UpdateSetPanel :: proc(gui_data: ^GuiData) {
	using gui_data
	file := strings.concatenate({"./levels/", set_filenames[set_result]})
	defer delete(file)
	if data, ok := os.read_entire_file(file); ok {
		delete(set_panel.panel_text)
		set_panel.panel_text = cstring(raw_data(data))
		set_panel.content_size = rl.MeasureTextEx(set_panel_font, set_panel.panel_text, 14, 0)
		set_panel.panel_title = fmt.ctprint(filepath.stem(file))
	} else {
		fmt.println("couldn't read file", file)
	}
}


controls_message :: 
"Move: Arrow Keys\nRestart: R\nUndo: Z\nZoom: +/-\nAdvance: Space\nNext/Prev Level: brackets"
