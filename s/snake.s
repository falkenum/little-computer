    j start
snk_addr:
    .word snk
key_times_addr:
    .word key_times
rand:
    .word 0000
foodx:
    .word 0000
foody:
    .word 0000
food_eaten:
    .word 0000
vga_write_addr:
    .word F80C
vga_vblank_addr:
    .word F80D
keys_addr:
    .word F80E
screen_width:
    .word 0280 ;640 in decimal
screen_height:
    .word 01E0 ;480 in decimal
bg_width:
    .word 0100
bg_height:
    .word 00C0
bg_x:
    .word 00C0
bg_y:
    .word 0090
colors_addr:
    .word colors
num_tiles:
    .word 0300
txrdy_addr:
    .word F80A
tx_addr:
    .word F80B
tx_count:
    .word 0000
zero_char:
    .string "0"
alpha_char:
    .string "A"
newline_char:
    .string "\n"
failed_msg_addr:
    .word failed_msg
begin_msg_addr:
    .word begin_msg
start:
    ; drawing the frame
    lw colors_addr r0 r1
    lw colors@frame r1 r1
    lw screen_width r0 r2
    lw screen_height r0 r3
    addi 0 r0 r4
    addi 0 r0 r5
    jl draw_rect
    jl reset_game

    j main
vblank_done:
    ; lw rand r0 r1
    ; jl print_hex_val

    ; update next_dir
    jl update_dir

    jl inc_key_times

    lw snk_addr r0 r1
    lw snk@move_frame_count r1 r2
    
    ; inc frame count
    addi 1 r2 r2
    sw snk@move_frame_count r1 r2

    addi 8 r0 r3
    beq moved_tile r2 r3
    j main
moved_tile:
    ; set dir = next_dir
    lw snk@next_dir r1 r2
    sw snk@dir r1 r2

    ; add 2 to tail index, mod buflen
    lw snk@tail_index r1 r2
    lw snk@tiles_queue_addr r1 r3
    add r2 r3 r3

    lw snk@expanding r1 r4
    addi 1 r0 r5
    beq reset_expanding r4 r5

    push r1
    push r2
    ; free old tail tile
    lw 0 r3 r1
    lw 1 r3 r2
    addi 0 r0 r3
    jl occupy_or_free_tile
    pop r2
    pop r1

    addi 2 r2 r2
    lw snk@tiles_queue_len r1 r3
    ; if new tail index is already less than buflen, then store it back
    blt moved_tile_store_tail r2 r3

    ; negate buflen and add to tail index
    not r3 r3
    addi 1 r3 r3
    add r2 r3 r2
    j moved_tile_store_tail
reset_expanding:
    sw snk@expanding r1 r0
moved_tile_store_tail:
    sw snk@tail_index r1 r2

    ; set new head data dependent on direction of movement
    ; get old head x,y in r2,r3
    lw snk@head_index r1 r6
    lw snk@tiles_queue_addr r1 r4
    add r6 r4 r4

    ; add 2 to head index and store back (mod buflen)
    addi 2 r6 r6
    lw snk@tiles_queue_len r1 r3
    ; if new head index is already less than buflen, then store it back
    blt moved_tile_store_head r6 r3

    ; negate buflen and add to head index
    not r3 r3
    addi 1 r3 r3
    add r6 r3 r6
moved_tile_store_head:
    sw snk@head_index r1 r6

    ; set head x and y values
    lw snk@dir r1 r2
    beq move_tile_right r2 r0
    addi 1 r0 r3
    beq move_tile_up r2 r3
    addi 2 r0 r3
    beq move_tile_left r2 r3
    addi 3 r0 r3
    beq move_tile_down r2 r3
move_tile_right:
    lw 0 r4 r2
    addi 8 r2 r2
    lw 1 r4 r3
    j end_move_tile
move_tile_up:
    lw 0 r4 r2
    lw 1 r4 r3
    addi -8 r3 r3
    j end_move_tile
move_tile_left:
    lw 0 r4 r2
    addi -8 r2 r2
    lw 1 r4 r3
    j end_move_tile
move_tile_down:
    lw 0 r4 r2
    lw 1 r4 r3
    addi 8 r3 r3
end_move_tile:

    ; update buf index with new head index
    add r6 r1 r5
    lw snk@tiles_queue_addr r1 r4
    add r6 r4 r4

    ; store back new head values
    sw 0 r4 r2
    sw 1 r4 r3

    push r1
    ; occupy new head tile
    addi 0 r2 r1
    addi 0 r3 r2
    addi 1 r0 r3

    jl occupy_or_free_tile
    pop r1

    ; reset frame count
    sw snk@move_frame_count r1 r0

    jl check_collision
    addi 1 r0 r2
    ; if r1 == 0, then go to main.
    blt main r1 r2
    ; if r1 == 1, reset game.
    beq collision_reset r1 r2
    ; else r1 == 2, food was eaten.
    sw food_eaten r0 r2
    
    lw snk_addr r0 r1
    sw snk@expanding r1 r2
    j main
collision_reset:
    jl reset_game
main:
    lw vga_vblank_addr r0 r1
    ; get vblank value
    lw 0 r1 r1
    ; if it's 0, loop and check again
    beq main_j r1 r0
    ; else handle the vblank
    jl vblank_handler
    j vblank_done
main_j:
    j main

update_food:
    push lr
    lw food_eaten r0 r1
    beq update_food_end r0 r1

    ; erase old food
    lw colors_addr r0 r1
    lw colors@bg r1 r1
    addi 8 r0 r2
    addi 8 r0 r3
    lw foodx r0 r4
    lw foody r0 r5
    jl draw_rect

    lw rand r0 r1
    lw snk_addr r0 r2
    lw snk@tiles_free_addr r2 r2
    add r1 r2 r2
    lw 0 r2 r1

    ; push r1
    ; jl print_hex_val
    ; pop r1

    jl tile_index_to_xy
    sw foodx r0 r1
    sw foody r0 r2

    ; draw new food
    addi 0 r1 r4
    addi 0 r2 r5
    addi 8 r0 r2
    addi 8 r0 r3
    lw colors_addr r0 r1
    lw colors@food r1 r1
    jl draw_rect

    sw food_eaten r0 r0
update_food_end:
    pop lr
    rts

reset_game:
    push lr
    ; draw the play area
    lw colors_addr r0 r1
    lw colors@bg r1 r1
    lw bg_width r0 r2
    lw bg_height r0 r3
    lw bg_x r0 r4
    lw bg_y r0 r5
    jl draw_rect

    ; need to initalize tiles_grid and tiles_free
    lw snk_addr r0 r1
    ; reset tiles_free_len to the max len
    lw num_tiles r0 r3

    sw snk@tiles_free_len r1 r3
    lw snk@tiles_grid_addr r1 r2
    lw snk@tiles_free_addr r1 r1


    ; tile count
    addi 0 r0 r5

tiles_init_loop:

    ; add tile count to grid addr, store tile count in that location
    add r5 r2 r6
    sw 0 r6 r5
    ; add tile count to free addr, store tile count in that location
    add r5 r1 r6
    sw 0 r6 r5

    addi 1 r5 r5

    ; if count < num_tiles, then loop 
    blt tiles_init_loop r5 r3
    ; jl run_tests

    ; initalizing snake
    lw snk_addr r0 r6
    ; tail at index 0
    sw snk@tail_index r6 r0
    addi 4 r0 r1
    ; head at index 4 (after x,y of first two tiles)
    sw snk@head_index r6 r1
    ; start with len 3
    addi 3 r0 r2
    sw snk@len r6 r2

    lw snk@start_x r6 r3
    lw snk@start_y r6 r4
    lw snk@tiles_queue_addr r6 r2

    ; store x,y for first tile
    sw 0 r2 r3
    sw 1 r2 r4

    push r2
    push r3
    push r4
    push r6
    addi 0 r3 r1
    addi 0 r4 r2
    addi 1 r0 r3
    jl occupy_or_free_tile
    pop r6
    pop r4
    pop r3
    pop r2

    ; store x,y for second tile
    addi 8 r3 r3
    sw 2 r2 r3
    sw 3 r2 r4

    push r2
    push r3
    push r4
    push r6
    addi 0 r3 r1
    addi 0 r4 r2
    addi 1 r0 r3
    jl occupy_or_free_tile
    pop r6
    pop r4
    pop r3
    pop r2

    ; store x,y for third tile
    addi 8 r3 r3
    sw 4 r2 r3
    sw 5 r2 r4

    push r6
    addi 0 r3 r1
    addi 0 r4 r2
    addi 1 r0 r3
    jl occupy_or_free_tile
    pop r6

    ; store 0 for dir and next_dir
    sw snk@dir r6 r0
    sw snk@next_dir r6 r0

    sw snk@expanding r6 r0

    ; draw first tile
    lw colors_addr r0 r1
    lw colors@snk r1 r1
    ; width and height of 8
    addi 8 r0 r2
    addi 8 r0 r3

    lw snk@tiles_queue_addr r6 r6
    ; loading x
    lw 0 r6 r4
    ; loading y
    lw 1 r6 r5

    push r1
    push r2
    push r3
    push r4
    push r5
    jl draw_rect
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1

    ; draw second tile
    addi 8 r4 r4
    jl draw_rect

    addi 1 r0 r1
    sw food_eaten r0 r1

    pop lr
    rts

run_tests:
    push lr
    lw begin_msg_addr r0 r1
    jl print

    lw snk_addr r0 r6
    lw snk@tiles_grid_addr r6 r3
    lw 0 r3 r1
    addi 0 r0 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw num_tiles r0 r1
    addi -1 r1 r1
    lw snk@tiles_grid_addr r6 r2
    add r2 r1 r2
    lw 0 r2 r2
    jl assert_eq

    ; tile x is 1
    lw bg_x r0 r1
    addi 8 r1 r1
    lw bg_y r0 r2
    addi 1 r0 r3
    jl occupy_or_free_tile

    ; tiles grid[1] == num tiles - 1
    ; tiles grid[numtiles-1] == 1
    ; tiles free[1] == num tiles - 1
    ; tiles free[numtiles-1] == 1

    lw snk_addr r0 r6
    lw snk@tiles_free_addr r6 r5
    addi 1 r5 r5
    lw 0 r5 r1
    lw num_tiles r0 r2
    addi -1 r2 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_free_addr r6 r5
    lw num_tiles r0 r2
    addi -1 r2 r2
    add r5 r2 r5
    lw 0 r5 r1
    addi 1 r0 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_grid_addr r6 r5
    addi 1 r5 r5
    lw 0 r5 r1
    lw num_tiles r0 r2
    addi -1 r2 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_grid_addr r6 r5
    lw num_tiles r0 r2
    addi -1 r2 r2
    add r5 r2 r5
    lw 0 r5 r1
    addi 1 r0 r2
    jl assert_eq

    lw bg_x r0 r1
    addi 16 r1 r1
    lw bg_y r0 r2
    addi 1 r0 r3
    jl occupy_or_free_tile

    lw bg_x r0 r1
    addi 8 r1 r1
    lw bg_y r0 r2
    addi 0 r0 r3
    jl occupy_or_free_tile

    lw bg_x r0 r1
    addi 0 r1 r1
    lw bg_y r0 r2
    addi 1 r0 r3
    jl occupy_or_free_tile

    lw bg_x r0 r1
    addi 16 r1 r1
    lw bg_y r0 r2
    addi 0 r0 r3
    jl occupy_or_free_tile

    lw bg_x r0 r1
    addi 8 r1 r1
    lw bg_y r0 r2
    addi 1 r0 r3
    jl occupy_or_free_tile

    lw snk_addr r0 r6
    lw snk@tiles_free_addr r6 r5
    lw 0 r5 r1
    addi 2 r0 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_free_addr r6 r5
    addi 1 r5 r5
    lw 0 r5 r1
    lw num_tiles r0 r2
    addi -1 r2 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_free_addr r6 r5
    addi 2 r5 r5
    lw 0 r5 r1
    lw num_tiles r0 r2
    addi -2 r2 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_grid_addr r6 r5
    lw 0 r5 r1
    lw num_tiles r0 r2
    addi -1 r2 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_grid_addr r6 r5
    addi 1 r5 r5
    lw 0 r5 r1
    lw num_tiles r0 r2
    addi -2 r2 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_grid_addr r6 r5
    lw num_tiles r0 r2
    addi -1 r2 r2
    add r5 r2 r5
    lw 0 r5 r1
    addi 1 r0 r2
    jl assert_eq
    
    lw snk_addr r0 r6
    lw snk@tiles_grid_addr r6 r5
    lw num_tiles r0 r2
    addi -2 r2 r2
    add r5 r2 r5
    lw 0 r5 r1
    addi 2 r0 r2
    jl assert_eq

    lw snk_addr r0 r6
    lw snk@tiles_free_addr r6 r5
    lw num_tiles r0 r2
    addi -1 r2 r2
    add r5 r2 r5
    lw 0 r5 r1
    addi 0 r0 r2
    jl assert_eq
    
    lw snk_addr r0 r6
    lw snk@tiles_free_addr r6 r5
    lw num_tiles r0 r2
    addi -2 r2 r2
    add r5 r2 r5
    lw 0 r5 r1
    addi 1 r0 r2
    jl assert_eq

    halt
    pop lr
    rts

; r1, r2
assert_eq:
    push lr
    beq assert_end r1 r2
assert_failed:
    lw failed_msg_addr r0 r1
    jl print
assert_end:
    pop lr
    rts


; r1: x
; r2: y
; return r1: index
xy_to_tile_index:
    ; first offset by start of play area
    lw bg_x r0 r3
    not r3 r3
    addi 1 r3 r3
    add r1 r3 r1

    lw bg_y r0 r3
    not r3 r3
    addi 1 r3 r3
    add r2 r3 r2

    ; generate tiles_grid index from x, y
    ; right shift 3 to get tile x
    addi -3 r0 r3
    ssl r1 r3 r1


    ; shift y val left 2 (or shift right 3 and left 5)
    addi 2 r0 r3
    ssl r2 r3 r2

    ; or y with x
    ; a | b == ~(~a & ~b)
    ; tile index (i) is put in r1
    not r1 r1
    not r2 r2
    and r1 r2 r1
    not r1 r1

    rts
; r1: tile index
; return r1: x, r2: y
tile_index_to_xy:
    addi 31 r0 r3
    addi 3 r0 r4
    addi 0 r1 r5

    ; get x tile and shift left 3
    and r5 r3 r3
    ssl r3 r4 r1

    ; shift y tile right 5 and then left 3
    addi -5 r0 r4
    ssl r5 r4 r5
    addi 3 r0 r4
    ssl r5 r4 r2

    ; offset by bg position
    lw bg_x r0 r3
    add r1 r3 r1
    lw bg_y r0 r3
    add r2 r3 r2

    rts

; r1: x
; r2: y
; r3: 1 for occupy, 0 for free
occupy_or_free_tile:
    push lr

    push r3
    jl xy_to_tile_index
    ; push r1
    ; jl print_hex_val
    ; pop r1
    pop r6
    
    lw snk_addr r0 r5
    lw snk@tiles_grid_addr r5 r4
    lw snk@tiles_free_addr r5 r3

    ; tiles_grid[i] = j is put in r2
    add r1 r4 r2
    lw 0 r2 r2


    ; swap tiles_free[j] and tiles_free[freelen-1]
    push r1
    push r2
    push r3
    push r4
    push r6
    ; tiles_free_addr + j
    add r3 r2 r1
    
    ; tiles_free_addr + freelen-1
    lw snk@tiles_free_len r5 r5
    beq first_free_swap r6 r0
    addi -1 r5 r5
first_free_swap:
    add r3 r5 r2

    jl swap_mem_vals
    pop r6
    pop r4
    pop r3
    pop r2
    pop r1

    ; swap tiles_grid[i] and tiles_grid[tiles_free[j]]
    ; tiles_grid_addr + i in r1
    add r1 r4 r1
    ; tiles_grid_addr + tiles_free[j] in r2
    add r3 r2 r2
    lw 0 r2 r2
    add r4 r2 r2

    push r6
    jl swap_mem_vals
    pop r6

    lw snk_addr r0 r1
    lw snk@tiles_free_len r1 r2
    beq freelen_inc r6 r0
    addi -1 r2 r2
    j end_freelen_modify
freelen_inc:
    addi 1 r2 r2
end_freelen_modify:
    sw snk@tiles_free_len r1 r2

    pop lr
    rts

; r1: addr 1
; r2: addr 2
; swaps the values at the given addresses
swap_mem_vals:
    lw 0 r1 r3
    lw 0 r2 r4
    sw 0 r1 r4
    sw 0 r2 r3
    rts


inc_key_times:

    lw key_times_addr r0 r2
    lw snk_addr r0 r3
    lw snk@tiles_free_len r0 r3

    not r3 r4
    addi -1 r4 r4

    ; add to key timers
    lw 0 r2 r1
    addi 7 r1 r1
    blt key0_mod r1 r3
    add r1 r4 r1
key0_mod:
    sw 0 r2 r1

    lw 1 r2 r1
    addi 7 r1 r1
    blt key1_mod r1 r3
    add r1 r4 r1
key1_mod:
    sw 1 r2 r1

    lw 2 r2 r1
    addi 7 r1 r1
    blt key2_mod r1 r3
    add r1 r4 r1
key2_mod:
    sw 2 r2 r1

    lw 3 r2 r1
    addi 7 r1 r1
    blt key3_mod r1 r3
    add r1 r4 r1
key3_mod:
    sw 3 r2 r1
    rts

check_collision:
    lw snk_addr r0 r1

    lw snk@head_index r1 r2
    lw snk@tiles_queue_addr r1 r3
    add r2 r3 r2

    ; check if x and y equal food x and y
    lw 0 r2 r3
    lw 1 r2 r4

    lw foodx r0 r5
    lw foody r0 r6
    beq food_collision_x r3 r5
    j food_collision_end
food_collision_x:
    beq food_collision_jump r4 r6
    j food_collision_end
food_collision_jump:
    j food_collision_found
food_collision_end:

;     ; check if x,y matches tile in snake
;     push r1
;     push r2
;     addi 0 r3 r1
;     addi 0 r4 r2
;     jl xy_to_tile_index
;     lw snk_addr r0 r2
;     lw snk@tiles_grid_addr r2 r3
;     add r1 r3 r1
;     lw 0 r1 r4

;     ; if tiles_free index is greater than its length, then the tile is occupied
;     lw snk@tiles_free_len r2 r3

;     push r3
;     addi 0 r4 r1
;     jl print_hex_val
;     pop r3
;     addi 0 r3 r1
;     jl print_hex_val

;     pop r2
;     pop r1

;     blt tile_not_occupied r4 r3
;     j collision_found
; tile_not_occupied:

    lw snk@dir r1 r3

    ; check the side in the direction of motion
    beq check_right_collision r3 r0
    addi 1 r0 r4
    beq check_up_collision r3 r4
    addi 2 r0 r4
    beq check_left_collision r3 r4
    addi 3 r0 r4
    beq check_down_collision r3 r4

check_right_collision:
    ; right side: check if head x >= bg_x + bg_width
    ; load x into r3
    lw 0 r2 r3
    ; bg_x + bg_width into r4
    lw bg_x r0 r4
    lw bg_width r0 r5
    add r4 r5 r4
    blt collision_not_found r3 r4
    j collision_found
check_up_collision:
    ; up side: check if head y < bg_y
    lw 1 r2 r3
    lw bg_y r0 r4
    blt collision_found r3 r4
    j collision_not_found
check_left_collision:
    ; left side: check if head x < bg_x
    lw 0 r2 r3
    lw bg_x r0 r4
    blt collision_found r3 r4
    j collision_not_found
check_down_collision:
    ; down side: check if head y >= bg_y + bg_height
    ; load x into r3
    lw 1 r2 r3
    ; bg_x + bg_width into r4
    lw bg_y r0 r4
    lw bg_height r0 r5
    add r4 r5 r4
    blt collision_not_found r3 r4
    j collision_found


    ; if collision, return 1
collision_found:
    addi 1 r0 r1
    j check_collision_end
food_collision_found:
    addi 2 r0 r1
    j check_collision_end
collision_not_found:
    addi 0 r0 r1
check_collision_end:
    rts


update_dir:
    ; get key values
    lw keys_addr r0 r1
    lw 0 r1 r1
    lw key_times_addr r0 r6

    ; translating key values into a direction:
    ; we are going to use the first high value we find,
    ; in the order of key 0 thru key 3, or right up left down

    ; r2 will contain the key mask
    addi 1 r0 r2

    ; r3 will contain 1 to ssl with
    addi 1 r0 r3

    addi 0 r1 r4
    and r2 r4 r4
    ; if keys & mask is 0, then check the next key
    beq dir_check_up r0 r4
    ; else if dir is not 10, load 00 into snk_dir

    ; 180 degree turn not allowed
    lw snk_addr r0 r4
    lw snk@dir r4 r4
    addi 2 r0 r5
    beq update_dir_end_jump r4 r5
    j update_dir_go_right
update_dir_end_jump:
    j update_dir_end
update_dir_go_right:

    push r1
    lw snk_addr r0 r1
    sw snk@next_dir r1 r0
    pop r1

    lw 0 r6 r4
    lw rand r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 0 r6 r0

    ; if tiles_free is greater than rand_val, do nothing
    push r1
    lw snk_addr r0 r1
    lw snk@tiles_free_len r1 r4
    pop r1
    blt dir_right_mod r5 r4
    not r4 r4
    addi 1 r4 r4
    add r4 r5 r5
dir_right_mod:
    ; store back rand val
    sw rand r0 r5

    j update_dir_end
dir_check_up:
    ; put keys value in r4
    addi 0 r1 r4
    ; shift the mask
    ssl r2 r3 r2
    ; and with the mask
    and r2 r4 r4
    ; if keys & mask is 0, then check the next key
    beq dir_check_left r0 r4
    ; 180 degree turn not allowed, check if current dir is down
    lw snk_addr r0 r4
    lw snk@dir r4 r4
    addi 3 r0 r5
    beq update_dir_end_jump r4 r5
    ; else load 01 into snk_dir
    push r1
    lw snk_addr r0 r1
    sw snk@next_dir r1 r3
    pop r1

    lw 1 r6 r4
    lw rand r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 1 r6 r0
    ; if tiles_free is greater than rand_val, do nothing
    push r1
    lw snk_addr r0 r1
    lw snk@tiles_free_len r1 r4
    pop r1
    blt dir_up_mod r5 r4
    not r4 r4
    addi 1 r4 r4
    add r4 r5 r5
dir_up_mod:
    ; store back rand val
    sw rand r0 r5

    j update_dir_end
dir_check_left:
    ; put keys value in r4
    addi 0 r1 r4
    ; shift the mask
    ssl r2 r3 r2
    ; and with the mask
    and r2 r4 r4
    ; if keys & mask is 0, then check the next key
    beq dir_check_down r0 r4
    ; 180 degree turn not allowed, check if current dir is right
    lw snk_addr r0 r4
    lw snk@dir r4 r4
    addi 0 r0 r5
    beq dir_end_jump r4 r5
    j end_dir_end_jump
dir_end_jump:
    j update_dir_end
end_dir_end_jump:
    ; else load 10 into snk_dir
    push r1
    lw snk_addr r0 r1
    addi 2 r0 r5
    sw snk@next_dir r1 r5
    pop r1

    lw 2 r6 r4
    lw rand r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 2 r6 r0
    ; if tiles_free is greater than rand_val, do nothing
    push r1
    lw snk_addr r0 r1
    lw snk@tiles_free_len r1 r4
    pop r1
    blt dir_left_mod r5 r4
    not r4 r4
    addi 1 r4 r4
    add r4 r5 r5
dir_left_mod:
    ; store back rand val
    sw rand r0 r5

    j update_dir_end
dir_check_down:
    ; put keys value in r4
    addi 0 r1 r4
    ; shift the mask
    ssl r2 r3 r2
    ; and with the mask
    and r2 r4 r4
    ; if keys & mask is 0, then no key is pressed
    beq update_dir_end r0 r4
    ; 180 degree turn not allowed, check if current dir is up
    lw snk_addr r0 r4
    lw snk@dir r4 r4
    addi 1 r0 r5
    beq update_dir_end r4 r5
    ; else load 11 into snk_dir
    push r1
    lw snk_addr r0 r1
    addi 3 r0 r5
    sw snk@next_dir r1 r5
    pop r1

    lw 3 r6 r4
    lw rand r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 3 r6 r0
    ; if tiles_free is greater than rand_val, do nothing
    push r1
    lw snk_addr r0 r1
    lw snk@tiles_free_len r1 r4
    pop r1
    blt dir_down_mod r5 r4
    not r4 r4
    addi 1 r4 r4
    add r4 r5 r5
dir_down_mod:
    ; store back rand val
    sw rand r0 r5
update_dir_end:
    rts

move_snake:
    push lr
    ; need to: 
    ; erase pixels from tail on the side opposite of direction travelled
    ; draw pixels on head in the direction of travel


    lw colors_addr r0 r1
    lw colors@snk r1 r1

    lw snk_addr r0 r6
    lw snk@dir r6 r2
    ; short side of rect is equal to move_frame_count at a rate of 8 frames/tile

    beq move_head_right r2 r0
    addi 1 r0 r3
    beq move_head_up r2 r3
    addi 2 r0 r3
    beq move_head_left r2 r3
    j move_head_down
move_head_right:
    lw snk@head_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; y 
    lw 1 r4 r5
    ; x
    lw 0 r4 r4
    ; width = frame cnt + 1
    lw snk@move_frame_count r6 r2
    addi 1 r2 r2
    ; height
    addi 8 r0 r3

    ; draw on head
    jl draw_rect
    j moved_head
move_head_up:
    lw snk@move_frame_count r6 r2

    lw snk@head_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; height = frame cnt + 1
    addi 1 r2 r3

    ; start by moving height into r2
    addi 0 r3 r2

    ; negate height
    not r2 r2
    addi 1 r2 r2

    ; add 8 to -height
    addi 8 r2 r2

    ; y = head y + (8-height)
    lw 1 r4 r5
    add r2 r5 r5
    ; x = head x
    lw 0 r4 r4

    ; width
    addi 8 r0 r2

    ; draw on head
    jl draw_rect
    j moved_head
move_head_left:
    lw snk@move_frame_count r6 r3

    lw snk@head_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; width = frame cnt + 1
    addi 1 r3 r2
    addi 0 r2 r3

    ; negate width
    not r3 r3
    addi 1 r3 r3

    ; add 8 to -width
    addi 8 r3 r3

    ; y = head y
    lw 1 r4 r5
    ; x = head x + (8-width)
    lw 0 r4 r4
    add r3 r4 r4

    ; height
    addi 8 r0 r3

    ; draw on head
    jl draw_rect
    j moved_head
move_head_down:
    lw snk@head_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; y 
    lw 1 r4 r5
    ; x
    lw 0 r4 r4
    ; height = frame cnt + 1
    lw snk@move_frame_count r6 r3
    addi 1 r3 r3
    ; width
    addi 8 r0 r2

    ; draw on head
    jl draw_rect
moved_head:

    lw colors_addr r0 r1
    lw colors@bg r1 r1
    lw snk_addr r0 r6

    lw snk@tail_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; load x of tail into r2
    lw 0 r4 r2

    ; load y of tail into r3
    lw 1 r4 r3

    ; load y of tail+1 into r5
    lw 3 r4 r5

    ; load x of tail+1 into r4
    lw 2 r4 r4

    ; if ytail = y1, the direction is left or right
    beq move_tail_horizontal r3 r5
move_tail_vertical:
    ; if ytail < y1, the direction is down
    blt move_tail_down_jump r3 r5
    j move_tail_up
move_tail_down_jump:
    j move_tail_down

move_tail_horizontal:
    ; if xtail < x1, the direction is right
    blt move_tail_right r2 r4
    j move_tail_left

move_tail_right:
    lw snk@tail_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; y 
    lw 1 r4 r5
    ; x
    lw 0 r4 r4
    ; width = frame cnt + 1
    lw snk@move_frame_count r6 r2
    addi 1 r2 r2
    ; height
    addi 8 r0 r3

    jl draw_rect
    j moved_tail
move_tail_up:
    lw snk@move_frame_count r6 r2

    lw snk@tail_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; height = frame cnt + 1
    addi 1 r2 r3

    ; start by moving height into r2
    addi 0 r3 r2

    ; negate height
    not r2 r2
    addi 1 r2 r2

    ; add 8 to -height
    addi 8 r2 r2

    ; y = tail y + (8-height)
    lw 1 r4 r5
    add r2 r5 r5
    ; x = tail x
    lw 0 r4 r4

    ; width
    addi 8 r0 r2

    ; draw on head
    jl draw_rect
    j moved_tail
move_tail_left:
    lw snk@move_frame_count r6 r3

    lw snk@tail_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; width = frame cnt + 1
    addi 1 r3 r2
    addi 0 r2 r3

    ; negate width
    not r3 r3
    addi 1 r3 r3

    ; add 8 to -width
    addi 8 r3 r3

    ; y = head y
    lw 1 r4 r5
    ; x = head x + (8-width)
    lw 0 r4 r4
    add r3 r4 r4

    ; height
    addi 8 r0 r3

    ; draw on head
    jl draw_rect
    j moved_tail
move_tail_down:
    lw snk@tail_index r6 r5
    lw snk@tiles_queue_addr r6 r4
    add r4 r5 r4

    ; y 
    lw 1 r4 r5
    ; x
    lw 0 r4 r4
    ; height = frame cnt + 1
    lw snk@move_frame_count r6 r3
    addi 1 r3 r3
    ; width
    addi 8 r0 r2
    jl draw_rect
moved_tail:

    pop lr
    rts

vblank_handler:
    push lr 
    jl move_snake
    jl update_food

vblank_check:
    lw vga_vblank_addr r0 r1
    ; get vblank value
    lw 0 r1 r1
    ; if it's 0, return
    beq vblank_end r1 r0
    ; else loop and check again
    j vblank_check
vblank_end:
    pop lr
    rts

; r1: color
; r2: width
; r3: height
; r4: x
; r5: y
draw_rect:
    ; backup the x location
    push r4
    lw vga_write_addr r0 r6

    ; store the end location - x and y
    add r4 r2 r2
    add r5 r3 r3

draw_rect_loop:
    ; x write
    sw 0 r6 r4
    ; y write
    sw 0 r6 r5
    ; bgr write
    sw 0 r6 r1

    addi 1 r4 r4

    ; if we have done 640 pixels, go to next line
    beq draw_rect_line_complete r4 r2
    j draw_rect_loop
draw_rect_line_complete:
    ; inc y
    addi 1 r5 r5
    ; reset x
    pop r4
    push r4
    beq draw_rect_end r5 r3
    j draw_rect_loop
draw_rect_end:
    pop r4
    rts


; r1: char
putc:
    ; load tx_addr into r2
    lw tx_addr r0 r2

    ; load txrdy_addr into r5
    lw txrdy_addr r0 r5

    ; load 1 into r4, for comparison
    addi 1 r0 r4
    ; store char at tx_addr
    sw 0 r2 r1

    ; we need to wait until txrdy goes low and then high again

txrdy_wait_for_low:
    ; load txrdy value into r3
    lw 0 r5 r3
    beq txrdy_is_low r3 r0
    j txrdy_wait_for_low

txrdy_is_low:
    lw 0 r5 r3
    beq txrdy_is_high r3 r4
    j txrdy_is_low

txrdy_is_high:
    rts

; r1: str ptr
print:
    push lr
strloop:
    push r1
    ; load char into r1
    lw 0 r1 r1

    ; if null char, go to the end
    beq print_end r0 r1
    jl putc
    
    pop r1
    ; inc str ptr
    addi 1 r1 r1
    j strloop

print_end:
    pop r1
    pop lr
    rts

; r1: value to print
print_hex_val:
    push lr
    addi 0 r1 r6
    addi -12 r0 r5
print_hex_loop:
    addi 15 r0 r3
    ssl r6 r5 r2
    and r2 r3 r3
    addi 10 r0 r4
    blt offset_by_zero r3 r4
    addi -10 r3 r3
    lw alpha_char r0 r4
    j end_offset
offset_by_zero:
    lw zero_char r0 r4
end_offset:
    add r3 r4 r1

    push r5
    push r6
    jl putc
    pop r6
    pop r5

    beq print_hex_loop_end r5 r0
    addi 4 r5 r5
    j print_hex_loop

print_hex_loop_end:
    lw newline_char r0 r1
    jl putc

    pop lr
    rts

colors:
colors@snk:
    .word 0008
colors@food:
    .word 080C
colors@bg:
    .word 0BBB
colors@frame:
    .word 0889
key_times:
    .word 0000
    .word 0000
    .word 0000
    .word 0000
snk:
; a two bit direction: 00 - right, 01 - up, 10 - left, 11 - down
snk@dir:
    .word 0000
snk@next_dir:
    .word 0000

; 0 thru 7
snk@move_frame_count:
    .word 0000
snk@start_x:
    .word 0140
snk@start_y:
    .word 00F0
snk@len:
    .word 0002
snk@tail_index:
    .word 0000
snk@head_index:
    .word 0000
snk@tiles_queue_len:
    .word 0600
snk@tiles_queue_addr:
    .word 2000
snk@tiles_grid_addr:
    .word 3000
snk@tiles_free_len:
    .word 0300
snk@tiles_free_addr:
    .word 4000
snk@expanding:
    .word 0000
failed_msg:
    .string "failed\n"
begin_msg:
    .string "begin\n"