#include <stdint.h>
#include "util.h"

int fetchtest(uint8_t *test, int sum);

int main(void)
{
   	small_printf ("(uint8_t *) 0x85123456= %x",(uint8_t *) 0x85123456);
	trigger_logic_analyzer();
	return fetchtest((uint8_t *) 0x85123456,1);
		
}

