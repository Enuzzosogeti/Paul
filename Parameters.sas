/********************************************************************************************************************************************************************/
/*                                                          Parameters                                                                                              */
/*                                                                                                                                                                  */                                                                
/* Here we define the parameters that will be used in the project, we defined a bloc of parameters where we precise the use of each of those, those parameters can  */
/* be modified later by the user in order to increase the speed of programs execution                                                                               */                                                                                             
/********************************************************************************************************************************************************************/
/*MODIFICATIONS:*/
/*
20210305: replace single quotes by double quotes in path_out so that the macro variable can resolve.
*/
/*********************/
/* Global parameters */
/*********************/

%macro slash; /*emanuele: this macro is doubled but I guess is good by now to keep like that */
%global slash;
%*** If the program is run on Windows;
%if (&sysscp = WIN) %then %do;
%let slash = %str(\);
%end;
%*** If the program is run on UNIX;
%else %do;
%let slash = %str(/);
%end;
%mend;
%slash;


options mprint;
%LET anon_root = C:\Users\emanuele.nuzzo\Desktop\Paul\Progetto\Task_7\Last version\Enviroment_test_2021_august;

libname donnees "&anon_root.\1_EE"; /* location of the HH and HM SAS databases for the corresponding Country */

libname inputRL "&anon_root.\nicolas\input"; /* location of the RecordLayout SAS dataset that I created  to avoid import issue from the RecordLayout text file*/

%LET Country_imported = EE; /* The parameter Country_imported represent the country that we want to import the HH and HM files as the project will be runned country by country */

%LET path_input = &anon_root.\Input; /* path for the location of the folder "input" */


/**********************************************************************************/
/*                            DataSplit by Country                                */
/**********************************************************************************/
%LET path_out = &anon_root./Output_t7; /* Here you have to define where the output of the program "DataSplitbyCountry" will be located without precising the folder "DataSplitByCountry" that you created before launching this program */



/*******************************************/
/* DataChecks + Check Execution + Recodings */
/*******************************************/
%LET path_DC_CE_REC = &path_out./DataChecks;

/* With the macro-parameter "path_DC_CE_REC" we define the path for the export of several results: */
/*
/* - the number of negative values for the numerical variables for the Country "&Country_imported." */
/* - the number of missing values for the numerical variables for the Country "&Country_imported." */
/* - the number of missing values for the discrete variables for the Country "&Country_imported." */
/* - the export of the txt file for the unexpected Variables for the Country imported which are not found in the file "RecordLayout" */
/* - the export of the txt file for the absent variables which are in the dataset "RecordLayout" but not in the variables for the country "&Country_imported." */
/* - the export of the txt file for the eventual unexpected modalities for the variables for the country exported compared to those referred in the dataset "RecordLayout" */
/* - the export for the statistics of the continuous variables */
/* - the export for the statistics of the discrete variables */
/* - The path for the export of &Country_AfterRecodings */


/*********************************************************************************/
/*                             R2CatVars                                         */
/*********************************************************************************/
%LET path_notspecified = "&path_input./not_specified.csv"; /* the path to access to the csv file "not specified" */

/*********************************************************************************/
/*                                Recodings                                      */
/*********************************************************************************/
%LET AGE = MB03; /* define the parameter age */

%LET MSTAT = MB04; /* define the parameter MSTAT */

%LET NUTS2 = HA08; /* define the parameter NUTS2 */

%LET ISCO88 = ME0988; /* define the parameter ISCO88 */

%LET ISCO08 = ME0908; /* define the parameter ISCO08 */


/*********************************************************************************/
/*                           Scenarios                                           */
/*********************************************************************************/
%LET path_scenarios_ST = &path_out./OutputCategoricalRuns; /* Here you define the output for the scenario A,B and C + the summary table */



/******************************************************************************/
/*                               ContVars                                     */
/******************************************************************************/
%LET DEGURB = HA09;
%LET SEX = MB02;
%LET Exp_zeros = y;
%LET Inc_Zeros = y;
%LET side = both;
%LET Ininc = EUR_MF099;
%LET candidates = &ISCO88. &ISCO08. ME12 ME13;
%LET k1 = 3;
%LET size = 2500 1000;
%LET H1Inc = EUR_HH095;
%LET H2Inc = EUR_HH099;
%LET spont_scen = EUR_HE00 EUR_HJ00 EUR_HE01 EUR_HE02 EUR_HE03 EUR_HE04 EUR_HE05 EUR_HE06 EUR_HE07 
EUR_HE08 EUR_HE09 EUR_HE10 EUR_HE11 EUR_HE12 EUR_HE071 EUR_HE0711 EUR_HE123 EUR_HE1231 EUR_HE12311 
EUR_HE1253 EUR_HE12531 &H1Inc. &H2Inc.;
%LET HMID = MB05;
%LET HID = HA04;
%LET NHM = HB05;
%LET Weight_CV = HA10;
%LET key_CV = Intercept NUTS1;

/* path to folder contvarsoutput where &Country_imported._spont_t1000_s1_hh_at_risk.txt is; */ 
%LET path_contvarsoutput  = /ec/prod/0hbs/hbs/5_Anonymisation/HBS2015ANON/ContVarsOutput;
%LET path_contvarsoutput2 = /ec/prod/0hbs/hbs/5_Anonymisation/HBS2015ANON/ContVarsOutput/Export;



/******************************************************************************/
/*                             R4_MFRfiles                                    */
/******************************************************************************/
%LET path_iso = "&path_input./EU2015_ISOalpha2.txt"; /* path to access to the text file EU2015_ISOalpha2 */

%LET COB = MB01; /* Country of birth */

%LET Country_isoalpha2 = "AT" "BE" "BG" "CY" "DK" "EE" "FI" "FR" "DE" "EL" "IE" "IT" "LT" "LU" "MT" "NO" "NL" "PL" "CZ" "RO" "SK" "SI" "ES" "SE" "HU"; /* list of country in the text file isoalpha2, if necessary update that list */

%LET COC = MB011; /* Country of Citizenship of household member */

%LET COR = MB012; /* Country of residence of the household member */

%LET path_MFR4 = &path_out./MFR; /* path for the export for the "R4_MFRfiles" program */


