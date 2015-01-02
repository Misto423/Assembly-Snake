Assembly-Snake
==============

Snake made in Mips assembly code.

Created using the Mars Mips simulator.

This program requires the Keyboard and Display MMIO and the Bitmap Display to be connected to MIPS.

Bitmap Display Settings:
Unit Width: 8
Unit Height: 8
Display Width: 512
Display Height: 512
Base Address for Display: 0x10008000 ($gp)

Standard snake game, use the arrow keys to move around and eat the pellets to increase score.  After certain scores are reached
the snake's speed will increase.