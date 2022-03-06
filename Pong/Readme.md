# Pong

Game of Pong. Two player, using Up/Down cursor keys and A/Z. UTF8 sprites. Angle determined by point of contact. 
Scores displayed using UTF8 block characters.

## Files:
1) pong.pl   Non object orientated clone of PONG: depends on Term::ReadKey, Time::Hires, utf8
2) pong-coop.pl   Uses classic packages
3) ---once written pong_corinna.pl   would use Object pad
4) etc.

![Pong](https://github.com/saiftynet/dummyrepo/blob/main/Pooppi/pong.gif)

## Objects

### Sprite
* Offers the game objects which have shape, position, motion (velocity and accelration), and colour.
* The objects can be drawn, wiped, moved, can be placed absolutely or relatively.
* There is scope for other animations, including rotations and flipping
* Methods exist for detecting collisions and boundaries.
* Methods for determing center of object and the relative positions of two objects' centers.

### Display
* Similar in function to Term:: AnsiColor (may be replaced by this to allow display in Windows)
* Offers the ability to place a character at arbitrary positions on the terminal
* Methods for colouring the displayed characters
* Some drawing primitives.


