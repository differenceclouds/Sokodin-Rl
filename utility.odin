package sokoban

import "core:fmt"


to_cstring :: proc(value: any) -> cstring {
	return fmt.ctprintf("%v", value) 
}

