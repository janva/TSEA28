#include <stdint.h>
#include "util.h"

void find_associativity(int nr, int step)
{
  int c=0, i, j;

  for(j = 0 ; j < 2; j++){
    for(i = 0 ; i < nr; i++){
       //läs in ett ord(4 bytes 32 bitar) bas + förskjutning i+step
      c = read_mem32(0x82000000 + i * step);
    }
  }
  small_printf("\nc= 0x%08x\n",c);
}

/* Prototype for assembler version of find_associativity() */
void find_associativity_asm(int nr, int step);

int main(void)
{
  Flush_DCache();                          
  trigger_logic_analyzer();
  find_associativity(9,0x100000);


  return 0;
}
