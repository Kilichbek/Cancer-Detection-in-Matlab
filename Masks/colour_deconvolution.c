/*
	Translated from ImageJ Java Pluging into MATLAB MEX c code by
	Tom Macura <tmacura@nih.gov>
	July 21st, 2006
	
	6/Nov/2006 changed the code to also work with 16bit RGBs
*/

/* G.Landini at bham ac uk
   30/Mar/2004 released
   03/Apr/2004 resolved ROI exiting
   07/Apr/2004 added Methyl Green DAB vectors
   08/Jul/2004 shortened the code
   01/Aug/2005 added fast red/blue/DAB vectors
   02/Nov/2005 changed code to work with image stacks (DLC - dchao at fhcrc org)
   02/Nov/2005 changed field names so user-defined colours can be set within 
               macros (DLC - dchao at fhcrc org)
   This plugin implements stain separation using the colour deconvolution
   method described in:
       Ruifrok AC, Johnston DA. Quantification of histochemical
       staining by color deconvolution. Analytical & Quantitative
       Cytology & Histology 2001; 23: 291-299.
   The code is based on "Color separation-30", a macro for NIH Image kindly provided
   by A.C. Ruifrok. Thanks Arnout!
   The plugin assumes images generated by color subtraction (i.e. light-absorbing dyes
   such as those used in bright field histology or ink on printed paper) but the dyes
   should not be neutral grey.
   I strongly suggest to read the paper reference above to understand how to determine
   new vectors and how the whole procedure works.
   The plugin works correctly when the background is neutral (white to light grey), 
   so background subtraction and colour correction must be applied to the images before 
   processing.
 
   The plugin provides a number of "bulit in" stain vectors some of which were determined
   experimentally in our lab (marked GL), but you may have to determine your own vectors to
   provide a more accurate stain separation, depending on the stains and methods you use.
   Ideally, vector determination should be done on slides stained with only one colour
   at a time (using the "From ROI" interactive option).
 
   The plugin takes an RGB image and returns three 8-bit images. If the specimen is
   stained with a 2 colour scheme (such as H & E) the 3rd image represents the
   complimentary of the first two colours (i.e. green).
  
   Please be *very* careful about how to interpret the results of colour deconvolution
   when analysing histological images.
   Most staining methods are not stochiometric and so intensity of the chromogen
   may not correlate well with the quantity of the reactants.
   This means that intensity of the colour may not be a good indicator of
   the amount of material stained.
   Read the paper!
*/

#include "mex.h"
#include "matrix.h"
#include <math.h>
/*#include "ome-Matlab.h"  backwards compatiblity to mwSize/mwIndex */

#include <sys/types.h>
#include <string.h>
#include <stdlib.h>

typedef uint16_T u_int16_t;
typedef uint8_T u_int8_t;

double to_8bit_range (u_int16_t X16, u_int16_t min, u_int16_t max);

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	const mwSize* dims;
	const mxArray*  img_mxArray;
	const u_int8_t* img = NULL;
	const u_int16_t* img16 = NULL;
    
    /*These variable definitions were moved here.*/
    mwSize num_of_dims;
    double MODx[3];
	double MODy[3];
	double MODz[3];
    double leng, A, V, C, log255=log(255.0);
	double cosx[3];
	double cosy[3];
	double cosz[3];
	double len[3];
	double q[9];
	int i,j;
    int imagesize;
    
	char* myStain;
	if (nrhs != 2)
		mexErrMsgTxt("\n [stain1, stain2, stain3] = colour_deconvolution (im, StainingMethod),\n\n"
		"This function takes an RGB image (either 8/16bit) and returns three uint8/uint16 images\n"
		"with separated stains. If the specimen is stained with a 2 colour scheme (such as H & E)\n"
		"the 3rd image represents the complimentary of the first two colours (i.e. green).\n"
		"\n"
		"StainingMethod can be a struct defining stain vectors or a a string refering to\n"
		"one of the built-in stain vectors.\n"
		"\n"
		"For example, the struct defining the H&E staining method would be defined thus:\n"
		" StainingMethod.MODx_0 = 0.644211;\n"
		" StainingMethod.MODy_0 = 0.716556;\n"
		" StainingMethod.MODz_0 = 0.266844;\n"
		" StainingMethod.MODx_1 = 0.092789;\n"
		" StainingMethod.MODy_1 = 0.954111;\n"
		" StainingMethod.MODz_1 = 0.283111;\n"
		" StainingMethod.MODx_2 = 0.0;\n"
		" StainingMethod.MODy_2 = 0.0;\n"
		" StainingMethod.MODz_2 = 0.0;\n"
		"\n"
		"The built-in vectors are:\n"
		" Haematoxylin and Eosin determined by G.Landini ('H&E')\n"
		" Haematoxylin and Eosin determined by A.C.Ruifrok ('H&E 2')\n"
		" Haematoxylin and DAB ('H DAB')\n"
		" Haematoxylin, Eosin and DAB ('H&E DAB')\n"
		" Haematoxylin and AEC ('H AEC')\n"
		" Fast Red, Fast Blue and DAB ('FastRed FastBlue DAB')\n"
		" Methyl green and DAB ('Methyl Green DAB')\n"
		" Azan-Mallory ('Azan-Mallory')\n"
		" Alcian blue & Haematoxylin ('Alcian blue & H')\n"
		" Haematoxylin and Periodic Acid of Schiff ('H PAS')\n"
		" RGB subtractive ('RGB')\n"
		" CMY subtractive ('CMY')\n");
		
	else if (nlhs < 1)
		mexErrMsgTxt ("colour_deconvolution returns at-least a single output.\n");
	
	if (mxIsUint8(prhs[0]))
		img = (u_int8_t*) mxGetData(prhs[0]);
	else if (mxIsUint16(prhs[0]))
		img16 = (u_int16_t*) mxGetData(prhs[0]);
	else
		mexErrMsgTxt("colour_deconvolution requires the first input be uint8 or uint16\n");

	dims = mxGetDimensions(prhs[0]);
	
	if (!(dims[0] > 1) || !(dims[1] > 1))
		mexErrMsgTxt("colour_deconvolution requires an input image, not a scalar.\n") ;
		
	num_of_dims = mxGetNumberOfDimensions(prhs[0]);
	if ((num_of_dims != 3) && (num_of_dims != 4) ) {		
		char err_str[128];
		sprintf(err_str, "colour_deconvolution requires a 3D input image where the third dimension is channel. The current image is %dd)", num_of_dims);
		mexErrMsgTxt(err_str);
	}
	
	/*
		This is hacked code required to get colour_deconvolution to work with
		the AE. OME assumes the 5D pixel model with the 3rd dimension being the
		z-section and the 4rd dimension the channel.
		
		The Matlab TIFF importer assumes the 3rd dimension is the channel.
		
		The unified ROI model will regularize things.
		
		The colour_deconvolution code works either way because of this trick,
		which is based onto deep hooks into MATLAB array serialization
		
			int R = img[i];
			int G = img[i+imagesize];
			int B = img[i+2*imagesize];
	*/
	if (num_of_dims == 4) {
		/* it's OKAY but only because of the clever code */
		;
	}

	/**********************************************************************
	* Compose the stain-vectors; either based on the inputed MATLAB struct
	* of the stain-vectors, or based on the built-in vectors
	***********************************************************************/
/*	double MODx[3];
	double MODy[3];
	double MODz[3];
 */
	
	if (mxIsStruct(prhs[1])) {
		MODx[0] = mxGetScalar(mxGetField(prhs[1], 0, "MODx_0"));
		MODy[0] = mxGetScalar(mxGetField(prhs[1], 0, "MODy_0"));
		MODz[0] = mxGetScalar(mxGetField(prhs[1], 0, "MODz_0"));

		MODx[1] = mxGetScalar(mxGetField(prhs[1], 0, "MODx_1"));
		MODy[1] = mxGetScalar(mxGetField(prhs[1], 0, "MODy_1"));
		MODz[1] = mxGetScalar(mxGetField(prhs[1], 0, "MODz_1"));
		
		MODx[2] = mxGetScalar(mxGetField(prhs[1], 0, "MODx_2"));
		MODy[2] = mxGetScalar(mxGetField(prhs[1], 0, "MODy_2"));
		MODz[2] = mxGetScalar(mxGetField(prhs[1], 0, "MODz_2"));
	} else if (mxIsChar(prhs[1])) {	
		myStain = mxArrayToString(prhs[1]);
		if (!strcmp(myStain,"H&E") || !strcmp(myStain,"HE")){
			/* GL Haem matrix */
			MODx[0]= 0.644211;
			MODy[0]= 0.716556;
			MODz[0]= 0.266844;
			/* GL Eos matrix */
			MODx[1]= 0.092789;
			MODy[1]= 0.954111;
			MODz[1]= 0.283111;
			/*  Zero matrix */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;


		} else if (!strcmp(myStain, "H&E MINERVA") || !strcmp(myStain, "HE MINERVA")){
			/* MINERVA Haem matrix */
			MODx[0] = 0.581623;
			MODy[0] = 0.67548984;
			MODz[0] = 0.45324185;
			/* MINERVA Eos matrix */
			MODx[1] = 0.16757342;
			MODy[1] = 0.85218674;
			MODz[1] = 0.49567825;
			/*  Zero matrix */
			MODx[2] = 0.0;
			MODy[2] = 0.0;
			MODz[2] = 0.0;

		} else if (!strcmp(myStain,"H&E 2") || !strcmp(myStain,"HE 2")){
			/* GL Haem matrix */
			MODx[0]= 0.650;
			MODy[0]= 0.704;
			MODz[0]= 0.286;
			/* GL Eos matrix */
			MODx[1]= 0.072;
			MODy[1]= 0.990;
			MODz[1]= 0.105;
			/*  Zero matrix */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"H DAB")){
			/* 3,3-diamino-benzidine tetrahydrochloride
			   Haem matrix */
			MODx[0]= 0.650;
			MODy[0]= 0.704;
			MODz[0]= 0.286;
			/* DAB matrix */
			MODx[1]= 0.268;
			MODy[1]= 0.570;
			MODz[1]= 0.776;
			/* Zero matrix */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"FastRed FastBlue DAB")){
			/* fast red */
			MODx[0]= 0.21393921;
			MODy[0]= 0.85112669;
			MODz[0]= 0.47794022;
			/* fast blue */
			MODx[1]= 0.74890292;
			MODy[1]= 0.60624161;
			MODz[1]= 0.26731082;
			/* dab */
			MODx[2]= 0.268;
			MODy[2]= 0.570;
			MODz[2]= 0.776;
		} else if (!strcmp(myStain,"Methyl Green DAB")){
			/* MG matrix (GL) */
			MODx[0]= 0.98003;
			MODy[0]= 0.144316;
			MODz[0]= 0.133146;
			/* DAB matrix */
			MODx[1]= 0.268;
			MODy[1]= 0.570;
			MODz[1]= 0.776;
			/* Zero matrix */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"H&E DAB")){
			/* Haem matrix */
			MODx[0]= 0.650;
			MODy[0]= 0.704;
			MODz[0]= 0.286;
			/* Eos matrix */
			MODx[1]= 0.072;
			MODy[1]= 0.990;
			MODz[1]= 0.105;
			/* DAB matrix */
			MODx[2]= 0.268;
			MODy[2]= 0.570;
			MODz[2]= 0.776;
		} else if (!strcmp(myStain,"H AEC")){
			/* 3-amino-9-ethylcarbazole
				   Haem matrix */
			MODx[0]= 0.650;
			MODy[0]= 0.704;
			MODz[0]= 0.286;
			/* AEC matrix */
			MODx[1]= 0.2743;
			MODy[1]= 0.6796;
			MODz[1]= 0.6803;
			/* Zero matrix */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"Azan-Mallory")){
			/* Azocarmine and Aniline Blue (AZAN)
			   GL Blue matrix */
			MODx[0]= .853033;
			MODy[0]= .508733;
			MODz[0]= .112656;
			/* GL Red matrix */
			MODx[1]= 0.070933;
			MODy[1]= 0.977311;
			MODz[1]= 0.198067;
			/* Orange matrix (not set yet, currently zero) */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"Alcian blue & H")){
			/* GL Alcian Blue matrix */
			MODx[0]= 0.874622;
			MODy[0]= 0.457711;
			MODz[0]= 0.158256;
			/* GL Haematox after PAS matrix */
			MODx[1]= 0.552556;
			MODy[1]= 0.7544;
			MODz[1]= 0.353744;
			/* Zero matrix */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"H PAS")){
			/* GL Haem matrix */
			MODx[0]= 0.644211; /* 0.650; */
			MODy[0]= 0.716556; /* 0.704; */
			MODz[0]= 0.266844; /* 0.286; */
			/* GL PAS matrix */
			MODx[1]= 0.175411;
			MODy[1]= 0.972178;
			MODz[1]= 0.154589;
			/* Zero matrix */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"RGB")){
			/* R */
			MODx[0]= 0.0;
			MODy[0]= 1.0;
			MODz[0]= 1.0;
			/* G */
			MODx[1]= 1.0;
			MODy[1]= 0.0;
			MODz[1]= 1.0;
			/* B */
			MODx[2]= 1.0;
			MODy[2]= 1.0;
			MODz[2]= 0.0;
		} else if (!strcmp(myStain,"CMY")){
			/* C */
			MODx[0]= 1.0;
			MODy[0]= 0.0;
			MODz[0]= 0.0;
			/* M */
			MODx[1]= 0.0;
			MODy[1]= 1.0;
			MODz[1]= 0.0;
			/* Y */
			MODx[2]= 0.0;
			MODy[2]= 0.0;
			MODz[2]= 1.0;
		} else {
			char err_str[128];
			sprintf(err_str, "colour_deconvolution doesn't support the stain %s", myStain);
			mexErrMsgTxt(err_str);
		}
	} else {
		mexErrMsgTxt("colour_deconvolution requires the second input to specify the stain-vectors via a string or struct\n");
	}
	
	/**********************************************************************
	*  Convert the stain vectors into the 'q' vector
	***********************************************************************/
/*	double leng, A, V, C, log255=log(255.0);
	double cosx[3];
	double cosy[3];
	double cosz[3];
	double len[3];
	double q[9];
	int i,j;
 */
	
	for (i=0; i<3; i++){
		/* normalise vector length */
		cosx[i]=cosy[i]=cosz[i]=0.0;
		len[i]=sqrt(MODx[i]*MODx[i] + MODy[i]*MODy[i] + MODz[i]*MODz[i]);
		if (len[i] != 0.0){
			cosx[i]= MODx[i]/len[i];
			cosy[i]= MODy[i]/len[i];
			cosz[i]= MODz[i]/len[i];
		}
	}

	/* translation matrix */
	if (cosx[1]==0.0){ /* 2nd colour is unspecified */
		if (cosy[1]==0.0){
			if (cosz[1]==0.0){
				cosx[1]=cosz[0];
				cosy[1]=cosx[0];
				cosz[1]=cosy[0];
			}	
		}
	}

	if (cosx[2]==0.0){ /* 3rd colour is unspecified */
		if (cosy[2]==0.0){
			if (cosz[2]==0.0){
				if ((cosx[0]*cosx[0] + cosx[1]*cosx[1])> 1)
					cosx[2]=0.0;
				else
					cosx[2]=sqrt(1.0-(cosx[0]*cosx[0])-(cosx[1]*cosx[1]));

				if ((cosy[0]*cosy[0] + cosy[1]*cosy[1])> 1)
					cosy[2]=0.0;
				else
					cosy[2]=sqrt(1.0-(cosy[0]*cosy[0])-(cosy[1]*cosy[1]));

				if ((cosz[0]*cosz[0] + cosz[1]*cosz[1])> 1)
					cosz[2]=0.0;
				else
					cosz[2]=sqrt(1.0-(cosz[0]*cosz[0])-(cosz[1]*cosz[1]));
			}
		}
	}

	leng= sqrt(cosx[2]*cosx[2] + cosy[2]*cosy[2] + cosz[2]*cosz[2]);

	cosx[2]= cosx[2]/leng;
	cosy[2]= cosy[2]/leng;
	cosz[2]= cosz[2]/leng;

	/* matrix inversion */
	A = cosy[1] - cosx[1] * cosy[0] / cosx[0];
	V = cosz[1] - cosx[1] * cosz[0] / cosx[0];
	C = cosz[2] - cosy[2] * V/A + cosx[2] * (V/A * cosy[0] / cosx[0] - cosz[0] / cosx[0]);
	q[2] = (-cosx[2] / cosx[0] - cosx[2] / A * cosx[1] / cosx[0] * cosy[0] / cosx[0] + cosy[2] / A * cosx[1] / cosx[0]) / C;
	q[1] = -q[2] * V / A - cosx[1] / (cosx[0] * A);
	q[0] = 1.0 / cosx[0] - q[1] * cosy[0] / cosx[0] - q[2] * cosz[0] / cosx[0];
	q[5] = (-cosy[2] / A + cosx[2] / A * cosy[0] / cosx[0]) / C;
	q[4] = -q[5] * V / A + 1.0 / A;
	q[3] = -q[4] * cosy[0] / cosx[0] - q[5] * cosz[0] / cosx[0];
	q[8] = 1.0 / C;
	q[7] = -q[8] * V / A;
	q[6] = -q[7] * cosy[0] / cosx[0] - q[8] * cosz[0] / cosx[0];

	
	/************************************************************************
	* Apply the 'q' vector to the original RGB image to make some new stain images
	*************************************************************************/
	if (img) { /* it's an 8bit img */
		u_int8_t* img_stain1;
		u_int8_t* img_stain2;
		u_int8_t* img_stain3;

		plhs[0] = mxCreateNumericMatrix(dims[0], dims[1], mxUINT8_CLASS, mxREAL);
		img_stain1 = (u_int8_t*) mxGetData(plhs[0]);
		plhs[1] = mxCreateNumericMatrix(dims[0], dims[1], mxUINT8_CLASS, mxREAL);
		img_stain2 = (u_int8_t*) mxGetData(plhs[1]);
		plhs[2] = mxCreateNumericMatrix(dims[0], dims[1], mxUINT8_CLASS, mxREAL);
		img_stain3 = (u_int8_t*) mxGetData(plhs[2]);
		
        imagesize = dims[0] * dims[1];
        
        for (i=0; i<imagesize;i++){
			/* log transform the RGB data */
			u_int8_t R = img[i];
			u_int8_t G = img[i+imagesize];
			u_int8_t B = img[i+2*imagesize];
	
			double Rlog = -((255.0*log(((double)R+1)/255.0))/log255);
			double Glog = -((255.0*log(((double)G+1)/255.0))/log255);
			double Blog = -((255.0*log(((double)B+1)/255.0))/log255);

			for (j=0; j<3; j++){
				/* rescale to match original paper values */
				double Rscaled = Rlog * q[j*3];
				double Gscaled = Glog * q[j*3+1];
				double Bscaled = Blog * q[j*3+2];

				double output = exp(-((Rscaled + Gscaled + Bscaled) - 255.0) * log255 / 255.0);
				if(output>255) output=255;
			
				if (j==0) {
					img_stain1[i] = (u_int8_t)(floor(output+.5));
				} else if (j==1) {
					img_stain2[i] = (u_int8_t)(floor(output+.5));
				} else {
					img_stain3[i] = (u_int8_t)(floor(output+.5));
				}
			}
		}
	} else { /* it must be a 16bit image */
		u_int16_t* img_stain1;
		u_int16_t* img_stain2;
		u_int16_t* img_stain3;

        u_int16_t min;
		u_int16_t max;


		plhs[0] = mxCreateNumericMatrix(dims[0], dims[1], mxUINT16_CLASS, mxREAL);
		img_stain1 = (u_int16_t*) mxGetData(plhs[0]);
		plhs[1] = mxCreateNumericMatrix(dims[0], dims[1], mxUINT16_CLASS, mxREAL);
		img_stain2 = (u_int16_t*) mxGetData(plhs[1]);
		plhs[2] = mxCreateNumericMatrix(dims[0], dims[1], mxUINT16_CLASS, mxREAL);
		img_stain3 = (u_int16_t*) mxGetData(plhs[2]);
		
		imagesize = dims[0] * dims[1];
		
		/* figure out the R channel's min and max intensity */
		min = img16[0];
		max = img16[0];
		for (i=1; i<imagesize;i++ ) {
			if (img16[i] < min)
				min = img16[i];
			else if (img16[i] > max)
				max = img16[i];
		}


		for (i=0; i<imagesize;i++){
			/* log transform the RGB data */
			u_int16_t R16 = img16[i];
			u_int16_t G16 = img16[i+imagesize];
			u_int16_t B16 = img16[i+2*imagesize];
			
			/* convert R,G,B from 16bit to 8 */
			double R = to_8bit_range (R16, min, max);
			double G = to_8bit_range (G16, min, max);
			double B = to_8bit_range (B16, min, max);

			double Rlog = -((255.0*log((R+1)/255.0))/log255);
			double Glog = -((255.0*log((G+1)/255.0))/log255);
			double Blog = -((255.0*log((B+1)/255.0))/log255);

			for (j=0; j<3; j++){
				/* rescale to match original paper values */
				double Rscaled = Rlog * q[j*3];
				double Gscaled = Glog * q[j*3+1];
				double Bscaled = Blog * q[j*3+2];

				double output = exp(-((Rscaled + Gscaled + Bscaled) - 255.0) * log255 / 255.0);				
				if(output>255) output=255;

				/* to_16bit_range */
				output = output / 255.0 * (max-min) + min;
				if(output>65535) output=65535;
			
				if (j==0) {
					img_stain1[i] = (u_int16_t)(floor(output+.5));
				} else if (j==1) {
					img_stain2[i] = (u_int16_t)(floor(output+.5));
				} else {
					img_stain3[i] = (u_int16_t)(floor(output+.5));
				}
			}
		}
	}
}

double to_8bit_range (u_int16_t X16, u_int16_t min, u_int16_t max)
{
	if (X16 <= min)
		return 0;
	else if (X16 >= max)
		return 255.0;
	else
		return ((double) X16 - min) / (max - min) * 255.0;
}