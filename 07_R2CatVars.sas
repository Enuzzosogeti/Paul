/***********************************************************************************************************************************************/
/*                                                             R2CATVARS                                                                       */
/* Objectives :																																   */
/*																																			   */
/* Replace the values corresponding to not specify values (mostly "9" "99" "Z") (according to the ones fullfill in the dataset "not_specified" */
/* for some variables by the modality "NA" in the data set "temp6" which is the full dataset for the country on which we are working one       */
/* 																																			   */
/* Data that we used for the program:																										   */
/*																																			   */
/* Temp 6 (created in the program "Data Split By Country")																					   */										
/*																																			   */
/* Macro used in the program:																												   */
/*																																			   */
/* %R2CatVars (Description in the program "Macros")																							   */
/*																																			   */
/* Output: &Country._R2CatVars (The country on which we are working one where we replace the "not specified" modalities by "NA" 			   */
/*         not_specified (the excel file 2Not_Specified" that we imported)   																   */
/***********************************************************************************************************************************************/

/******************************************/
/* Import of the csv file "no specified " */
/******************************************/
DATA not_specified;
    LENGTH
        Variable         $ 6
        'Not specified code'n $ 2 ;
    FORMAT
        Variable         $CHAR6.
        'Not specified code'n $CHAR2. ;
    INFORMAT
        Variable         $CHAR6.
        'Not specified code'n $CHAR2. ;
    INFILE &path_notspecified.
        DLM=';'
        MISSOVER
        DSD firstobs=2;
    INPUT
        Variable         : $CHAR6.
        'Not specified code'n : $CHAR2. ;
RUN;

/**************************************************************************/
/* Replace the no specified values of some variables by the modality "NA" */
/**************************************************************************/
%R2CatVars (Country = &Country_imported.);



