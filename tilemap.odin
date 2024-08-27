package sokoban
import rl   "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:encoding/json"

Tilemap :: struct {
	name: string,
	texture: rl.Texture2D,
	w: f32,
	h: f32,
	offset: rl.Vector2,
	gutter: f32,
	tileCoords: []rl.Vector2,
	wallCoords: []rl.Vector2,
	options: TileRendererOptions
}

//These are the only tiles found in map files.
//Aside from Void these are the only tiles needed to describe gamestate of basic Sokoban.
Tile :: enum {
	Void,
	Wall,
	Player,
	PlayerOnGoal,
	Box,
	BoxOnGoal,
	Goal,
	Floor,

}

TileRenderer :: struct {
	baseLayerRects:		[64]rl.Rectangle,
	objectLayerRects:	[64]rl.Rectangle,

	// options: TileRendererOptions,
}

TileRendererOptions :: struct {
	disableVoidTile: bool,
	floorTileAsVoid: bool,
	renderBackgroundImage: bool,
	fixedPlayerRotation: bool,
	mirrorPlayerSprites: bool,
	playerTileStyle: PlayerTileStyle,
	defaultPlayerOnRest: bool,
	defaultZoom: f32,
	drawBlobWalls: bool,
}

//These are optional player "animation" tiles
//order is in increasing complexity of the tileset,
//so a simple tileset might just use the first 1-3 states.
PlayerTileStyle :: enum {
	TwoTile, //PlayerOnFloor, PlayerOnGoal
	SingleTile, //Single player sprite. hopefully on transparent.
	FourTileDirectional, //horizontal and vertical with goal tiles, use mirroring
	EightTileDirectional, //all four directions with , one pose
	SingleDirectionWithPoses, //Rotate sprite, use different push and walk poses
	TwoDirectionWithPoses, //horizontal and vertical sprites, mirror, with poses
	FourDirectionWithPoses, //all four directions, each with poses
}


//optional Wall tiles that follow the "blob" wang tile set
//UpperCase is edges, lowercase is corners
//bitwise
// https://web.archive.org/web/20230528015915/http://www.cr31.co.uk/stagecast/wang/blob.html
// WallTilesBlob :: enum {
// 	Isolated = 0,

//  Fill = 255,
//  Cross = 85,

// 	N = 1,
// 	ne = 2,
// 	E = 4,
// 	se = 8,
// 	S = 16,
// 	sw = 32,
// 	W = 64,
// 	nw = 128,

// 	// N = 1,
// 	// E = 4,
// 	// S =t 16,
// 	// W = 64,

// 	// NE = 5,
// 	// SE = 20,
// 	// SW = 80,
// 	// NW = 65,

// 	// NEne = 7,
// 	// SEse = 28,
// 	// SWsw = 112,
// 	// NWnw = 193,

// 	// NS = 17,
// 	// EW = 68,

// 	// NES = 21,
// 	// ESW = 84,
// 	// NSW = 81,
// 	// NEW = 69,
// }


WallTilesBlob :: enum {
	N,
	ne,
	E,
	se,
	S,
	sw,
	W,
	nw,
}

Blob_Set :: bit_set[WallTilesBlob]


	YASCTiles :: []rl.Vector2 {
		{3,2}, //void
		{1,3}, //wall
		{1,0}, //player
		{1,1}, //player on goal
		{2,0}, //box
		{2,1}, //box on goal
		{0,1}, //goal
		{0,0}, //floor

		{1,0}, //player resting
		{1,0}, //player walking
		{1,0}, //player pushing neutral
		{1,0}, //player walking odd frame
		{1,0}, //player pushing even frame
		{1,0}, //player pushing odd frame,

		{0,4}, //player Up
		{3,4}, //player Right
		{2,4}, //player Down
		{1,4}, //player Left

		{0,5}, //player on goal, Up
		{3,5}, //player on goal, Right
		{2,5}, //player on goal, Down
		{1,5}, //player on goal, Left
	}

YASCWallTiles :: []rl.Vector2 {
	{0,2}, // NESW
	{1,2}, // EW
	{2,2}, // Fill
	{0,3}, // NS
	{1,3}, // Isolated
}

YASCOptions : TileRendererOptions = {
	fixedPlayerRotation = true,
	playerTileStyle = .EightTileDirectional,
	defaultZoom = 0,
	defaultPlayerOnRest = true,
	drawBlobWalls = false
}


RectFromCoord :: proc(coord: rl.Vector2, tilemap:Tilemap) -> rl.Rectangle {
	using tilemap
	return {
		offset.x + coord.x * (w + gutter),
		offset.y + coord.y * (h + gutter),
		w,
		h
	}
}




//Game draws on 2 layers, but data is one layer.
SetTileRenderer :: proc(tilemap: Tilemap) -> TileRenderer{
	tr: TileRenderer = {}


	voidIndex : int = 0
	voidRect : rl.Rectangle = {}

	if tilemap.options.floorTileAsVoid {
		voidIndex = 7
	} else {
		voidIndex = 0
	}

	if tilemap.options.disableVoidTile {
		voidRect = {}
	} else {
		voidRect = RectFromCoord(tilemap.tileCoords[voidIndex], tilemap)
	}


	tr.baseLayerRects[0] = voidRect //void
	tr.baseLayerRects[1] = RectFromCoord(tilemap.tileCoords[1], tilemap) //wall
	tr.baseLayerRects[2] = RectFromCoord(tilemap.tileCoords[7], tilemap) //player, draw floor
	tr.baseLayerRects[3] = RectFromCoord(tilemap.tileCoords[6], tilemap) //player on goal, draw goal
	tr.baseLayerRects[4] = RectFromCoord(tilemap.tileCoords[7], tilemap) //box, draw floor
	tr.baseLayerRects[5] = RectFromCoord(tilemap.tileCoords[6], tilemap) //boxongoal, draw goal
	tr.baseLayerRects[6] = RectFromCoord(tilemap.tileCoords[6], tilemap) //goal
	tr.baseLayerRects[7] = RectFromCoord(tilemap.tileCoords[7], tilemap) //floor

	for i:int = 0; i < len(tilemap.tileCoords); i += 1 {
		tr.objectLayerRects[i] = RectFromCoord(tilemap.tileCoords[i], tilemap)
	}

	return tr
}


MultiSheet :: struct {
	texture: rl.Texture2D,

}

// LoadTilemapFromSheet :: proc(sheet: MultiSheet) -> Tilemap {

// }

InitSheets :: #force_inline proc(sheet: string tilemaps: ^[dynamic]Tilemap) {

	sheet0 := rl.LoadTexture(
		strings.clone_to_cstring(strings.concatenate({
		"./tilesets/sheets/", sheet, ".png"
	})))
	
	data, ok := os.read_entire_file_from_filename(strings.concatenate({
		"./tilesets/sheets/", sheet, ".json"
	}))
	if !ok {
		fmt.eprintln("Couldn't load sheet")
		return
	}

	// defer delete(data)

	jason_data, err := json.parse(data)
	if err != .None {
		fmt.eprintln("couldn't parse json")
		fmt.eprintln("Error:", err)
	}
	// defer json.destroy_value(jason_data)

	frames := jason_data.(json.Object)["frames"].(json.Array)

	for o in frames {
		// fmt.println(o)
		object := o.(json.Object)
		rect := object["frame"].(json.Object)

		append(tilemaps, Tilemap {
			object["filename"].(json.String),
			sheet0,
			f32(rect["w"].(json.Float) / 4),
			f32(rect["h"].(json.Float) / 8),
			{f32(rect["x"].(json.Float)), f32(rect["y"].(json.Float))},
			0,
			YASCTiles, 
			YASCWallTiles,
			YASCOptions,
		})
	}

}


LoadVariousTilemaps :: #force_inline proc() -> [dynamic]Tilemap {
	tilemaps : [dynamic]Tilemap = {}


	shoveIt := Tilemap {
		"ShoveIt.png",
		rl.LoadTexture("./tilesets/ShoveIt.png"),
		24, 24,
		{4, 4},
		4,
		{
			{5,3}, //void
			{6,2}, //wall
			{0,0}, //player
			{1,0}, //player on goal
			{2,1}, //box
			{3,1}, //box on goal
			{5,2}, //goal
			{4,2}, //floor

			{1,0}, //player resting
			{0,0}, //player walking
			{4,0}, //player pushing neutral
			{2,0}, //player walking odd frame
			{3,0}, //player pushing even frame
			{5,0}, //player pushing odd frame
		}, {},
		{
			disableVoidTile = false,
			floorTileAsVoid = false,
			renderBackgroundImage = false,
			fixedPlayerRotation = false,
			playerTileStyle = .SingleDirectionWithPoses,
			// defaultZoom = 2,
		}
	}
	append(&tilemaps, shoveIt)


	sokobanPerfect := Tilemap {
		"Sokoban Perfect.png",
		rl.LoadTexture("./tilesets/Sokoban Perfect.png"),
		40, 54,
		{4, 4},
		4,
		{
			{5,0}, //void
			{2,0}, //wall
			{4,1}, //player
			{4,1}, //player on goal
			{3,0}, //box
			{4,0}, //box on goal
			{1,0}, //goal
			{0,0}, //floor

			{4,1}, //player resting
			{3,1}, //player walking
			{4,2}, //player pushing neutral
			{5,1}, //player walking odd frame
			{5,2}, //player pushing even frame
			{3,2}, //player pushing odd frame

			{4,1}, //player
			{4,1}, //player
			{4,1}, //player
			{4,1}, //player

			{4,1}, //player
			{4,1}, //player
			{4,1}, //player
			{4,1}, //player

			{4,1}, // player Up resting
			{3,1}, // player Up walking even
			{4,2}, // player Up pushing neutral
			{5,1}, // player Up walking odd
			{5,2}, // player Up pushing even
			{3,2}, // player Up pushing odd

			{1,1}, // player Right resting
			{0,1}, // player Right walking even
			{1,2}, // player Right pushing neutral
			{2,1}, // player Right walking odd
			{2,2}, // player Right pushing even
			{0,2}, // player Right pushing odd

			{4,1}, // player Down resting
			{3,1}, // player Down walking even
			{4,2}, // player Down pushing neutral
			{5,1}, // player Down walking odd
			{5,2}, // player Down pushing even
			{3,2}, // player Down pushing odd

			{1,1}, // player Left resting
			{0,1}, // player Left walking even
			{1,2}, // player Left pushing neutral
			{2,1}, // player Left walking odd
			{2,2}, // player Left pushing even
			{0,2}, // player Left pushing odd
		}, {},
		{
			playerTileStyle = .TwoDirectionWithPoses,
			fixedPlayerRotation = true,
			mirrorPlayerSprites = true,
		}
	}
	append(&tilemaps, sokobanPerfect)
	
	// sneezingTiger := Tilemap {
	// 	"sneezing_tiger.png",
	// 	rl.LoadTexture("./tilesets/sneezing_tiger.png"),
	// 	16, 16,
	// 	{0, 0},
	// 	0,
	// 	{
	// 		{0,0},
	// 		{6,0},
	// 		{2,7},
	// 		{3,7},
	// 		{0,7},
	// 		{1,7},
	// 		{4,7},
	// 		{0,6},
	// 	}, {},
	// 	{}
	// }
	// append(&tilemaps, sneezingTiger)

	Chip2 := Tilemap {
		"chip2.png",
		rl.LoadTexture("./tilesets/chip2.png"),
		32, 32,
		{0, 0},
		0,
		YASCTiles, YASCWallTiles,
		YASCOptions
	}
	append(&tilemaps, Chip2)


	return tilemaps
}
