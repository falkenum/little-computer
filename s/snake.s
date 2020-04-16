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
    ; jl update_dir


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
    ; update tail index +2 mod buflen
    ; write new head data
    ; check collisions with new tile

    ; add 2 to tail index, mod buflen
    lw snk@tail_index r1 r2
    addi 2 r2 r2
    sw snk@tail_index r1 r2

    ; set new head data TODO dependent on direction of movement
    ; get old head x,y in r2,r3
    lw snk@head_index r1 r6
    add r6 r1 r5
    addi snk@tile_data_buf r5 r4

    ; add 2 to head index and store back TODO (mod buflen)
    addi 2 r6 r6
    sw snk@head_index r1 r6

    ; head x
    lw 0 r4 r2
    addi 8 r2 r2
    ; head y
    lw 1 r4 r3

    ; update buf index with new head index
    add r6 r1 r5
    addi snk@tile_data_buf r5 r4

    ; store back new values
    sw 0 r4 r2
    sw 1 r4 r3

    ; reset frame count
    sw snk@move_frame_count r1 r0

    ; jl check_collision
    ; addi 1 r0 r2
    ; ; if r1 == 0, then go to main. else restart game
    ; blt main r1 r2
    ; jl reset_game
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
    addi 2 r0 r1
    ; head at index 2 (after x,y of first tile)
    sw snk@head_index r6 r1
    ; start with len 2
    addi 2 r0 r2
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

    ; store 0 for dir and next_dir
    sw snk@dir r1 r0
    sw snk@next_dir r1 r0

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

    jl draw_rect

    pop lr
    rts

; inc_key_times:

;     lw key_times_addr r0 r2
;     ; add to key timers
;     lw 0 r2 r1
;     addi 19 r1 r1
;     sw 0 r2 r1

;     lw 1 r2 r1
;     addi 19 r1 r1
;     sw 1 r2 r1

;     lw 2 r2 r1
;     addi 19 r1 r1
;     sw 2 r2 r1

;     lw 3 r2 r1
;     addi 19 r1 r1
;     sw 3 r2 r1
;     rts

check_collision:
    lw snk_addr r0 r1

    ; TODO check other the side in the direction of motion
    ; right side: check if head x >= bg_x + bg_width
    lw snk@head_index r1 r2
    add r1 r2 r2
    addi snk@tile_data_buf r2 r2

    ; load x into r3
    lw 0 r2 r3

    ; bg_x + bg_width into r4
    lw bg_x r0 r4
    lw bg_width r0 r5
    add r4 r5 r4

    blt collision_not_found r3 r4


    ; if collision, return 1
    addi 1 r0 r1
    j check_collision_end
collision_not_found:
    addi 0 r0 r1
check_collision_end:
    rts


; update_dir:
;     ; get key values
;     lw keys_addr r0 r1
;     lw 0 r1 r1
;     lw key_times_addr r0 r6

;     ; translating key values into a direction:
;     ; we are going to use the first high value we find,
;     ; in the order of key 0 thru key 3, or right up left down

;     ; r2 will contain the key mask
;     addi 1 r0 r2

;     ; r3 will contain 1 to lsl with
;     addi 1 r0 r3

;     addi 0 r1 r4
;     and r2 r4 r4
;     ; if keys & mask is 0, then check the next key
;     beq dir_check_up r0 r4
;     ; else load 00 into snk_dir

;     push r1
;     lw snk_addr r0 r1
;     sw snk@dir r1 r0
;     pop r1

;     lw 0 r6 r4
;     lw randx r0 r5
;     ; add to rand value
;     add r4 r5 r5
;     ; reset timer
;     sw 0 r6 r0
;     ; store back rand val
;     sw randx r0 r5

;     j update_dir_end
; dir_check_up:
;     ; put keys value in r4
;     addi 0 r1 r4
;     ; shift the mask
;     lsl r2 r3 r2
;     ; and with the mask
;     and r2 r4 r4
;     ; if keys & mask is 0, then check the next key
;     beq dir_check_left r0 r4
;     ; else load 01 into snk_dir
;     push r1
;     lw snk_addr r0 r1
;     sw snk@dir r1 r3
;     pop r1

;     lw 1 r6 r4
;     lw randy r0 r5
;     ; add to rand value
;     add r4 r5 r5
;     ; reset timer
;     sw 1 r6 r0
;     ; store back rand val
;     sw randy r0 r5

;     j update_dir_end
; dir_check_left:
;     ; put keys value in r4
;     addi 0 r1 r4
;     ; shift the mask
;     lsl r2 r3 r2
;     ; and with the mask
;     and r2 r4 r4
;     ; if keys & mask is 0, then check the next key
;     beq dir_check_down r0 r4
;     ; else load 10 into snk_dir
;     push r1
;     lw snk_addr r0 r1
;     addi 2 r0 r5
;     sw snk@dir r1 r5
;     pop r1

;     lw 2 r6 r4
;     lw randx r0 r5
;     ; add to rand value
;     add r4 r5 r5
;     ; reset timer
;     sw 2 r6 r0
;     ; store back rand val
;     sw randx r0 r5

;     j update_dir_end
; dir_check_down:
;     ; put keys value in r4
;     addi 0 r1 r4
;     ; shift the mask
;     lsl r2 r3 r2
;     ; and with the mask
;     and r2 r4 r4
;     ; if keys & mask is 0, then no key is pressed
;     beq update_dir_end r0 r4
;     ; else load 11 into snk_dir
;     push r1
;     lw snk_addr r0 r1
;     addi 3 r0 r5
;     sw snk@dir r1 r5
;     pop r1

;     lw 3 r6 r4
;     lw randy r0 r5
;     ; add to rand value
;     add r4 r5 r5
;     ; reset timer
;     sw 3 r6 r0
;     ; store back rand val
;     sw randy r0 r5
; update_dir_end:
;     rts

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
    addi 3 r0 r3
    beq move_head_down r2 r3
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
    j moved_head
move_head_left:
    j moved_head
move_head_down:
moved_head:

    ; check direction tail is facing

    lw colors_addr r0 r1
    lw colors@bg r1 r1

    lw snk_addr r0 r6

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
    j moved_tail
move_tail_left:
    j moved_tail
move_tail_down:
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