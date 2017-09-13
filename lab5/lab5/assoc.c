#include <stdint.h>
#include "util.h"
/*
 * Om minnet hade varit direktmappat cache så hade varje cachemängd varit
 * 512kb är uppdelat i 16384 (decimalt) cache lines (en line är 8 ord a 4byte (8*32 bitear))
 * det betyder att var 16384:de cache line har samma index vilket rimligvis då borde leda till
 * en kollision. Men hur många kollisioner vill vi ha? mellan 2 och 8? beroende associativitet
 * hur yttrar detta sig på axi bussen????  nr bli associsiativetetn och step blir kollisionlängd
 * 512KB =524288B = hex 80000
 **/
void find_associativity(int nr, int step)
{
   int c=0, i, j;
   
   for(j = 0 ; j < 2; j++){
      for(i = 0 ; i < nr; i++){
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
  find_associativity(ANTAL,STEGLANGD);

  return 0;
}
