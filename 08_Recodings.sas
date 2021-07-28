/****************************************************************************************************************/
/*                                Recodings                                                						*/
/* Objectives:																			   						*/
/* Recode for annual age, marital status												   						*/
/* Definition of NUTS1																	   						*/
/* selection of the occupation variable													   						*/
/* 																						   						*/
/* Data that we used for the program:													   						*/
/* &Country._R2CatVars (created in the program "R2CatVars")								  						*/
/*																						   						*/
/* Macros used in the program : 														   						*/
/* %Recodings (description in the program "Macros")										   						*/
/* %idc (description in the program "Macros")											   						*/
/*																						   						*/
/* Outputs :																			   						*/
/* &Country._Bottom (display the individuals who have an age <=14 years for a country given)					*/
/* &Country._Top (display the individuals who have an age >=85 years for a country given)						*/
/* &Country._Frequencies_age1 (represent the frequencies for the variable "age1" for a country given) 	 	    */
/* &Country._Frequencies_age_adhoc (represent the frequencies for the variable "age_adhoc" for a country given) */
/* &Country._Frequencies_age5 (represent the frequencies for the variable "age5" for a country given)	   	    */
/* &Country._Frequencies_age10 (represent the frequencies for the variable "age10" for a country given)			*/
/* &Country._Age5_lastrows (represent the last rows for the variable "Age5" for a country given)				*/
/* &Country._Age10_lastrows (represent the last rows for the variable "age10" for a country given)				*/
/* &Country._Frequencies_&MSTAT._34(represent the frequencies for the marital status for a country given)       */
/* &Country._AfterRecodings (the final dataset after the application of all the recodings for a country given)  */
/****************************************************************************************************************/


/***************************************************************/
/* Recode for annual age, marital status , definition of NUTS1 */ 
/***************************************************************/
%Recodings (Country = &Country_imported.);


/****************************************************/
/* Displaying of the occupation variable in the Log */
/****************************************************/
%idc (Country = &Country_imported.);



