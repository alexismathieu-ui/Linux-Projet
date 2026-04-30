#include <stdio.h>
#include <stdlib.h>
#include "header.h"

int factorielle( int number )
{
  int result = 1;

  for(int i = 1; i <= number; i++) 
  {
    result *= i;
  }

  return result;
}

int main(int argc, char *argv[]) 
{
  if (argc != 2) 
  {
    printf("Erreur: Mauvais nombre de parametres\n");
    return 1;
  }

  int number = atoi(argv[1]);
  if (number < 0) {
    printf("Erreur: nombre negatif\n");
    return 1;
  }

  int result = factorielle(number);
  printf("%d\n", result);
  return 0;
}