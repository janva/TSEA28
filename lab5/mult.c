// Exempel på cache-effekter för Datorteknik-kursen
// Författare: Andreas Ehliar <ehliar@isy.liu.se>

#include <stdio.h>
#include <stdlib.h>

// Värden att testa: 2000, 2048, (2048+48)
#define MATRIXSIZE 2000
float a[MATRIXSIZE][MATRIXSIZE]; // Deklarera en tvådimensionell array (vår matris) 
float b[MATRIXSIZE]; // Deklarera en endimensionell array (vår vektor)
float c[MATRIXSIZE]; //  - " -  (vårt resultat)

void initialize_data(void)
{
        int i,j;
        for(i=0; i < MATRIXSIZE; i++){
                for(j=0; j < MATRIXSIZE; j++){
                        a[i][j] = rand() / 10000.0;
                }
                b[i] = rand() / 10000.0;
        }
}
// En funktion som multiplicerar matrisen a med vektorn b
static void matrix_mul(void)
{
        int i,j; // Deklarera två heltalsvariabler
	// En for-loop fungerar på följande sätt i C:
	// for(sätt loopvariabelns startvärde; villkor som ska uppfyllas för att vi ska fortsätta i loopen; uppräkning av loopvariabeln)
        //
        // Det vill säga: Följande for-loop loopar 2000 gånger där i räknas upp från 0 till 1999 (om nu MATRIXSIZE är 2000)
        for(i=0; i < MATRIXSIZE; i = i + 1){
	  float result = 0; // Deklarera flyttalsvariabeln result
                for(j=0; j < MATRIXSIZE; j++){
                        // Notering: Om du byter plats på i och j
                        // nedan (dvs transponerar matrisen) kommer
                        // programmet gå mycket långsammare på grund
                        // av att cachen inte utnyttjas särskilt
                        // effektivt!
			result = result + a[j][i]*b[j];
		}
		c[i] = result;
	}
}
// Notering: Det var en del på föreläsningen som frågade om det inte
// var bakvänt att läsa i a på det sätt jag gjorde ifrån
// början. Anledningen till detta var att jag valde att börja med det
// osmarta sättet att lagra matrisen i minnet. Däremot kan man
// konstatera att om du vill multiplicera två matriser med varandra så
// kan du inte undvika att läsa en matris i fel ordning. (Däremot så
// kommer du (om du använder den naiva implementationen ovan) att
// tjäna på att först transponera en av matriserna innan du kör
// matrismultiplikationen.)


int main(int argc, char **argv)
{
	int i;
	initialize_data();
	// Kör funktionen ett antal gånger eftersom det annars blir
	// svårare att få bra mätvärden eftersom funktionen i själv
	// går ganska snabbt att köra.
	for(i=0; i < 1000; i++){
		matrix_mul();
	}
}


// Tid för att köra de olika varianterna (på min laptop):
// MATRIXSIZE = 2000, a[i][j] i loopen ovan: Cirka 4.8s
// MATRIXSIZE = 2048, a[i][j] i loopen ovan: Cirka 5.1s
// MATRIXSIZE = 2092, a[i][j] i loopen ovan: Cirka 5.3s

// MATRIXSIZE = 2000, a[j][i] i loopen ovan: Cirka 37s
// MATRIXSIZE = 2048, a[j][i] i loopen ovan: Cirka 69s
// MATRIXSIZE = 2092, a[j][i] i loopen ovan: Cirka 39s
