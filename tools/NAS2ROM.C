/* Very trivial little code snipped to convert the Nassys 'L' format
   (we call that the "NAS" format) to the raw format, suitable for
   EPROM 

   -- Tommy Thorn 21st of Februar, 2000

   Usage: ./nas2rom < foobar.nas > foobar.rom
*/

#include <stdio.h>

main()
{
  int a, b1, b2, b3, b4, b5, b6, b7, b8, dummy;
  for (;;) {
    if (scanf("%x %x %x %x %x %x %x %x %x %x\010\010\n",
	      &a, &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8, &dummy)
	== 10) {
      putchar(b1);
      putchar(b2);
      putchar(b3);
      putchar(b4);
      putchar(b5);
      putchar(b6);
      putchar(b7);
      putchar(b8);
    }
    else break;
  }
}

