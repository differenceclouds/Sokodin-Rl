package sokoban
import rl "vendor:raylib"



GetBlobIndex :: proc(cardinalV, corner, cardinalH: bool) -> int {
	if cardinalV && corner && cardinalH {
		return 2
	} else {
		if cardinalV {
			if cardinalH {
				return 0
			} else {
				return 3
			}
		} else {
			if cardinalH {
				return 1
			} else {
				return 4
			}
		}
	}
}

draw_blob_wall :: proc(world: World, tilemap: Tilemap,index: i32, x:i32, y:i32) {
	Quad_Offsets : [4]rl.Vector2 = {
		{0,0}, {1, 0}, {1,1}, {0, 1}
	}
	tileN := world.tiles[index - world.width] == .Wall
	tileNE := world.tiles[index - world.width + 1] == .Wall
	tileE := world.tiles[index + 1] == .Wall
	tileSE := world.tiles[index + world.width + 1] == .Wall
	tileS := world.tiles[index + world.width] == .Wall
	tileSW := world.tiles[index + world.width - 1] == .Wall
	tileW := world.tiles[index - 1] == .Wall
	tileNW := world.tiles[index - world.width - 1] == .Wall

	blob_indexes : [4]int

	blob_indexes[0] = GetBlobIndex(tileN, tileNW, tileW)
	blob_indexes[1] = GetBlobIndex(tileN, tileNE, tileE)
	blob_indexes[2] = GetBlobIndex(tileS, tileSE, tileE)
	blob_indexes[3] = GetBlobIndex(tileS, tileSW, tileW)

	source_rects : [4]rl.Rectangle
	for &r, i in source_rects {
		r = RectFromCoord(tilemap.blobCoords[blob_indexes[i]], tilemap)
		r.width /= 2
		r.height /= 2
		r.x += Quad_Offsets[i].x * r.width
		r.y += Quad_Offsets[i].y * r.height
		dest_rect := rl.Rectangle {
			f32(x) * tilemap.w + Quad_Offsets[i].x * r.width,
			f32(y) * tilemap.h + Quad_Offsets[i].y * r.height,
			tilemap.w/2,
			tilemap.h/2,
		}
		rl.DrawTexturePro(tilemap.texture, r, dest_rect, {tilemap.w/2,tilemap.h/2}, 0, rl.WHITE)

	}
}