package sokoban
import "core:fmt"

import "core:log"
import "core:mem"

DEBUG_MEM :: true

main :: proc() {
	tracking_allocator : mem.Tracking_Allocator
	when DEBUG_MEM {
		context.logger = log.create_console_logger()
		default_allocator := context.allocator
		mem.tracking_allocator_init(&tracking_allocator, default_allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)
		reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
			err := false

			for _, value in a.allocation_map {
				fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
				err = true
			}

			mem.tracking_allocator_clear(a)
			return err
		}
	}
	run_game()


	when DEBUG_MEM {
		if len(tracking_allocator.bad_free_array) > 0 {
			for b in tracking_allocator.bad_free_array {
				log.errorf("Bad free at: %v", b.location)
			}
			panic("Bad free detected")
		}
		if reset_tracking_allocator(&tracking_allocator) {
		}
	}
	mem.tracking_allocator_destroy(&tracking_allocator)
}
