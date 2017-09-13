#include <stdint.h>
#include <stdio.h>
 

void main (void)
{
   printf ("test \n");
   int cosval = fixed_point_cos(90);
   int sinval = fixed_point_sin(90);
   printf ("cosval 90 degrees dx= %d \n",cosval);
   printf ("sinval 90 degrees dy= %d \n",sinval);
   int cosval270 = fixed_point_cos(270);
   int sinval270 = fixed_point_sin(270);
   printf ("cosval 270 degrees dx= %d \n",cosval270);
   printf ("sinval 270 degrees dy= %d \n",sinval270);
   int cosval0 = fixed_point_cos(0);
   int sinval0 = fixed_point_sin(0);
   printf ("cosval 0 degrees dx= %d \n",cosval0);
   printf ("sinval 0 degrees dy= %d \n",sinval0);

}
