/********************************************************************************************************************************/
/*                                                 RII_levelcodes\\CheckExecution.r                                             */
/********************************************************************************************************************************/

/*************************************************************************************************************************************************************************************************************************************/
/* Objectives :																																																						 */
/*																																																									 */
/* 1) To Know the eventual unexpected variables for the Country that we imported (the ones which are not found in the txt file "RecordLayout")																						 */
/* 2) To know the variables which are present in the dataset "RecordLayout" but which are missing in the Country Imported																											 */
/* 3) To know the the eventual unexpected Modalities of the variables in the Country imported taking into account RecordLayout																										 */
/* 4) To Calculate the statistics for the continous variables in the Country imported taking into account RecordLayout																												 */
/* 5) To calculate the statistics for the discrete variables in the Country imported taking into account RecordLayout																												 */
/*																																																									 */
/* Data that we used for the program :																																																 */
/*																																																									 */
/* HH_&Country._VARS (the SAS dataset which give us the different variables which are in the SAS dataset "HH_&Country_imported.") (created in the program "Data Split By Country")													 */
/* HM_&Country._VARS (the SAS dataset which give us the different variables which are in the SAS dataset "HM_&Country_imported.") (created in the program "Data Split By Country")													 */
/* HH_&Country. (created in the program "Imports")																																													 */
/* HM_&Country. (created in the program "Imports")																																													 */
/* RecordLayout (created in the program "Imports")																																													 */
/*																																																									 */
/* Macros used in the program :																																																		 */
/*																																																									 */
/* %Unexpected_Variables (Description in the program "Macros")																																										 */
/* %Absent_Variables (Description in the program "Macros")																																											 */
/* %Unexpected_Modalities (Description in the program "Macros")																																										 */
/* %Cont_Var_Summaries (Description in the program "Macros")																																										 */
/* %Dis_Var_Summaries (Description in the program "Macros")																																											 */
/*																																																									 */
/* Outputs of the program :																																																			 */
/*																																																									 */
/* &Country._unexpected_variables (the content of the eventual unexpected variables for the Country Imported, if the column "Unexpected_Variables" is blank there are no unexpected variables 										 */
/* &Country._Absent_Variables_2 (the content of the eventual variables which are present in the dataset "RecordLayout" but absent for the Country Imported, if the column "Absent_Variables" is blank there are no absent variables) */
/* &data._&Country._Cont_Var_Summaries (the statistics for the continous variables in the files "HH" and "HM" for the Country imported)	  																						     */
/* &data._&Country._discrete_var_summaries (the statistics for the discrete variables in the files "HH" and "HM" for the Country imported)																							 */
/*************************************************************************************************************************************************************************************************************************************/


/***************************************************************************************************************************************/
/* 1) The eventual unexpected variables for the Country that we imported (the ones which are not found in the txt file "RecordLayout") */
/***************************************************************************************************************************************/
%Unexpected_Variables (Country = &Country_imported. , data1 = HH , data2 = HM);

/************************************************************************************************************************/
/* 2) Check the variables which are present in the dataset "RecordLayout" but which are missing in the Country Imported */
/************************************************************************************************************************/
%Absent_Variables (data1 = HH, data2 = HM , Country = &Country_imported.);

/*************************************************************************************************************************/
/* 3) Check the eventual unexpected Modalities of the variables in the Country imported taking into account RecordLayout */
/*************************************************************************************************************************/
%Unexpected_Modalities (data=HH,Country=&Country_imported.);
%Unexpected_Modalities (data=HM,Country=&Country_imported.);

/********************************************************************************************************************/
/* 4) Calculate the statistics for the continous variables in the Country imported taking into account RecordLayout */
/********************************************************************************************************************/
%Cont_Var_Summaries (data = HH , Country = &Country_imported.);
%Cont_Var_Summaries (data = HM , Country = &Country_imported.);

/********************************************************************************************************************/
/* 5) Calculate the statistics for the discrete variables in the Country imported taking into account RecordLayout */
/********************************************************************************************************************/
%Dis_Var_Summaries (data=HH , Country = &Country_imported.);
%Dis_Var_Summaries (data=HM , Country = &Country_imported.);