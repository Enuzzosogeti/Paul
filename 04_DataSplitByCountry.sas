/*********************************************************************************************************************************/
/*                                             RI_levelcodes\\R0_SplitDataByCountry.r                                            */
/*********************************************************************************************************************************/

/**********************************************************************************************************************************************/
/* Objectives :                                                                                                                   			  */
/*                                                                                                                                			  */
/* 1) Recalculate the variable "HA10" if the variable "flag_weight" that we create in the program (in the part 5) is equal to "y" 			  */
/*                                                                                                                                			  */
/* 2) Have a text file for every country (ex:EE.txt)                                                                              			  */
/*                                                                                                                                			  */
/* 3) Know the variables present for each country in each dataset (ex: EE_Vars_HH  EE_Vars_HM) (both will be export in txt files) 			  */
/*																																			  */
/*																																			  */
/* Data that we use for the program:																										  */
/*																																			  */
/* HH_&Country_imported. (the HH dataset corresponding to a given country) (created in the program "Imports")								  */
/* HM_&Country_imported. (The HM dataset corresponding to a given country) (created in the program "Imports")    						      */
/*                                                                                                                                            */
/* Macros used in the program :																												  */
/*																																			  */
/* %Content_Sort_HH_HM (Description in the program "Macros")  																		          */
/* %Export_vars_HH_HM  (Description in the program "Macros")																				  */
/*                             																												  */
/* Outputs of the program:                                                                                                                    */
/*                                                                                                                                            */
/* HH_Country (SAS dataset which give us the different countries (and normally only one) which are in the SAS dataset "HH_&Country_imported." */ 
/* HH_Year (SAS dataset which give us the different years (and normally only one) which are in the SAS dataset "HH_&Country_imported."        */
/* HH_&Country_imported._vars (SAS dataset which give us the different variables which are in the SAS dataset "HH_&Country_imported."         */
/* HM_&Country_imported._vars (SAS dataset which give us the different variables which are in the SAS dataset "HM_&Country_imported."         */
/* Temp6 (SAS dataset which represent the whole country given)                                                                                */
/**********************************************************************************************************************************************/



/**********************************************************************************************/
/* 1)Display the distinct Countries and distinct years in the "HH_&Country_imported." dataset */
/**********************************************************************************************/
proc sql noprint;

create table HH_Country /* create a sas dataset named "HH_Country" */ 
as select distinct Country /* where you display the different modalities of the variable "Country" */
from HH_&Country_imported.; /* from the dataset "HH_&Country_imported." */


create table HH_Year  /* create a sas dataset named "HH_Year" */ 
as select distinct YEAR /* where you display the different modalities of the variable "YEAR"*/
from HH_&Country_imported.; /* from the dataset "HH_&Country_imported." */
quit;


/*******************************************************************************************************************************************************/
/* 2) Creation of the text file name CountryList where you have the different Countries (normally only one) inside the dataset "HH_Country" but before */ 
/* you have to create a folder named "DataSplitByCountry" in the "&path_out." path                                                                     */
/*******************************************************************************************************************************************************/
proc export data=HH_Country /* do the export of the dataset "HH_Country" */
            outfile="&path_out.&slash.DataSplitByCountry/CountryList.txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
			dbms = tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */
			delimiter = ","; /* the separator will be ";"*/
			putnames = yes; /* We will put "yes" for the putnames option because it will be useful in the program "Datacheck" where we will need to import the CountryList txt */
			run;           /* because otherwise when we will import it we will have a variable named "Var1" */

/*****************************************************************************************************************************************************/
/* 3) We get the different variables of each files HH and HM of the given country 																     */
/* 3bis) We make a sort on the two datasets before the merge of the two datasets which contain the different variables of the datasets "HH" and "HM" */
/*****************************************************************************************************************************************************/
%Content_Sort_HH_HM (data= HH , Country = &Country_imported. , LastVar = HA04);
%Content_Sort_HH_HM (data= HM , Country = &Country_imported. , LastVar = MA04);


/*****************************************************************************************************/
/* 4) We will do a Merge between HH_&Country_imported. and HM_&Country_imported. by "Country" "Year" */
/* and "HA04" (in "HH_&Country_imported." dataset), "MA04" (in "HM_&Country_imported." dataset))     */
/* that merge will appear in a dataset named "temp"                                                  */
/*****************************************************************************************************/

data temp; /* Here we are doing the merge */
length COUNTRY $4.; /* we are precising the length of the variable "COUNTRY" because otherwise we will have a WARNING in the Log */
merge HH_&Country_imported._1 HM_&Country_imported._1 (rename=(MA04 = HA04)); /* in order to do the merge "HA04" and "MA04" need to have the sane name so I rename "MA04" by "HA04" in the SAS dataset "HM_&Country_imported._1" */
by Country Year HA04; /* by those key variables */
run;


/*************************************************************************************************************************************************/
/* 5) We create the new variable "individual weight" (we will use the old name "HA10" for this newly created variable)                           */
/* by dividing the household weight (HA10) by the number of individuals in the household (HB05) if the parameter flag_weight is not equal to "y" */
/*************************************************************************************************************************************************/

/**********************************************************/
/* 1st step : Construction of the parameter "flag_weight" */
/**********************************************************/

/* Let the parameter "flag_weight" = "y" if the household member weights (the number of a same modality of the variable "HA04"( HA04 represents the identification number of */
/* the household) (ex: for the country "EE" the modality "402031520021" of the variable HA04 is written four times) are equal to the household weights (variable HB05 which */
/* represents the household size (the sum of household members) */

proc freq data=temp order=data noprint; /* proc freq allows the construction of simple cross tables, here from the SAS dataset "temp"........"order" specifies the order in which the modalities of the different variables must appear...here what is displayed in the dataset */
tables COUNTRY * HA04 * hb05/*construction of a simple cross table between the variables "COUNTRY" "HA04" and "hb05" *//out=temp1 (drop=percent); /* the output of that simple cross table will be in a dataset named "temp1" where I dropped the variable "Percent" */
run;

data temp2; /* creation of the dataset "temp2" */
set temp1; /* from the dataset "temp1" */
if HB05 = COUNT then flag_weight = "y";          /* here we have built the parameter "flag_weight", if HB05 = COUNT then flag_weight = "y" otherwise it equals to "n"  */
if HB05 ne COUNT then flag_weight = "n";
run;


/********************************************************************************************************************************************/
/* 2nd step : We will do a merge between the table "temp2" which contains the parameter "flag_weight" and the eventual flag_weight = "n"    */
/* and the SAS table "temp" which is the result of the merge between HH_&Country_imported. and HM_&Country_imported. The key variables will */
/* be "COUNTRY" "HA04" and "HB05"; we will drop the variable "COUNT" from the SAS table "temp2", but before the merge we will do            */
/* a proc sort                                                                                                                              */
/********************************************************************************************************************************************/
proc sort data= temp out=temp3; by COUNTRY HA04; run; /* We are doing a sort for the sas table "temp" with the following key variables "COUNTRY" and "HA04", the output of that sort will be located in a dataset named "temp3" */

proc sort data= temp2 out=temp4; by COUNTRY HA04; run; /* We are doing a sort for the sas table "temp2" with the following key variables "COUNTRY" and "HA04", the output of that sort will be located in a dataset named "temp4" */

data temp5; /* creation of a dataset "temp5" */
merge temp3 temp4 (drop= COUNT); /* that will be the merge between the datasets "temp3" and "temp4"...in the dataset "temp4" we delete the variable "COUNT" which will not appear in the dataset "temp5" */
by COUNTRY HA04 ; /* The key variables "COUNTRY" and "HA04" are used for this merge*/
run;

data temp6 (drop= flag_weight); /* Creation of the dataset "temp6" where we do not keep the variable "flag_weight" */
set temp5; /* from the dataset "temp5" */
if flag_weight = "n" then HA10 = HA10/HB05; /* if the modality of the variable "flag_weight" is equal to "n" do the following operation "HA10 = HA10/HB05" */
run;


/*******************************/
/* 5) We are doing the exports */
/*******************************/

/********************************************************************************************/
/* 1st step : the export of the whole given country with all the variables into a text file */
/********************************************************************************************/
proc export data=temp6 /* do the export of the dataset "temp6" */

            outfile = "&path_out./DataSplitByCountry/&Country_imported..txt" /* put the export at that location where you define the name of the output and its format (.txt here) */

			dbms = tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */

			delimiter = ","; /* the separator will be ","*/

			putnames = yes; /* we want the name of the variables to appear in the final output */
run;


/***************************************************************************************/
/* 2nd step : We export the different variables of HH and HM files for a given country */
/***************************************************************************************/
%Export_vars_HH_HM (data=HH, Country= &Country_imported.);
%Export_vars_HH_HM (data=HM, Country= &Country_imported.);



/***********************************/
/* 4th step : Cleaning of the work */
/***********************************/
proc datasets lib=work nolist;
delete HH_&Country_imported._1 HM_&Country_imported._1 temp temp1-temp5;
run;