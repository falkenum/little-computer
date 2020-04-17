    j start
snk_addr:
    .word snk
key_times_addr:
    .word key_times
; these are random numbers generated based on the time between key presses
randx:
    .word 0000
randy:
    .word 0000
foodx:
    .word 0000
foody:
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
txrdy_addr:
    .word F80A
tx_addr:
    .word F80B
tx_count:
    .word 0000
zero_char:
    .string "0"
msg:
    .string "hello world\n"
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

    ; jl gen_food_coord
    ; addi 0 r1 r4
    ; addi 0 r2 r5
    ; lw colors_addr r0 r1
    ; lw colors@food r1 r1
    ; lw snk_width r0 r2
    ; lw snk_width r0 r3
    ; jl draw_rect

    j main
vblank_done:
    ; update next_dir
    jl update_dir

    ; jl inc_key_times

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
    addi 2 r2 r2
    sw snk@tail_index r1 r2

    ; set new head data dependent on direction of movement
    ; get old head x,y in r2,r3
    lw snk@head_index r1 r6
    add r6 r1 r5
    addi snk@tile_data_buf r5 r4

    ; add 2 to head index and store back TODO (mod buflen)
    addi 2 r6 r6
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
    addi snk@tile_data_buf r5 r4

    ; store back new head values
    sw 0 r4 r2
    sw 1 r4 r3

    ; reset frame count
    sw snk@move_frame_count r1 r0

    jl check_collision
    addi 1 r0 r2
    ; if r1 == 0, then go to main. else restart game
    blt main r1 r2
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
    addi snk@tile_data_buf r6 r2

    ; store x,y for first tile
    sw 0 r2 r3
    sw 1 r2 r4


    ; store x,y for second tile
    addi 8 r3 r3
    sw 2 r2 r3
    sw 3 r2 r4

    ; store x,y for third tile
    addi 8 r3 r3
    sw 4 r2 r3
    sw 5 r2 r4

    ; store 0 for dir and next_dir
    sw snk@dir r6 r0
    sw snk@next_dir r6 r0

    ; draw first tile
    lw colors_addr r0 r1
    lw colors@snk r1 r1
    ; width and height of 8
    addi 8 r0 r2
    addi 8 r0 r3

    addi snk@tile_data_buf r6 r6
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

    pop lr
    rts

inc_key_times:

    lw key_times_addr r0 r2
    ; add to key timers
    lw 0 r2 r1
    addi 19 r1 r1
    sw 0 r2 r1

    lw 1 r2 r1
    addi 19 r1 r1
    sw 1 r2 r1

    lw 2 r2 r1
    addi 19 r1 r1
    sw 2 r2 r1

    lw 3 r2 r1
    addi 19 r1 r1
    sw 3 r2 r1
    rts

check_collision:
    lw snk_addr r0 r1
    lw snk@dir r1 r3

    lw snk@head_index r1 r2
    add r1 r2 r2
    addi snk@tile_data_buf r2 r2


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
    ; TODO don't allow 180 degree changes in direction

    ; r2 will contain the key mask
    addi 1 r0 r2

    ; r3 will contain 1 to lsl with
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
    lw randx r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 0 r6 r0
    ; store back rand val
    sw randx r0 r5

    j update_dir_end
dir_check_up:
    ; put keys value in r4
    addi 0 r1 r4
    ; shift the mask
    lsl r2 r3 r2
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
    lw randy r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 1 r6 r0
    ; store back rand val
    sw randy r0 r5

    j update_dir_end
dir_check_left:
    ; put keys value in r4
    addi 0 r1 r4
    ; shift the mask
    lsl r2 r3 r2
    ; and with the mask
    and r2 r4 r4
    ; if keys & mask is 0, then check the next key
    beq dir_check_down r0 r4
    ; 180 degree turn not allowed, check if current dir is right
    lw snk_addr r0 r4
    lw snk@dir r4 r4
    addi 0 r0 r5
    beq update_dir_end r4 r5
    ; else load 10 into snk_dir
    push r1
    lw snk_addr r0 r1
    addi 2 r0 r5
    sw snk@next_dir r1 r5
    pop r1

    lw 2 r6 r4
    lw randx r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 2 r6 r0
    ; store back rand val
    sw randx r0 r5

    j update_dir_end
dir_check_down:
    ; put keys value in r4
    addi 0 r1 r4
    ; shift the mask
    lsl r2 r3 r2
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
    lw randy r0 r5
    ; add to rand value
    add r4 r5 r5
    ; reset timer
    sw 3 r6 r0
    ; store back rand val
    sw randy r0 r5
update_dir_end:
    rts

; gen_food_coord:
;     lw randx r0 r1
;     lw screen_width r0 r4
;     addi -20 r0 r3 
;     ; 620
;     add r3 r4 r4
;     ; 600
;     add r3 r4 r4

;     ; copy to r3 and negate it
;     add r4 r0 r3
;     not r3 r3
;     addi 1 r3 r3

;     ; subtract 600 until it's less than 600
; x_mod_loop:
;     blt x_generated r1 r4
;     add r1 r3 r1
;     j x_mod_loop

; x_generated:
;     ; x val in r1, y val in r2
;     addi 20 r1 r1

;     lw randy r0 r2
;     lw screen_height r0 r4
;     addi -15 r0 r3 
;     add r3 r4 r4
;     add r3 r4 r4

;     ; copy to r3 and negate it
;     add r4 r0 r3
;     not r3 r3
;     addi 1 r3 r3

;     ; subtract 600 until it's less than 600
; y_mod_loop:
;     blt y_generated r2 r4
;     add r2 r3 r2
;     j y_mod_loop

; y_generated:

;     addi 15 r2 r2
;     rts

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
    lw snk@head_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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

    lw snk@head_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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

    lw snk@head_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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
    lw snk@head_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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

    lw snk@tail_index r6 r4
    add r6 r4 r4
    addi snk@tile_data_buf r4 r4

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
    lw snk@tail_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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

    lw snk@tail_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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

    lw snk@tail_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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
    lw snk@tail_index r6 r4
    ; offset addr by index
    add r6 r4 r4
    ; offset addr by buf location
    addi snk@tile_data_buf r4 r4

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

print:
    ; load msg addr into r1
    addi msg r0 r1

    ; load tx_addr into r2
    lw tx_addr r0 r2

    ; load txrdy_addr into r5
    lw txrdy_addr r0 r5

    ; load 1 into r4, for comparison
    addi 1 r0 r4

strloop:
    ; load char into r3
    lw 0 r1 r3

    ; if null char, go to the end
    beq print_end r0 r3

    ; store char at tx_addr
    sw 0 r2 r3

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
    ; inc char ptr
    addi 1 r1 r1
    j strloop

print_end:
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
snk@tile_data_len:
    .word 0600
; index to the tail of the snake in the buffer
snk@tail_index:
    .word 0000
snk@head_index:
    .word 0000
; each of the tiles has x, y
snk@tile_data_buf:
    .array 1536