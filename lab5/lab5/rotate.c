// Remove the comment before this line if you want to do the lab in
// assembler.

// #define ASM_VERSION

#include <stdint.h>
#include "util.h"
#include "memorymap.h"

#include "config.h"


#define MAP_BASE 0x81800000

/* Change this to 0x81000000 and 0x81400000 if you also want to see
   writes to the framebuffer in the logic analyzer. (Although this
   will degrade the performance...) */

#define FB_FRAME0 0x01000000
#define FB_FRAME1 0x01400000

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

	int x;

	for (x=0; x<FB_XSIZE; x++) {
		fb[fb_offset] = map_addr[fixed_point_xy_to_linear(xpos,ypos)];
		fb_offset = fb_offset + 1;
		xpos = xpos + dx;
		ypos = ypos + dy;
	}
}


// Render all lines specified in info
void render_all_lines(struct lineinfo *infoarray)
{
	int y;

	for(y=0; y < FB_YSIZE; y++){
		/* In order to analyze a specific line you may want to
		   add an if statement so you can trigger the logic
		   analyzer only if y == 1 for example. */
		trigger_logic_analyzer();
		render_line(infoarray, y);
	}
}

// Prototype for assembler version of render_all_lines()
void render_all_lines_asm(struct lineinfo *info);

// We are using a static instead of automatic variable here since we
// are pretty short on stack space.
static struct lineinfo thelineinfo[FB_YSIZE]; // Lineinfo for all lines in the framebuffer

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

		thelineinfo[y].map_addr = (uint16_t *) MAP_BASE;
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

void paintloop(void)
{

	int angle;
	uint16_t *fb;

	uint32_t starttime, endtime;

	int current_buffer = 0;

	int speed = 256;
	int xpos = MAP_XSIZE/2*256;
	int ypos = MAP_YSIZE/2*256;
	angle = 90;
	int demo_mode = 0;

	while (1) {
		// This part checks that we are not trying to move outside the map itself
		int out_of_bounds = 0;
		int cosval = fixed_point_cos(angle);
		int sinval = fixed_point_sin(angle);

		xpos = xpos + speed*(sinval)/256;;
		ypos = ypos + speed*(-cosval)/256;

		if(xpos < (FB_XSIZE/2)*256){
			xpos = (FB_XSIZE/2)*256+2;
			out_of_bounds = 1;
		}else if(xpos > (MAP_XSIZE - FB_XSIZE-32)*256){
			xpos = (MAP_XSIZE - FB_XSIZE-32)*256-2;
			out_of_bounds = 1;
		}


		if(ypos < (FB_YSIZE/2)*256){
			ypos = (FB_YSIZE/2)*256+2;
			out_of_bounds = 1;
		}else if(ypos > (MAP_YSIZE - FB_XSIZE-32)*256){
			ypos = (MAP_YSIZE - FB_XSIZE-32)*256-2;
			out_of_bounds = 1;
		}

		if(out_of_bounds){
			small_printf("Going too close to the border!\r\n");
			speed=0;
		}
		
		// If we are in demo mode we should make sure the
		// screen rotates every frame
		if(demo_mode){
			angle = angle + 1;
			if(angle >= 360){
				angle = 0;
			}
		}

		// This part implements the user interface.
		// Notably: Pressing D activates demo mode and
		// pressing q exits the program.
		if(uart_has_data()){
			demo_mode = 0;
			switch(uart_getc()){
			case 'D':
				if(demo_mode) {
					demo_mode = 0;
					break;
				}
				small_printf("Activating demo mode, press any key to quit\r\n");
				xpos = 868*256;
				ypos=356*256;
				speed = 256*7;
				angle = 90;
				demo_mode = 1;
				break;
			case ' ':
				speed = 0;
				break;
			case 'q':
				return;
			case 'a':
				
                                angle = angle - 1;
				if(angle < 0){
					angle = 359;
				}
				break;
			case 'd':
				angle = angle + 1;
				if(angle > 359){
					angle = 0;
				}
				break;
			case 's':
				speed = speed - 16;
				if(speed < 0){
					speed = 0;
				}
				break;
			case 'w':
				speed = speed + 16;
				if(speed > 256*32){
					speed = 256*32;
				}
				break;
			}
		}
		// Flush remaining piled up characters to increase responsiveness
		while(uart_has_data()){
			uart_getc();
		}

		// Figure out the correct buffer to render to
		if(current_buffer == 1){
			fb = (uint16_t *) FB_FRAME1;
			current_buffer = 0;
		}else{
			fb = (uint16_t *) FB_FRAME0;
			current_buffer = 1;
		}

		/* This part is responsible for the main bulk of the runtime cost */
		starttime = get_timer();
		rotate_image(angle, xpos, ypos, fb);
		Flush_DCache(); // Ensure all data hits the framebuffer!
		endtime = get_timer(); // Only measure time after all data has hit the framebuffer.

		// Wait for current VSync and swap the currently showing framebuffer
		int lag; // Tells whether we skipped a frame because rendering took too long.
		if(current_buffer == 1){
			lag = framebuffer_swap(FB_FRAME0);
		}else{
			lag = framebuffer_swap(FB_FRAME1);
		}

		
		// Note: We are running the UART at 115200 baud. This
		// corresponds to about 11520 characters per second
		// (at the default setting of 8N1).
		//
		// This means that we can print about 11520/60 = 192
		// characters per iteration of this loop (assuming the
		// loop runs at full framerate).
		//
		// However, we are further limited by the UART FIFO
		// which only contains 64 characters, all in all. Thus
		// we are limited to a maximum of 64 characters per
		// loop unless we want our performance to degradate
		// severely. (This constraint could be lifted if we
		// used an IRQ driven UART, although this is way
		// too complicated for our current needs.)
		small_printf("Angle: %d, time: %d useconds%s\r\n", angle, 
			     (endtime-starttime)*2/533,
			     lag ? "(LAG!)":"");
			
	}
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
	start_timer();
#ifdef ASM_VERSION
	redraw_reference_image_asm();
#else
	redraw_reference_image();
#endif
	paintloop();
	return 0;
}


