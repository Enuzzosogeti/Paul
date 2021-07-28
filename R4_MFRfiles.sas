/**************************************************************************************************************************************************************************************************************************************************************************************/
/* Objectives :																																																																		  */
/* 1) Create a sub-table of hh where you keep only the variables where the name contains the caracter chain "EUR_HE" 																																								  */
/* 2) Creation of multiple variables when it is possible : &NUTS1. , &AGE._Recoded_5Classes , &AGE._Recoded_5YearsClasses, &COB._Recoded_3Categ, &COC._Recoded_3Categ, &COR._Recoded_3Categ,&MSTAT._Recoded_3Categ, &ISCO08._Recoded,HA04rand 										  */
/* 3) Export The files HH and HM for every country after the creation of the different variables 																																													  */
/* 																																																																					  */ 
/* Data we use for the program:																																																														  */
/* HM_&Country.																																																																		  */
/* HH_&Country. 																																																																	  */
/* &Country._spont_t1000_s1_hh_at_risk (text file)																																																									  */
/* EU2015_ISOalpha2 (text file)																																																														  */
/*																																																																					  */
/* Macros used in the program : 																																																													  */
/* %Before_Step1_R4 (description in the program "Macros")																																																							  */
/* %R4_Step1 (description in the program "Macros")																																																									  */
/* %R4_Step2 (description in the program "Macros")																																																									  */
/* %R4_Step3 (description in the program "Macros")																																																									  */
/* 																																																																					  */
/* Outputs: 																																																																	      */
/* &Country._HH_EUR_HE (dataset where we only keep the variables which start by "EUR_HE" for a country given)																																										  */
/* &Country._test100 (For a country given it shows the different variables which start by "EUR_HE") 																																												  */
/* test144_HH_&Country. (for a country given it shows the dataset HH after the creation of the variables : &NUTS1. , &AGE._Recoded_5Classes , &AGE._Recoded_5YearsClasses, &COB._Recoded_3Categ, &COC._Recoded_3Categ, &COR._Recoded_3Categ,&MSTAT._Recoded_3Categ, &ISCO08._Recoded) */
/* test117_HM_&Country. (for a country given it shows the dataset HH after the creation of the variables : &NUTS1. , &AGE._Recoded_5Classes , &AGE._Recoded_5YearsClasses, &COB._Recoded_3Categ, &COC._Recoded_3Categ, &COR._Recoded_3Categ,&MSTAT._Recoded_3Categ, &ISCO08._Recoded) */
/* &Country._MFR_HH_v2 (for a country given it shows the dataset HH which will be exported) 																																														  */
/* &Country._MFR_HM_v3 (for a country given it shows the dataset HM which will be exported) 																																														  */																																														  
/**************************************************************************************************************************************************************************************************************************************************************************************/

%Before_Step1_R4 (data=HH,Country=&Country_imported.);

%R4_Step1 (Country = &Country_imported. , data = HH);

%R4_Step2 (Country = &Country_imported. , data = HM , HIDHM = MA04);
%R4_Step2 (Country = &Country_imported. , data = HM , HIDHM = MA04);
%R4_step3 (Country = &Country_imported.,data1 = HH,data2 = HM);