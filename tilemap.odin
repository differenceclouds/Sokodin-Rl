package sokoban
import rl   "vendor:raylib"

Tilemap :: struct {
	texture: rl.Texture2D,
	w: f32,
	h: f32,
	margin: f32,
	gutter: f32,
	tileCoords: []rl.Vector2
}




RectFromCoord :: proc(coord: rl.Vector2, tilemap:Tilemap) -> rl.Rectangle {
	using tilemap
	return {
		gutter + coord.x * (w + gutter),
		gutter + coord.y * (h + gutter),
		w,
		h
	}
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

//These are optional player "animation" tiles
//order is in increasing complexity of the tileset,
//so a simple tileset might just use the first 1-3 states.
PlayerTiles :: enum {
	//North-facing or non-directional
	resting,
	walking,
	pushing, //pushingNeutral

	walkingOdd,
	pushingEven,
	pushingOdd,

	//East-facing or second of two-directional
	restingEast,
	walkingEast,
	pushingEast,

	walkingOddEast,
	pushingEvenEast,
	pushingOddEast,

	//South-facing or third of four-directional
	restingSouth,
	walkingSouth,
	pushingSouth,

	walkingOddSouth,
	pushingEvenSouth,
	pushingOddSouth,

	//West-facing or fourth of four-directional
	restingWest,
	walkingWest,
	pushingWest, //pushingNeutral

	walkingOddWest,
	pushingEvenWest,
	pushingOddWest,
}


//optional Wall tiles that follow the "blob" wang tile set
//UpperCase is edges, lowercase is corners
//bitwise
// https://web.archive.org/web/20230528015915/http://www.cr31.co.uk/stagecast/wang/blob.html
WallTilesBlob :: enum {
	Void = 0,

	Wall = 255,

	N = 1,
	ne = 2,
	E = 4,
	se = 8,
	S = 16,
	sw = 32,
	W = 64,
	nw = 128,

	// N = 1,
	// E = 4,
	// S = 16,
	// W = 64,

	// NE = 5,
	// SE = 20,
	// SW = 80,
	// NW = 65,

	// NEne = 7,
	// SEse = 28,
	// SWsw = 112,
	// NWnw = 193,

	// NS = 17,
	// EW = 68,

	// NES = 21,
	// ESW = 84,
	// NSW = 81,
	// NEW = 69,
}


TileRenderer :: struct {
	baseLayerRects:		[]rl.Rectangle,
	objectLayerRects:	[]rl.Rectangle,
	options: TileRendererOptions,
}

TileRendererOptions :: struct {
	disableVoidTile: bool,
	floorTileAsVoid: bool,
	renderBackgroundImage: bool,
}


//Game draws on 2 layers, but data is one layer.
SetTileRenderer :: #force_inline proc(tilemap: Tilemap, _options: TileRendererOptions) -> TileRenderer {
	tr: TileRenderer = {options = _options}

	voidIndex : int
	voidRect : rl.Rectangle

	if _options.floorTileAsVoid {
		voidIndex = 7
	} else {
		voidIndex = 0
	}

	if _options.disableVoidTile {
		voidRect = {}
	} else {
		voidRect = RectFromCoord(tilemap.tileCoords[voidIndex], tilemap)
	}


	tr.baseLayerRects = []rl.Rectangle {
		voidRect, //void
		RectFromCoord(tilemap.tileCoords[1], tilemap), //wall
		RectFromCoord(tilemap.tileCoords[7], tilemap), //player, draw floor
		RectFromCoord(tilemap.tileCoords[6], tilemap), //player on goal, draw goal
		RectFromCoord(tilemap.tileCoords[7], tilemap), //box, draw floor
		RectFromCoord(tilemap.tileCoords[6], tilemap), //boxongoal, draw goal
		RectFromCoord(tilemap.tileCoords[6], tilemap), //goal
		RectFromCoord(tilemap.tileCoords[7], tilemap), //floor
		{},
		{},
		{},
		{},
		{},
		{},
	}

	tr.objectLayerRects = []rl.Rectangle {
		{}, //void
		{}, //wall
		RectFromCoord(tilemap.tileCoords[2], tilemap), //player
		RectFromCoord(tilemap.tileCoords[3], tilemap), //player on goal
		RectFromCoord(tilemap.tileCoords[4], tilemap), //box
		RectFromCoord(tilemap.tileCoords[5], tilemap), //boxongoal
		{}, //goal
		{}, //floor
		RectFromCoord(tilemap.tileCoords[8], tilemap), //resting
		RectFromCoord(tilemap.tileCoords[9], tilemap), //walking
		RectFromCoord(tilemap.tileCoords[10], tilemap), //pushing
		RectFromCoord(tilemap.tileCoords[11], tilemap), //walkingOdd
		RectFromCoord(tilemap.tileCoords[12], tilemap), //pushingEven
		RectFromCoord(tilemap.tileCoords[13], tilemap), //pushingOdd
	}
	return tr
}
