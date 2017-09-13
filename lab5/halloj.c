#include <stdio.h>
#include <stdlib.h>
//losningen dela upp hur en address ser ut och räkna 
// enligt formatet
//man page man 3 printf 
//gcc -std=c99 -o halloj halloj.c
void main (void)
{
   printf ("hello world \n");
   int nr=5;
   int step=4000;
   for(int j = 0 ; j < 2; j++)
   {
      for(int i = 0 ; i < nr; i++)
      {
	 printf ("%X \n",(0x82000000 + i * step));
      }
   }
  
   exit(EXIT_SUCCESS);
}
