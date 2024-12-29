package tinyfiledialogs

import "core:fmt"
import "core:c"

foreign import tinyfiledialogs {
	"./macos/libtinyfiledialogs.dylib",
}

@(default_calling_convention="c", link_prefix="tfd")
foreign tinyfiledialogs {
	tinyfd_notifyPopup :: proc(aTitle: cstring, aMessage: cstring, aIconType: cstring) -> i32 ---
}