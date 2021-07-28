/********************************************************************************************************************************/
/*                                                 RI_levelcodes\\R1_data_check.r                                               */
/********************************************************************************************************************************/

/***********************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/* Objectives :																																																																																   */
/*																																																																																			   */
/* 1) Have a content of the RecordLayout text file (with the dataset "RecordLayout_Content") 																																																												   */
/*																																																																																			   */
/* 2) Load the list of country (with the dataset "CountryList")																																																																				   */
/*																																																																																			   */
/* 3) Check the number of negative values for the variables that are considered numeric and integer in the dataset "RecordLayout" for the files "HH" and "HM"																																												   */
/* (we can check it in the datasets "NegVal_HH_4" (for the file HH) and "NegVal_HM_4" (for the file HM)) (those are the data which will be exported if there are negative values																																							   */
/* We will have an export named "HH_NumberofNegativeValuebyNumVariablesAllCountries.txt" (for the file HH) and "HM_NumberofNegativeValuebyNumVariablesAllCountries.txt"																																										   */
/* (for the file HM) if there are negative values in those files																																																																			   */
/*																																																																																			   */
/* 4) Check the number of missing values for the variables that are considered numeric and integer in the dataset "RecordLayout" for the files "HH" and "HM"																																												   */
/* (we can check it in the datasets "MissVal_HH_2" (for the file HH) and "MissVal_HM_2" (for the file HM)) (those are the data which will be exported if there are missing values																																							   */
/* We will have an export named "HH_NumberofMissingValuesByNumVariablesAllCountries.txt" (for the file HH) and "HM_NumberofMissingValuesByNumVariablesAllCountries.txt"																																										   */
/* (for the file HM) if there are missing values in those files																																																																				   */
/*																																																																																			   */
/* 5) Check the number of missing values for the variables that are considered character in the dataset "RecordLayout" for the files "HH" and "HM"																																															   */
/* (we can check it in the datasets "MissVal_Dis_HH_2" (for the file HH) and "MissVal_Dis_HM_2" (for the file HM)) (those are the data which will be exported if there are missing values																																					   */
/* We will have an export named "HH_NumberofMissingValuesByDiscreteVariablesAllCountries.txt" (for the file HH) and "HM_NumberofMissingValuesByDiscreteVariablesAllCountries.txt"																																							   */
/* (for the file HM) if there are missing values in those files																																																																				   */
/*																																																																																			   */
/* Data that we used for the program:																																																																										   */
/*																																																																																			   */
/* RecordLayout (created in the program "Imports")																																																																							   */
/* CountryList (that is the txt file created in the program "Data Split By Country" which is exported)																																																										   */
/* HH_&Country. (created in the program "Imports")																																																																							   */
/* HM_&Country. (created in the program "Imports")																																																																							   */
/*																																																																																			   */
/* Macros used in the program:																																																																												   */
/*																																																																																			   */
/* %Negative_Missing_Numvar (Description in the program "Macros")																																																																			   */
/* %Missing_Disvar (Description in the program "Macros")																																																																					   */
/*																																																																																			   */
/* Outputs:																																																																																	   */
/*																																																																																			   */
/* RecordLayout_Content (the content of the original dataset "RecordLayout")																																																																   */
/* CountryList (the list of the country...normally one)																																																																						   */
/* NegVal_HH_4 (number of negative values for each numeric variables concerned in the dataset "HH"...from that output we will export "HH_NumberofNegativeValuebyNumVariablesAllCountries.txt" ...if there are negative values, if there is only the variable "Country" in the dataset "NegVal_HH_4" there are no negative values) 			   */
/* NegVal_HM_4 (number of negative values for each numeric variables concerned in the dataset "HM"...from that output we will export "HM_NumberofNegativeValuebyNumVariablesAllCountries.txt" ...if there are negative values, if there is only the variable "Country" in the dataset "NegVal_HM_4" there are no negative values)			   */
/* MissVal_HH_2 (number of missing values for each numeric variables concerned in the dataset "HH"...from that output we will export "HH_NumberofMissingValuesByNumVariablesAllCountries.txt"... if there are missing values, if there is only the variable "Country" in the dataset "MissVal_HH_2" there are no missing values)			   */
/* MissVal_HM_2 (number of missing values for each numeric variables concerned in the dataset "HM"...from that output we will export "HM_NumberofMissingValuesByNumVariablesAllCountries.txt"... if there are missing values, if there is only the variable "Country" in the dataset "MissVal_HM_2" there are no missing values)			   */
/* MissVal_Dis_HH_2 (number of missing values for each character variables concerned in the dataset "HH"...from that output we will export "HH_NumberofMissingValuesByDiscreteVariablesAllCountries.txt"...if there are missing values, if there is only the variable "Country" in the dataset "MissVal_Dis_HH_2" there are no missing values) */
/* MissVal_Dis_HM_2 (number of missing values for each character variables concerned in the dataset "HM"...from that output we will export "HM_NumberofMissingValuesByDiscreteVariablesAllCountries.txt"...if there are missing values, if there is only the variable "Country" in the dataset "MissVal_Dis_HM_2" there are no missing values) */
/***********************************************************************************************************************************************************************************************************************************************************************************************************************************************/

/******************************************************/
/* 1) Load of the record Layout and show the contents */
/******************************************************/

/*****************************************************************************************************************************************/
/* That step has already been done in the program "Imports" , this is the R Code :                                                       */
/*                                                                                                                                       */
/* #load the record layout                                                                                                               */
/*Layout=read.table("Input\\RecordLayout.txt",header=TRUE,sep="\t",colClasses="character",na.strings="")                                 */
/*str(Layout)                                                                                                                            */
/*                                                                                                                                       */
/* It says that all colums have to be considered as character and that one empty cell should be considered as a "NA"                     */
/*                                                                                                                                       */
/* We do not know why we sould put all the variables in characters, we have two variables when we were doing this code which are numeric */
/*                                                                                                                                       */
/* in the SAS table "RecordLayout" we have two variables that are numeric "Digit" and "Dec"                                              */
/*****************************************************************************************************************************************/

proc contents data=RecordLayout 
              out=RecordLayout_Content noprint; /* With the SAS dataset "RecordLayout_Content" we can see the content of the original dataset "RecordLayout" */

run; 



/**********************************/
/* 2) Load of the list of Country */
/**********************************/

/****************************************************************************************************************/
/* The corresponding R Codes: 																					*/
/*																												*/
/* #load the list of countries											  										*/
/* CountryList=read.table("DataSplitByCountry\\CountryList.txt",header=F,sep=",",stringsAsFactor=F) 			*/
/*																												*/
/* explication of "stringsAsFactor=F"																			*/
/*																												*/
/* R, by default , converts (character) strings to factor when creating data frames directly with data.frame () */ 
/* or as the result of using read.table () variants to read in tabular data										*/
/****************************************************************************************************************/
proc import datafile= "&path_out./DataSplitByCountry/CountryList.txt"
            out = CountryList
			dbms=dlm replace;
			delimiter= ',';
			getnames= yes; /* header = F in the R code so normally getnames = no in the SAS code but as it is a SAS table */ 
			              /* if we do not put getnames=yes we will have a variable named "VAR1" with two different modalities : */
			              /* the name of the variable in the txt file "Country" and the two-digits of the country (ex: EE) */
			              /* so we will put getnames = yes */
run;



/*************************************************************************************************************************************************************************************/
/* 3) Check the number of negative values for the variables that are considered numeric or integer in the text file "RecordLayout" and which are present for the files "HH" and "HM" */
/*    Check the number of missing values for the variables that are considered numeric or integer in the text file "RecordLayout" and which are present for the files "HH" and "HM"  */                        
/*************************************************************************************************************************************************************************************/
%Negative_Missing_Numvar (data = HH , Country = &Country_imported.);
%Negative_Missing_Numvar (data = HM , Country = &Country_imported.);


/***************************************************************************************************************************************************************************/
/* 4) Check the number of missing values for the variables that are considered character in the text file "RecordLayout" and which are present for the files "HH" and "HM" */
/***************************************************************************************************************************************************************************/ 
%Missing_Disvar (data=HH, Country = &Country_imported.);
%Missing_Disvar (data=HM, Country = &Country_imported.);















 
