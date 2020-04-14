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
screen_buf_sel_addr:
    .word F80F
screen_width:
    .word 0280 ;640 in decimal
screen_height:
    .word 01E0 ;480 in decimal
colors_addr:
    .word colors
tile_size:
    .word 0008
start:
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
    jl update_dir

    lw snk_addr r0 r1
    lw snk@move_frame_count r1 r2
    ; inc frame count
    addi 1 r2 r2
    sw snk@move_frame_count r1 r2
    lw snk@move_period r1 r3
    beq do_move_snake r2 r3
    j end_move_snake
do_move_snake:
    ; reset frame count
    sw snk@move_frame_count r1 r0

    jl move_snake
    jl check_collision
    addi 1 r0 r2
    beq start r1 r2
end_move_snake:

    jl inc_key_times

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
    ; drawing the background
    lw colors_addr r0 r1
    lw colors@bg r1 r1
    lw screen_width r0 r2
    lw screen_height r0 r3
    addi 0 r0 r4
    addi 0 r0 r5
    jl draw_rect

    jl swap_screen_buf

    lw colors_addr r0 r1
    lw colors@bg r1 r1
    lw screen_width r0 r2
    lw screen_height r0 r3
    addi 0 r0 r4
    addi 0 r0 r5
    jl draw_rect

    lw snk_addr r0 r2
    lw snk@start_x r2 r1
    sw snk@x r2 r1
    lw snk@start_y r2 r1
    sw snk@y r2 r1
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

swap_screen_buf:
    lw screen_buf_sel_addr r0 r1
    lw 0 r1 r2
    not r2 r2
    sw 0 r1 r2
    rts

check_collision:
    lw snk_addr r0 r4
    lw snk@x r4 r1
    lw screen_width r0 r2
    ; check if left side has wrapped around
    addi -1 r2 r2
    blt collision_found r2 r1
    ; check if right side has gone too far
    lw tile_size r0 r3
    add r1 r3 r1
    blt collision_found r2 r1
    ; check top

    lw snk@y r4 r1
    lw screen_height r0 r2
    addi -1 r2 r2
    blt collision_found r2 r1

    ; check bottom
    lw tile_size r0 r3
    add r1 r3 r1
    blt collision_found r2 r1

    ; if no collision, return 0
    addi 0 r0 r1
    j check_collision_end
collision_found:
    addi 1 r0 r1
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

    ; r3 will contain 1 to lsl with
    addi 1 r0 r3

    addi 0 r1 r4
    and r2 r4 r4
    ; if keys & mask is 0, then check the next key
    beq dir_check_up r0 r4
    ; else load 00 into snk_dir

    push r1
    lw snk_addr r0 r1
    sw snk@dir r1 r0
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
    ; else load 01 into snk_dir
    push r1
    lw snk_addr r0 r1
    sw snk@dir r1 r3
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
    ; else load 10 into snk_dir
    push r1
    lw snk_addr r0 r1
    addi 2 r0 r5
    sw snk@dir r1 r5
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
    ; else load 11 into snk_dir
    push r1
    lw snk_addr r0 r1
    addi 3 r0 r5
    sw snk@dir r1 r5
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

gen_food_coord:
    lw randx r0 r1
    lw screen_width r0 r4
    addi -20 r0 r3 
    ; 620
    add r3 r4 r4
    ; 600
    add r3 r4 r4

    ; copy to r3 and negate it
    add r4 r0 r3
    not r3 r3
    addi 1 r3 r3

    ; subtract 600 until it's less than 600
x_mod_loop:
    blt x_generated r1 r4
    add r1 r3 r1
    j x_mod_loop

x_generated:
    ; x val in r1, y val in r2
    addi 20 r1 r1

    lw randy r0 r2
    lw screen_height r0 r4
    addi -15 r0 r3 
    add r3 r4 r4
    add r3 r4 r4

    ; copy to r3 and negate it
    add r4 r0 r3
    not r3 r3
    addi 1 r3 r3

    ; subtract 600 until it's less than 600
y_mod_loop:
    blt y_generated r2 r4
    add r2 r3 r2
    j y_mod_loop

y_generated:

    addi 15 r2 r2
    rts

move_snake:
    ; erase old tile
    ; TODO: only erase and draw the needed number of pixels, not a whole tile
    lw snk_addr r0 r6
    lw colors_addr r0 r1
    lw colors@bg r1 r1
    lw snk@x r6 r2
    lw snk@y r6 r3

    push lr
    jl draw_tile
    pop lr

    lw snk_addr r0 r6

    ; check which direction we are going
    lw snk@dir r6 r2
    addi 0 r0 r3
    beq going_right r2 r3
    addi 1 r0 r3
    beq going_up r2 r3
    addi 2 r0 r3
    beq going_left r2 r3
    addi 3 r0 r3
    beq going_down r2 r3
going_right:
    ; change x by 1 and store back in memory
    lw snk@x r6 r4
    addi 1 r4 r4
    sw snk@x r6 r4
    j moved
going_up:
    ; change y by -1 and store back in memory
    lw snk@y r6 r4
    addi -1 r4 r4
    sw snk@y r6 r4
    j moved
going_left:
    ; change x by -1 and store back in memory
    lw snk@x r6 r4
    addi -1 r4 r4
    sw snk@x r6 r4
    j moved
going_down:
    ; change y by 1 and store back in memory
    lw snk@y r6 r4
    addi 1 r4 r4
    sw snk@y r6 r4
moved:
    ; draw new location
    lw colors_addr r0 r1
    lw colors@snk r1 r1
    lw snk@x r6 r2
    lw snk@y r6 r3

    push lr
    jl draw_tile
    pop lr

    rts

vblank_handler:
    push lr 
    jl swap_screen_buf
    pop lr

vblank_check:
    lw vga_vblank_addr r0 r1
    ; get vblank value
    lw 0 r1 r1
    ; if it's 0, return
    beq vblank_end r1 r0
    ; else loop and check again
    j vblank_check
vblank_end:
    rts

; r1: color
; r2: x
; r3: y
draw_tile:
    push lr
    
    ; tile size is 2^3
    addi 3 r0 r6
    lsl r2 r6 r4
    lsl r3 r6 r5
    lw tile_size r0 r2
    addi 0 r2 r3

    jl draw_rect
    
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
    .word 0888
key_times:
    .word 0000
    .word 0000
    .word 0000
    .word 0000
snk:
snk@x:
    .word 0000
snk@y:
    .word 0000
; a two bit direction: 00 - right, 01 - up, 10 - left, 11 - down
snk@dir:
    .word 0000
snk@len:
    .word 0000

; period of movement per tile in frames
snk@move_period:
    .word 0004
snk@move_frame_count:
    .word 0000
snk@start_x:
    .word 0028
snk@start_y:
    .word 001E