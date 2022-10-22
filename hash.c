#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

void usage()
{
  printf("Usage: ./hash  [--sentinel] \"my_string\"\n");
}

uint_fast32_t dl_new_hash(const char *s)
{
  uint_fast32_t h = 5381;
  for(unsigned char c = *s; c != '\0'; c = *++s)
  {
    h = h * 33 + c;
  }
  return h & 0xffffffff;
}

int main(int argc,char **argv)
{
  int sentinel;
  int strindex;
  uint_fast32_t hash;

  if(argc < 2)
  {
    usage();
    exit(1);
  }
  else if(argc < 3)
  {
    sentinel = 0;
    strindex = 1;
  }
  else if(argc < 4 && !strcmp(argv[1],"--sentinel"))
  {
    sentinel = 1;
    strindex = 2;
  }
  else
  {
    usage();
    exit(1);
  }

  hash = dl_new_hash(argv[strindex]);

  if(sentinel)
    hash |= 1;
  else
    hash &= (-2);

  printf("%lx\n",(unsigned long)hash);
  exit(0);
}
