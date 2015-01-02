######################################################################
# 			     SNAKE!!!!                               #
######################################################################
#           Programmed by Shane Shafferman and Eric Deas             #
######################################################################
#	This program requires the Keyboard and Display MMIO          #
#       and the Bitmap Display to be connected to MIPS.              #
#								     #
#       Bitmap Display Settings:                                     #
#	Unit Width: 8						     #
#	Unit Height: 8						     #
#	Display Width: 512					     #
#	Display Height: 512					     #
#	Base Address for Display: 0x10008000 ($gp)		     #
######################################################################

.data

#Game Core information

#Screen 
screenWidth: 	.word 64
screenHeight: 	.word 64

#Colors
snakeColor: 	.word	0x0066cc	 # blue
backgroundColor:.word	0x000000	 # black
borderColor:    .word	0x00ff00	 # green	
fruitColor: 	.word	0xcc6611	 # orange

#score variable
score: 		.word 0
#stores how many points are recieved for eating a fruit
#increases as program gets harder
scoreGain:	.word 10
#speed the snake moves at, increases as game progresses
gameSpeed:	.word 200
#array to store the scores in which difficulty should increase
scoreMilestones: .word 100, 250, 500, 1000, 5000, 10000
scoreArrayPosition: .word 0
#end game message
lostMessage:	.asciiz "You have died.... Your score was: "
replayMessage:	.asciiz "Would you like to replay?"

#Snake Information
snakeHeadX: 	.word 31
snakeHeadY:	.word 31
snakeTailX:	.word 31
snakeTailY:	.word 37
direction:	.word 119 #initially moving up
tailDirection:	.word 119
# direction variable
# 119 - moving up - W
# 115 - moving down - S
# 97 - moving left - A
# 100 - moving right - D
# numbers are selected due to ASCII characters

#this array stores the screen coordinates of a direction change
#once the tail hits a position in this array, its direction is changed
#this is used to have the tail follow the head correctly
directionChangeAddressArray:	.word 0:100
#this stores the new direction for the tail to move once it hits
#an address in the above array
newDirectionChangeArray:	.word 0:100
#stores the position of the end of the array (multiple of 4)
arrayPosition:			.word 0
locationInArray:		.word 0

#Fruit Information
fruitPositionX: .word
fruitPositionY: .word

.text

main:
######################################################
# Fill Screen to Black, for reset
######################################################
	lw $a0, screenWidth
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 #total number of pixels on screen
	mul $a2, $a2, 4 #align addresses
	add $a2, $a2, $gp #add base of gp
	add $a0, $gp, $zero #loop counter
FillLoop:
	beq $a0, $a2, Init
	sw $a1, 0($a0) #store color
	addiu $a0, $a0, 4 #increment counter
	j FillLoop

######################################################
# Initialize Variables
######################################################
Init:

	li $t0, 31
	sw $t0, snakeHeadX
	sw $t0, snakeHeadY
	sw $t0, snakeTailX
	li $t0, 37
	sw $t0, snakeTailY
	li $t0, 119
	sw $t0, direction
	sw $t0, tailDirection
	li $t0, 10
	sw $t0, scoreGain
	li $t0, 200
	sw $t0, gameSpeed
	sw $zero, arrayPosition
	sw $zero, locationInArray
	sw $zero, scoreArrayPosition
	sw $zero, score
	
ClearRegisters:

	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0		

######################################################
# Draw Border
######################################################

DrawBorder:
	li $t1, 0	#load Y coordinate for the left border
	LeftLoop:
	move $a1, $t1	#move y coordinate into $a1
	li $a0, 0	# load x direction to 0, doesnt change
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0	# move screen coordinates into $a0
	lw $a1, borderColor	#move color code into $a1
	jal DrawPixel	#draw the color at the screen location
	add $t1, $t1, 1	#increment y coordinate
	
	bne $t1, 64, LeftLoop	#loop through to draw entire left border
	
	li $t1, 0	#load Y coordinate for right border
	RightLoop:
	move $a1, $t1	#move y coordinate into $a1
	li $a0, 63	#set x coordinate to 63 (right side of screen)
	jal CoordinateToAddress	#convert to screen coordinates
	move $a0, $v0	# move coordinates into $a0
	lw $a1, borderColor	#move color data into $a1
	jal DrawPixel	#draw color at screen coordinates
	add $t1, $t1, 1	#increment y coordinate
	
	bne $t1, 64, RightLoop	#loop through to draw entire right border
	
	li $t1, 0	#load X coordinate for top border
	TopLoop:
	move $a0, $t1	# move x coordinate into $a0
	li $a1, 0	# set y coordinate to zero for top of screen
	jal CoordinateToAddress	#get screen coordinate
	move $a0, $v0	#  move screen coordinates to $a0
	lw $a1, borderColor	# store color data to $a1
	jal DrawPixel	#draw color at screen coordinates
	add $t1, $t1, 1 #increment X position
	
	bne $t1, 64, TopLoop #loop through to draw entire top border
	
	li $t1, 0	#load X coordinate for bottom border
	BottomLoop:
	move $a0, $t1	# move x coordinate to $a0
	li $a1, 63	# load Y coordinate for bottom of screen
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0	#move screen coordinates to $a0
	lw $a1, borderColor	#put color data into $a1
	jal DrawPixel	#draw color at screen position
	add $t1, $t1, 1	#increment X coordinate
	
	bne $t1, 64, BottomLoop	# loop through to draw entire bottom border
	
######################################################
# Draw Initial Snake Position
######################################################
	#draw snake head
	lw $a0, snakeHeadX #load x coordinate
	lw $a1, snakeHeadY #load y coordinate
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
	
	#draw middle portion
	lw $a0, snakeHeadX #load x coordinate
	lw $a1, snakeHeadY #load y coordinate
	add $a1, $a1, 1
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
	
	#TEST 8 PIXELS
	lw $a0, snakeHeadX #load x coordinate
	lw $a1, snakeHeadY #load y coordinate
	add $a1, $a1, 2
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
	
	lw $a0, snakeHeadX #load x coordinate
	lw $a1, snakeHeadY #load y coordinate
	add $a1, $a1, 3
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
	
	lw $a0, snakeHeadX #load x coordinate
	lw $a1, snakeHeadY #load y coordinate
	add $a1, $a1, 4
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
	
	lw $a0, snakeHeadX #load x coordinate
	lw $a1, snakeHeadY #load y coordinate
	add $a1, $a1, 5
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
	
	lw $a0, snakeHeadX #load x coordinate
	lw $a1, snakeHeadY #load y coordinate
	add $a1, $a1, 6
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
	
	#draw snake tail
	lw $a0, snakeTailX #load x coordinate
	lw $a1, snakeTailY #load y coordinate
	jal CoordinateToAddress #get screen coordinates
	move $a0, $v0 #copy coordinates to $a0
	lw $a1, snakeColor #store color into $a1
	jal DrawPixel	#draw color at pixel
######################################################
# Spawn Fruit
######################################################	
SpawnFruit:
	#syscall for random int with a upper bound
	li $v0, 42
	#upper bound 61 (0 <= $a0 < $a1)
	li $a1, 62
	syscall
	#increment the X position so it doesnt draw on a border
	addiu $a0, $a0, 1
	#store X position
	sw $a0, fruitPositionX
	syscall
	#increment the Y position so it doesnt draw on a border
	addiu $a0, $a0, 1
	#store Y position
	sw $a0, fruitPositionY
	jal IncreaseDifficulty
	
######################################################
# Check for Direction Change
######################################################

InputCheck:
	lw $a0, gameSpeed
	jal Pause

#get the coordinates for direction change if needed
	lw $a0, snakeHeadX
	lw $a1, snakeHeadY
	jal CoordinateToAddress
	add $a2, $v0, $zero

	#get the input from the keyboard
	li $t0, 0xffff0000
	lw $t1, ($t0)
	andi $t1, $t1, 0x0001
	beqz $t1, SelectDrawDirection #if no new input, draw in same direction
	lw $a1, 4($t0) #store direction based on input
	
DirectionCheck:	
	lw $a0, direction # load current direction into #a0

	jal CheckDirection	#check to see if the direction is valid
	beqz $v0, InputCheck	#if input is not valid, get new input
	sw $a1, direction	#store the new direction if valid
	lw $t7, direction	#store the direction into $t7

######################################################
# Update Snake Head position
######################################################	
			
SelectDrawDirection:
	#check to see which direction to draw
	beq $t7, 119, DrawUpLoop
	beq  $t7, 115, DrawDownLoop
	beq  $t7, 97, DrawLeftLoop
	beq  $t7, 100, DrawRightLoop
	#jump back to get input if an unsupported key was pressed
	j InputCheck
	
DrawUpLoop:
	#check for collision before moving to next pixel
	lw $a0, snakeHeadX
	lw $a1, snakeHeadY
	lw $a2, direction
	jal CheckGameEndingCollision
	#draw head in new position, move Y position up
	lw $t0, snakeHeadX
	lw $t1, snakeHeadY
	addiu $t1, $t1, -1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, snakeColor
	jal DrawPixel

	sw  $t1, snakeHeadY
	j UpdateTailPosition #head updated, update tail
	
DrawDownLoop:
	#check for collision before moving to next pixel
	lw $a0, snakeHeadX
	lw $a1, snakeHeadY
	lw $a2, direction	
	jal CheckGameEndingCollision
	#draw head in new position, move Y position down
	lw $t0, snakeHeadX
	lw $t1, snakeHeadY
	addiu $t1, $t1, 1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, snakeColor
	jal DrawPixel
	
	sw  $t1, snakeHeadY	
	j UpdateTailPosition #head updated, update tail

DrawLeftLoop:
	#check for collision before moving to next pixel
	lw $a0, snakeHeadX
	lw $a1, snakeHeadY
	lw $a2, direction	
	jal CheckGameEndingCollision
	#draw head in new position, move X position left
	lw $t0, snakeHeadX
	lw $t1, snakeHeadY
	addiu $t0, $t0, -1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, snakeColor
	jal DrawPixel
	
	sw  $t0, snakeHeadX	
	j UpdateTailPosition #head updated, update tail

DrawRightLoop:
	#check for collision before moving to next pixel
	lw $a0, snakeHeadX
	lw $a1, snakeHeadY
	lw $a2, direction	
	jal CheckGameEndingCollision
	#draw head in new position, move X position right
	lw $t0, snakeHeadX
	lw $t1, snakeHeadY
	addiu $t0, $t0, 1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, snakeColor
	jal DrawPixel
	
	sw  $t0, snakeHeadX
	j UpdateTailPosition #head updated, update tail

######################################################
# Update Snake Tail Position
######################################################	
			
UpdateTailPosition:	
	lw $t2, tailDirection
	#branch based on which direction tail is moving
	beq  $t2, 119, MoveTailUp
	beq  $t2, 115, MoveTailDown
	beq  $t2, 97, MoveTailLeft
	beq  $t2, 100, MoveTailRight

MoveTailUp:
	#get the screen coordinates of the next direction change
	lw $t8, locationInArray
	la $t0, directionChangeAddressArray #get direction change coordinate
	add $t0, $t0, $t8
	lw $t9, 0($t0)
	lw $a0, snakeTailX  #get snake tail position
	lw $a1, snakeTailY
	#if the index is out of bounds, set back to zero
	beq $s1, 1, IncreaseLengthUp #branch if length should be increased
	addiu $a1, $a1, -1 #change tail position if no length change
	sw $a1, snakeTailY
	
IncreaseLengthUp:
	li $s1, 0 #set flag back to false
	jal CoordinateToAddress
	add $a0, $v0, $zero
	bne $t9, $a0, DrawTailUp #change direction if needed
	la $t3, newDirectionChangeArray  #update direction
	add $t3, $t3, $t8
	lw $t9, 0($t3)
	sw $t9, tailDirection
	addiu $t8,$t8,4
	#if the index is out of bounds, set back to zero
	bne $t8, 396, StoreLocationUp
	li $t8, 0
StoreLocationUp:
	sw $t8, locationInArray 
DrawTailUp:
	lw $a1, snakeColor
	jal DrawPixel
	#erase behind the snake
	lw $t0, snakeTailX
	lw $t1, snakeTailY
	addiu $t1, $t1, 1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, backgroundColor
	jal DrawPixel	
	j DrawFruit  #finished updating snake, update fruit

MoveTailDown:
	#get the screen coordinates of the next direction change
	lw $t8, locationInArray
	la $t0, directionChangeAddressArray #get direction change coordinate
	add $t0, $t0, $t8
	lw $t9, 0($t0)
	lw $a0, snakeTailX  #get snake tail position
	lw $a1, snakeTailY
	beq $s1, 1, IncreaseLengthDown #branch if length should be increased
	addiu $a1, $a1, 1 #change tail position if no length change
	sw $a1, snakeTailY
	
IncreaseLengthDown:
	li $s1, 0 #set flag back to false
	jal CoordinateToAddress
	add $a0, $v0, $zero
	bne $t9, $a0, DrawTailDown #change direction if needed
	la $t3, newDirectionChangeArray  #update direction
	add $t3, $t3, $t8
	lw $t9, 0($t3)
	sw $t9, tailDirection
	addiu $t8,$t8,4
	#if the index is out of bounds, set back to zero
	bne $t8, 396, StoreLocationDown
	li $t8, 0
StoreLocationDown:
	sw $t8, locationInArray  
DrawTailDown:	
	lw $a1, snakeColor
	jal DrawPixel	
	#erase behind the snake
	lw $t0, snakeTailX
	lw $t1, snakeTailY
	addiu $t1, $t1, -1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, backgroundColor
	jal DrawPixel	
	j DrawFruit #finished updating snake, update fruit

MoveTailLeft:
	#update the tail position when moving left
	lw $t8, locationInArray
	la $t0, directionChangeAddressArray #get direction change coordinate
	add $t0, $t0, $t8
	lw $t9, 0($t0)
	lw $a0, snakeTailX #get snake tail position
	lw $a1, snakeTailY
	beq $s1, 1, IncreaseLengthLeft #branch if length should be increased
	addiu $a0, $a0, -1 #change tail position if no length change
	sw $a0, snakeTailX
	
IncreaseLengthLeft:
	li $s1, 0 #set flag back to false
	jal CoordinateToAddress
	add $a0, $v0, $zero
	bne $t9, $a0, DrawTailLeft #change direction if needed
	la $t3, newDirectionChangeArray #update direction
	add $t3, $t3, $t8
	lw $t9, 0($t3)
	sw $t9, tailDirection
	addiu $t8,$t8,4
	#if the index is out of bounds, set back to zero
	bne $t8, 396, StoreLocationLeft
	li $t8, 0
StoreLocationLeft:
	sw $t8, locationInArray  
DrawTailLeft:	
	lw $a1, snakeColor
	jal DrawPixel	
	#erase behind the snake
	lw $t0, snakeTailX
	lw $t1, snakeTailY
	addiu $t0, $t0, 1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, backgroundColor
	jal DrawPixel	
	j DrawFruit  #finished updating snake, update fruit

MoveTailRight:
	#get the screen coordinates of the next direction change
	lw $t8, locationInArray
	#get the base address of the coordinate array
	la $t0, directionChangeAddressArray
	#go to the correct index of array
	add $t0, $t0, $t8
	#get the data from the array
	lw $t9, 0($t0)
	#get current tail position
	lw $a0, snakeTailX
	lw $a1, snakeTailY
	#if the length needs to be increased
	#do not change coordinates
	beq $s1, 1, IncreaseLengthRight
	#change tail position
	addiu $a0, $a0, 1
	#store new tail position
	sw $a0, snakeTailX
	
IncreaseLengthRight:
	li $s1, 0 #set flag back to false
	#get screen coordinates
	jal CoordinateToAddress
	#store coordinates in $a0
	add $a0, $v0, $zero
	#if the coordinates is a position change 
	#continue drawing tail in same direction
	bne $t9, $a0, DrawTailRight
	#get the base address of the direction change array
	la $t3, newDirectionChangeArray
	#move to correct index in array
	add $t3, $t3, $t8
	#get data from array
	lw $t9, 0($t3)
	#store new direction
	sw $t9, tailDirection
	#increment position in array
	addiu $t8,$t8,4
	#if the index is out of bounds, set back to zero
	bne $t8, 396, StoreLocationRight
	li $t8, 0
StoreLocationRight:
	sw $t8, locationInArray  
DrawTailRight:	

	lw $a1, snakeColor
	jal DrawPixel	
	#erase behind the snake
	lw $t0, snakeTailX
	lw $t1, snakeTailY
	addiu $t0, $t0, -1
	add $a0, $t0, $zero
	add $a1, $t1, $zero
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, backgroundColor
	jal DrawPixel
	j DrawFruit  #finished updating snake, update fruit
	
######################################################
# Draw Fruit
######################################################	
DrawFruit:
	#check collision with fruit
	lw $a0, snakeHeadX
	lw $a1, snakeHeadY
	jal CheckFruitCollision
	beq $v0, 1, AddLength #if fruit was eaten, add length

	#draw the fruit
	lw $a0, fruitPositionX
	lw $a1, fruitPositionY
	jal CoordinateToAddress
	add $a0, $v0, $zero
	lw $a1, fruitColor
	jal DrawPixel
	j InputCheck
	
AddLength:
	li $s1, 1 #flag to increase snake length
	j SpawnFruit

j InputCheck #shouldn't need, but there in case of errors

##################################################################
#CoordinatesToAddress Function
# $a0 -> x coordinate
# $a1 -> y coordinate
##################################################################
# returns $v0 -> the address of the coordinates for bitmap display
##################################################################
CoordinateToAddress:
	lw $v0, screenWidth 	#Store screen width into $v0
	mul $v0, $v0, $a1	#multiply by y position
	add $v0, $v0, $a0	#add the x position
	mul $v0, $v0, 4		#multiply by 4
	add $v0, $v0, $gp	#add global pointerfrom bitmap display
	jr $ra			# return $v0

##################################################################
#Draw Function
# $a0 -> Address position to draw at
# $a1 -> Color the pixel should be drawn
##################################################################
# no return value
##################################################################
DrawPixel:
	sw $a1, ($a0) 	#fill the coordinate with specified color
	jr $ra		#return
	
##################################################################
# Check Acceptable Direction
# $a0 - current direction
# $a1 - input
# $a2 - coordinates of direction change if acceptable
##################################################################
# return $v0 = 0 - direction unacceptable
#	 $v0 = 1 - direction is acceptable
##################################################################
CheckDirection:
	beq $a0, $a1, Same  #if the input is the same as current direction
				#continue moving in the direction
	beq $a0, 119, checkIsDownPressed #if  moving up, check to see if down is pressed
	beq $a0, 115, checkIsUpPressed	#if moving down, check to see if up is pressed
	beq $a0, 97, checkIsRightPressed #if moving left, check to see if right is pressed
	beq $a0, 100, checkIsLeftPressed #if moving right, check to see if left is pressed
	j DirectionCheckFinished # if input is incorrect, get new input
	
checkIsDownPressed:
	beq $a1, 115, unacceptable #if down is pressed while moving up
	#prevent snake from moving into itself
	j acceptable

checkIsUpPressed:
	beq $a1, 119, unacceptable #if up is pressed while moving down
	#prevent snake from moving into itself
	j acceptable

checkIsRightPressed:
	beq $a1, 100, unacceptable #if right is pressed while moving left
	#prevent snake from moving into itself
	j acceptable
	
checkIsLeftPressed:
	beq $a1, 97, unacceptable #if left is pressed while moving right
	#prevent snake from moving into itself
	j acceptable
	
acceptable:
	li $v0, 1
	
	beq $a1, 119, storeUpDirection  #store the location of up direction change
	beq $a1, 115, storeDownDirection #store the location of down direction change	
	beq $a1, 97, storeLeftDirection  #store the location of left direction change
	beq $a1, 100, storeRightDirection #store the location of right direction change
	j DirectionCheckFinished
	
storeUpDirection:
	lw $t4, arrayPosition #get the array index
	la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
	la $t3, newDirectionChangeArray #get address for new direction
	add $t2, $t2, $t4 #add the index to the base
	add $t3, $t3, $t4
		
	sw $a2, 0($t2) #store the coordinates in that index
	li $t5, 119
	sw $t5, 0($t3) #store the direction in that index
	
	addiu $t4, $t4, 4 #increment the array index
	#if the array will go out of bounds, start it back at 0
	bne $t4, 396, UpStop
	li $t4, 0
UpStop:
	sw $t4, arrayPosition	
	j DirectionCheckFinished
	
storeDownDirection:
	lw $t4, arrayPosition #get the array index
	la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
	la $t3, newDirectionChangeArray #get address for new direction
	add $t2, $t2, $t4 #add the index to the base
	add $t3, $t3, $t4
	
	sw $a2, 0($t2) #store the coordinates in that index
	li $t5, 115
	sw $t5, 0($t3) #store the direction in that index

	addiu $t4, $t4, 4 #increment the array index
	#if the array will go out of bounds, start it back at 0
	bne $t4, 396, DownStop
	li $t4, 0

DownStop:	
	sw $t4, arrayPosition
	j DirectionCheckFinished

storeLeftDirection:
	lw $t4, arrayPosition #get the array index
	la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
	la $t3, newDirectionChangeArray #get address for new direction
	add $t2, $t2, $t4 #add the index to the base
	add $t3, $t3, $t4

	sw $a2, 0($t2) #store the coordinates in that index
	li $t5, 97
	sw $t5, 0($t3) #store the direction in that index

	addiu $t4, $t4, 4 #increment the array index
	#if the array will go out of bounds, start it back at 0
	bne $t4, 396, LeftStop
	li $t4, 0

LeftStop:
	sw $t4, arrayPosition
	j DirectionCheckFinished

storeRightDirection:
	lw $t4, arrayPosition #get the array index
	la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
	la $t3, newDirectionChangeArray #get address for new direction
	add $t2, $t2, $t4 #add the index to the base
	add $t3, $t3, $t4
	
	sw $a2, 0($t2) #store the coordinates in that index
	li $t5, 100
	sw $t5, 0($t3) #store the direction in that index

	addiu $t4, $t4, 4 #increment the array index
	#if the array will go out of bounds, start it back at 0
	bne $t4, 396, RightStop
	li $t4, 0

RightStop:
	#store array position
	sw $t4, arrayPosition		
	j DirectionCheckFinished
	
unacceptable:
	li $v0, 0 #direction is not acceptable
	j DirectionCheckFinished
	
Same:
	li $v0, 1
	
DirectionCheckFinished:
	jr $ra
	
##################################################################
# Pause Function
# $a0 - amount to pause
##################################################################
# no return values
##################################################################
Pause:
	li $v0, 32 #syscall value for sleep
	syscall
	jr $ra
	
##################################################################
# Check Fruit Collision
# $a0 - snakeHeadPositionX
# $a1 - snakeHeadPositionY
##################################################################
# returns $v0:
#	0 - does not hit fruit
#	1 - does hit fruit
##################################################################
CheckFruitCollision:
	
	#get fruit coordinates
	lw $t0, fruitPositionX
	lw $t1, fruitPositionY
	#set $v0 to zero, to default to no collision
	add $v0, $zero, $zero	
	#check first to see if x is equal
	beq $a0, $t0, XEqualFruit
	#if not equal end function
	j ExitCollisionCheck
	
XEqualFruit:
	#check to see if the y is equal
	beq $a1, $t1, YEqualFruit
	#if not eqaul end function
	j ExitCollisionCheck
YEqualFruit:
	#update the score as fruit has been eaten
	lw $t5, score
	lw $t6, scoreGain
	add $t5, $t5, $t6
	sw $t5, score
	# play sound to signify score update
	li $v0, 31
	li $a0, 79
	li $a1, 150
	li $a2, 7
	li $a3, 127
	syscall	
	
	li $a0, 96
	li $a1, 250
	li $a2, 7
	li $a3, 127
	syscall
	
	li $v0, 1 #set return value to 1 for collision
	
ExitCollisionCheck:
	jr $ra
	
##################################################################
# Check Snake Body Collision
# $a0 - snakeHeadPositionX
# $a1 - snakeHeadPositionY
# $a2 - snakeHeadDirection
##################################################################
# returns $v0:
#	0 - does not hit body
#	1 - does hit body
##################################################################	
CheckGameEndingCollision:
	#save head coordinates
	add $s3, $a0, $zero
	add $s4, $a1, $zero
	#save return address
	sw $ra, 0($sp)

	beq  $a2, 119, CheckUp
	beq  $a2, 115, CheckDown
	beq  $a2, 97,  CheckLeft
	beq  $a2, 100, CheckRight
	j BodyCollisionDone #for error?
	
CheckUp:
	#look above the current position
	addiu $a1, $a1, -1
	jal CoordinateToAddress
	#get color at screen address
	lw $t1, 0($v0)
	#add $s6, $t1, $zero
	lw $t2, snakeColor
	lw $t3, borderColor
	beq $t1, $t2, Exit #If colors are equal - YOU LOST!
	beq $t1, $t3, Exit #If you hit the border - YOU LOST!
	j BodyCollisionDone # if not, leave function

CheckDown:

	#look below the current position
	addiu $a1, $a1, 1
	jal CoordinateToAddress
	#get color at screen address
	lw $t1, 0($v0)
	#add $s6, $t1, $zero
	lw $t2, snakeColor
	lw $t3, borderColor
	beq $t1, $t2, Exit #If colors are equal - YOU LOST!
	beq $t1, $t3, Exit #If you hit the border - YOU LOST!
	j BodyCollisionDone # if not, leave function

CheckLeft:

	#look to the left of the current position
	addiu $a0, $a0, -1
	jal CoordinateToAddress
	#get color at screen address
	lw $t1, 0($v0)
	#add $s6, $t1, $zero
	lw $t2, snakeColor
	lw $t3, borderColor
	beq $t1, $t2, Exit #If colors are equal - YOU LOST!
	beq $t1, $t3, Exit #If you hit the border - YOU LOST!
	j BodyCollisionDone # if not, leave function

CheckRight:

	#look to the right of the current position
	addiu $a0, $a0, 1
	jal CoordinateToAddress
	#get color at screen address
	lw $t1, 0($v0)
	#add $s6, $t1, $zero
	lw $t2, snakeColor
	lw $t3, borderColor
	beq $t1, $t2, Exit #If colors are equal - YOU LOST!
	beq $t1, $t3, Exit #If you hit the border - YOU LOST!
	j BodyCollisionDone # if not, leave function

BodyCollisionDone:
	lw $ra, 0($sp) #restore return address
	jr $ra		
	
##################################################################
# Increase Difficulty Function
# no parameters
##################################################################
# no return values
##################################################################
IncreaseDifficulty:
	lw $t0, score #get the player's score
	la $t1, scoreMilestones #get the milestones base address
	lw $t2, scoreArrayPosition #get the array position
	add $t1, $t1, $t2 #move to position in array
	lw $t3, 0($t1) #get the value at the array index
	
	#if the player score is not equal to the current milestone
	#exit the function, if they are equal increase difficulty
	bne $t3, $t0, FinishedDiff 
	#increase the index for the milestones array
	addiu $t2, $t2, 4
	#store new position
	sw $t2, scoreArrayPosition
	#load the scoreGain variable to increase the
	#points awarded for eating fruit
	lw $t0, scoreGain
	#multiply gain by 2
	sll $t0, $t0, 1 
	#load the game speed
	lw $t1, gameSpeed
	#subtract 25 from the move speed
	addiu $t1, $t1, -25
	#store new speed
	sw $t1, gameSpeed

FinishedDiff:
	jr $ra

Exit:   
	#play a sound tune to signify game over
	li $v0, 31
	li $a0, 28
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
		
	li $a0, 33
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 47
	li $a1, 1000
	li $a2, 32
	li $a3, 127
	syscall
	
	li $v0, 56 #syscall value for dialog
	la $a0, lostMessage #get message
	lw $a1, score	#get score
	syscall
	
	li $v0, 50 #syscall for yes/no dialog
	la $a0, replayMessage #get message
	syscall
	
	beqz $a0, main#jump back to start of program
	#end program
	li $v0, 10
	syscall