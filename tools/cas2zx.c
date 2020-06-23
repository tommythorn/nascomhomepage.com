/*
 *	NASCOM CAS file to ZX Spectrum headerless TAP file converter
 *
 *	By Stefano bodrato 10/11/2003 - based on a skeleton by Dominic Morris
 *
 */

#include <stdio.h>

/* stdlib.h is needed for binary files for Win compilers*/
#include <stdlib.h>

unsigned char parity;

void writebyte(unsigned char, FILE *);
void writeword(unsigned int, FILE *);

int main(int argc, char *argv[])
{
	char	name[11];
	FILE	*fpin, *fpout;
	int	c;
	int	i;
	int	len;
	if ((argc < 3 )||(argc > 4 )) {
		fprintf(stdout,"Usage: %s [Nascom CAS file] [Spectrum TAP file]\n",argv[0]);
		exit(1);
	}

	
	if ( (fpin=fopen(argv[1],"rb") ) == NULL ) {
		printf("Can't open input file\n");
		exit(1);
	}


/*
 *	Now we try to determine the size of the file
 *	to be converted
 */
	if	(fseek(fpin,0,SEEK_END)) {
		printf("Couldn't determine size of file\n");
		fclose(fpin);
		exit(1);
	}

	len=ftell(fpin);

	fseek(fpin,305L,SEEK_SET);

	if ( (fpout=fopen(argv[2],"wb") ) == NULL ) {
		printf("Can't open output file\n");
		exit(1);
	}


/* Now onto the data bit */
	//writeword(len+2-305-21*((int)(i-249)/277),fpout);	/* Length of next block */
	writeword(len+2-305-21*((len-249)/277),fpout);	/* Length of block */
	parity=0;
	writebyte(255,fpout);	/* Data... */
	for (i=305; i<len;i++) {

		if ( ((i-249)%277) == 0 )
			for(c=0; c<21;c++)
			{
				i++;
				getc(fpin);
			}

		c=getc(fpin);
		writebyte(c,fpout);
	}
	writebyte(parity,fpout);
	fclose(fpin);
	fclose(fpout);
}


void writeword(unsigned int i, FILE *fp)
{
	writebyte(i%256,fp);
	writebyte(i/256,fp);
}



void writebyte(unsigned char c, FILE *fp)
{
	fputc(c,fp);
	parity^=c;
}
