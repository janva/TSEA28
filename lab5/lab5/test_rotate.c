// Remove the comment before this line if you want to do the lab in
// assembler.

// #define ASM_VERSION

#include <stdint.h>
#include <stdio.h>
#include "util_dummy.h"
#include "memorymap.h"

#include "config.h"

#define SEGMENTED_MODE
#define MAP_BASE 0x81800000

/* Change this to 0x81000000 and 0x81400000 if you also want to see
   writes to the framebuffer in the logic analyzer. (Although this
   will degrade the performance...) */

#define FB_FRAME0 0x01000000
#define FB_FRAME1 0x01400000

//NOTE shit in shit out use correct numbers :-)
const int SEGMENT_LENGTH =32;
//const int NR_OF_SEGMENTS = FB_XSIZE/240;
#define NR_OF_SEGMENTS  FB_XSIZE/SEGMENT_LENGTH

/*converts from fixed point (24.8) to int*/
static inline int fixed_point_xy_to_linear(int x,int y)
{
	return (y/256)*MAP_XSIZE + x/256;
}


struct lineinfo{
	uint16_t *map_addr;
	int startx; // Coordinates in 24.8 fixed point format
	int starty; // Coordinates in 24.8 fixed point format
	int dx; // Delta-X in 24.8 fixed point format
	int dy; // Delta-X in 24.8 fixed point format
	uint16_t *fb;
	int fb_offset;
};


/* Note that the assembler version of render_line() works slightly
   differently as it takes only one argument (a direct pointer to
   infoarray[y] instead of a pointer to the start of the infoarray
   structure plus an offset into it). */


/* Render a line in the framebuffer according to the information
   located in infoarray[y] */
void render_line(struct lineinfo *infoarray, int y)
{
	uint16_t *map_addr = infoarray[y].map_addr;

	int xpos = infoarray[y].startx;
	int ypos = infoarray[y].starty;
	uint16_t *fb = infoarray[y].fb;
	int fb_offset = infoarray[y].fb_offset;
	int dx = infoarray[y].dx;
	int dy = infoarray[y].dy;

        //TODO from where we last left to where we last left +segment_size
        // store position or calc position where w last left into lineinfo
	//int x;
	int x;
#ifndef SEGMENTED_MODE
	for (x=0; x<FB_XSIZE; x++) {
#else
	 for (x=0; x<SEGMENT_LENGTH; ++x) {
#endif
//printf ("fb_offset: %d\n", fb_offset);
//printf ("fb[fb_offset]: %d\n", fb[fb_offset]);
//printf ("fixed_point_xy_to_linear (xpos,ypos): %x\n", fixed_point_xy_to_linear(xpos,ypos));
printf ("Accessed ref-img @ 0x81800000 + offset : %x\n", 
	   (0x81800000 + (fixed_point_xy_to_linear(xpos,ypos))));
                fb[fb_offset] = map_addr[fixed_point_xy_to_linear(xpos,ypos)];
		fb_offset = fb_offset + 1;
		xpos = xpos + dx;
		ypos = ypos + dy;
	}
//store last position no need to add anything to struct lineifo since img
//rotation is allways built from scratch using ref image.
// Eventuellt behöver vi stega fram ett steg oxå 
infoarray[y].fb_offset = fb_offset;
infoarray[y].startx =xpos;
infoarray[y].starty= ypos;

printf("-----------------new col------------------\n");
}
// Render all lines specified in info
void render_all_lines(struct lineinfo *infoarray)
{
	int x;
	int y;
  #ifdef SEGMENTED_MODE
	for (x=0; x<NR_OF_SEGMENTS; ++x)
	{
   #endif
	   //for(y=0; y < FB_YSIZE; y++){
	   for(y=0; y < 10; y++){
	      /* In order to analyze a specific line you may want to
		 add an if statement so you can trigger the logic
		 analyzer only if y == 1 for example. */
	      //trigger_logic_analyzer();
	      render_line(infoarray, y);
	   }
	   printf("-----------------new iteration------------------\n");

	}
}

// Prototype for assembler version of render_all_lines()
void render_all_lines_asm(struct lineinfo *info);

// We are using a static instead of automatic variable here since we
// are pretty short on stack space.
static struct lineinfo thelineinfo[FB_YSIZE]; // Lineinfo for all lines in the framebuffer
uint16_t MAP[4194304];
void rotate_image(int angle, int xpos, int ypos, uint16_t *fb)
{
	int cosval = fixed_point_cos(angle);
	int sinval = fixed_point_sin(angle);
	int xr,yr,xs,ys;
	int y;
	// First we setup the render parameters for each row
	for (y=0; y < FB_YSIZE; y++){
		ys = y - FB_YSIZE/2;
		xs =  - FB_XSIZE/2;
		// Rotate the start coordinates by multiplying with the rotation matrix
		xr = cosval*xs - sinval*ys;
		yr = sinval*xs + cosval*ys;
		// And translate the start coordinates by adding the current position
		xr = xr  + xpos;
		yr = yr  + ypos;

		//	thelineinfo[y].map_addr = (uint16_t *) MAP_BASE;
		thelineinfo[y].map_addr = (uint16_t *) MAP;

                thelineinfo[y].startx = xr + 128; // By adding 128 we ensure that we get slightly
		thelineinfo[y].starty = yr + 128; // better rounding 
		thelineinfo[y].fb = fb;
		thelineinfo[y].fb_offset = y*FB_XSIZE;
		
		thelineinfo[y].dx = cosval;
		thelineinfo[y].dy = sinval;
	}

	// Then we render all lines using these parameters using the
	// appropriate function.
#ifdef ASM_VERSION
	render_all_lines_asm(thelineinfo);
#else
	render_all_lines(thelineinfo);
#endif	
}

void mypaint (int angle)
{
   uint16_t fb[307200];
   int xpos = MAP_XSIZE/2*256;
   int ypos = MAP_YSIZE/2*256;
   angle = 90;

   angle = angle - 1;
   if(angle < 0){
      angle = 359;
   }
   rotate_image(angle, xpos, ypos, fb);
}

 // Prototype for assembler version of redraw_reference_image()
void redraw_reference_image_asm(void);

void redraw_reference_image(void)
{
	// If you believe that you need to do so you can redraw the
	// reference image in this function.
}

int main(void)
{
   //start_timer();
#ifdef ASM_VERSION
	redraw_reference_image_asm();
#else
	redraw_reference_image();
#endif
	mypaint(0);
	return 0;
}


