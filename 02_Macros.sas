/*******************************************************************************************************************************************************************/
/*                                                                         Macros                          														   */
/*******************************************************************************************************************************************************************/

/***********************************************************************************/
/* Here we define the different macros that will be used in the different programs */
/***********************************************************************************/


/*********************************/
/* Data Split By Country program */
/*********************************/

/***********************************************************************************************************************************************/
/* The objectives of the macro "Content_Sort_HH_HM" are to :																				   */
/*																																			   */
/* 1) Get the different variables of each files HH and HM of the given country 																   */
/*																																			   */
/* 2) make a sort on the two datasets before the merge of the two datasets which contain the different variables of the datasets "HH" and "HM" */
/***********************************************************************************************************************************************/
%Macro Content_Sort_HH_HM (data,Country,LastVar);

proc contents data= &data._&Country.
              out = &data._&Country._vars noprint; /* Give me the content of the dataset "&data._&Country." into a dataset named "&data._&Country._vars" */
run;

proc sort data=&data._&Country. out=&data._&Country._1; /* We make a sort on the dataset before the merge */
by Country Year &LastVar.; /* We create the macro parameter "&LstVar." because for the two datasets that variable is not named the same way */
run;

%MEND Content_Sort_HH_HM;



/************************************************************************************************************************************************************/
/* The objective of the macro "Export_vars_HH_HM" will be to export in a txt file the different variables of the datasets "HH" and "HM" for a given country */
/************************************************************************************************************************************************************/
%Macro Export_vars_HH_HM (data,Country);

proc export data= &data._&Country._vars (keep= NAME) /* Do the export of the dataset "&data._&Country._vars" where we keep the variable "NAME" */
            outfile= "&path_out.&slash.DataSplitByCountry&slash.&Country._vars_&data..txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
			dbms = tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */

			delimiter = "," ; /* the separator will be ","*/

			putnames = no; /* we do not want the name of the variables to appear in the final outputs */
run;

%MEND Export_vars_HH_HM;





/*********************/
/* Datacheck program */
/*********************/

/******************************************************************************************************************************************************************************************/
/* The objectives of the macro "Negative_Missing_Numvar" are to :																														  */
/*           																																											  */
/* 1) Check the number of negative values for the variables that are considered numeric or integer in the text file "RecordLayout" and which are present for the files                    */
/* "HH" and "HM" and to export those results in a text file...if there are some negative values, for the export (txt file) we will have for variables "Country"                           */
/* (corresponding to the country concerned) and the different variables where there are negative values with the number of times there are negative values for the corresponding variable */
/* the datasets used for export (once again if there are negative values) are "NegVal_HH_4" (for the file "HH") and "NegVal_HM_4" (for the file "HM")                                     */
/*																																														  */
/* 2) Check the number of missing values for the variables that are considered numeric or integer in the text file "RecordLayout" and which are present for the files 					  */
/* "HH" and "HM" and to export those results in a text file...if there are some missing values, for the export (txt file) we will have for variables "Country" (corresponding to the      */
/* the country concerned) and the different variables where there are missing values with the number of times there are missing values for the corresponding variable 					  */
/*  the datasets used for the export (once again if there are missing values) are "MissVal_HH_2" (for the file "HH") and "MissVal_HM_2" (for the file "HM")								  */
/******************************************************************************************************************************************************************************************/
%Macro Negative_Missing_Numvar (data,Country); /* it will have two parameters for this macro named "Negative_Missing_Numvar" "&data." and "&Country." */

proc contents data=&data._&Country.
              out=Miss_Num_Content_&data._&Country.    /* Here we want to display the content of the data "HH" and "HM" for the country that we have chosen to run the codes */
			  noprint;                                 /* and named it "Miss_Num_Content_&data._&Country." (&data. is corresponding to HH or HM and &Country. for the Country*/ 
run;                                                   /* that we have chosen */

 proc sort data= Miss_Num_Content_&data._&Country.;
 by name;                                                  /* We sort the table "Miss_Num_Content_&data._&Country." by "name" that column corresponds to the different */
 run;                                                      /* variables found in the dataset "&data._&Country." */

proc sql noprint;
create table Numlistvar as           /* create a SAS dataset named "Numlistvar" */
select distinct Variable as name     /* where we are going to select the different modalities of the variable "Variable" that we will name "name"*/
from RecordLayout                    /* from the SAS dataset "RecordLayout" */
where type in ('num' 'int');         /* where the modalities of the variable "type" are either equal to "num" and "int"*/
quit;

data Miss_Num_Content_&data._&Country._1; /* create a table named "Miss_Num_Content_&data._&Country._1" */
merge Miss_Num_Content_&data._&Country. (in = a) Numlistvar (in = b); /* by merging the two tables "Miss_Num_Content_&data._&Country." and "Numlistvar"*/
by name; /* by the key variable "name" */
if a and b; /* if both modalies are in the dataset table "Miss_Num_Content_&data._&Country." (corresponding to the tag "a") and the dataset "Numlistvar" (corresponding to the tag "b")*/
run;

proc sql noprint;

  select distinct name into:Num_Varnamn_&data. separated by ' - ' from Miss_Num_Content_&data._&Country._1 where type eq 1; /* select the different modalities of the variable "name" that you will separate by ' - ' from the sas dataset "Miss_Num_Content_&data._&Country._1" where the variable "type" is equal to 1 and contain that in a macro-parameter named "Num_Varnamn_&data."  */

  select count (distinct name) into:Num_Varnbn_&data. from Miss_Num_Content_&data._&Country._1 where type eq 1; /* Count the number of distinct modalities for the variable "name" where the variable "type" is equal to 1  from the dataset "Miss_Num_Content_&data._&Country._1" and contain that in a macro-parameter named "Num_Varnbn_&data." */

 quit;

  %DO i=1 %TO &&Num_Varnbn_&data.; /* create a loop that will be applicated "&&Num_Varnbn_&data." number of times */
  %LET Num_Varnnc_&data. = %Scan (&&Num_Varnamn_&data..,&i., ' - '); /* creation of a macro-variable "Num_Varnnc_&data." which will be equal to the "i"th "word" of the variable "&&Num_Varnamn_&data..", those "words" are sseparated by "-" */

  data Num_Varnnc_&data._gwn_&i.; /* create sas datasets named "Num_Varnnc_&data._gwn_&i." where &i. represents &&Num_Varnbn_&data., so if &&Num_Varnbn_&data. equals to 5 we will have five datasets Num_Varnnc_&data._gwn_1 until Num_Varnnc_&data._gwn_5 (data is still representing HH or HM) */
  set &data._&Country. (keep = COUNTRY YEAR &&Num_Varnnc_&data..); /* from the dataset "&data._&Country." where you keep only the variables "COUNTRY" "YEAR" "&&Num_Varnnc_&data.." in order to create the different "Num_Varnnc_&data._gwn_&i." */
  length varlab valuec $50.; /* defintion of the length of the variables "varlab" and "valuec" which will be 50, as we see the "$" before the "50" we already know those are character variables*/
  valuec = ""; /* creation of a variable "valuec" which will be equal to "" (so noting we will have a blank space */
  varlab = "&&Num_Varnnc_&data.."; /* creation of a variable "varlab" where the modality will be equal to "&&Num_Varnnc_&data.." */
  rename &&Num_Varnnc_&data.. = valuen; /* we rename the variable "&&Num_Varnnc_&data.." by "valuen" */
  run;

  %END; /* end of the loop %DO i=1 %TO &&Num_Varnbn_&data.*/

  data Num_Var_&data._Final; /* creation of a dataset "Num_Var_&data._Final" */
  set Num_Varnnc_&data._gwn_:; /*  which will be a set from the different datasets "Num_Varnnc_&data._gwn_:" created */
  if valuec eq '' then valuec = input(valuen,$14.); /* if the variable "valuec" equald to '' then we create a new value for that variable which will be a conversion of the variable valuen from character to numeric, "$14." represents the informat that means a format for reading the variable "valuen" */
  run;

  proc freq data= Num_Var_&data._Final noprint; /* proc freq allows the construction of simple cross tables, here from the SAS dataset "Num_Var_&data._Final" */
  table valuec*varlab /*construction of a simple cross table between the variables "valuec" and "varlab" *// out = Num_Var_&data._Finfreq (drop= Percent rename=(valuec = modality count=Frequency varlab=Variable)); /* the output of that simple cross table will be in a dataset named "Num_Var_&data._Finfreq" where I dropped the variable "Percent" from the output and where I rename the names of some variables (valuec by modality....count by frequency...varlab by variable*/
  run;

  /***************************/
  /* for the negative values */
  /***************************/
  data NegVal_&data.; /* creation of a dataset "NegVal_&data." */
  set Num_Var_&data._Finfreq; /* from the dataset "Num_Var_&data._Finfreq" */
  where Modality contains "-"; /* where the variable "Modality" contains "-" */
  run;

  proc sort data=NegVal_&data. out=NegVal_&data._1; by Variable; run; /* We sort the dataset "NegVal_&data." by the variable "Variable" and the outpout of that sort will be a dataset named "NegVal_&data._1" */

  proc freq data=NegVal_&data._1 noprint; /* construction of a simple table from the dataset "NegVal_&data._1" */
  table Variable/* for the variable "Variable" *//out=NegVal_&data._2(drop=percent); /* the output of that construction of that simple table will be named "NegVal_&data._2" */
  run;

/* in the dataset "NegVal_&data._2" we will put all the variables in lowcases anf withdraw all kinds of punctuations */

  data NegVal_&data._2 (drop= Variable rename = (Variable1 = Variable)); /* creation of a dataset "NegVal_&data._2" where I drop the variable "Variable" and after rename the variable "Variable1" by "Variable" */
  set NegVal_&data._2; /* from the dataset "NegVal_&data._2" */
  Variable1 = compress (lowcase(Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* "Variable1" will be equal to the variable "Variable" in lowcases and without any kind of punctuations */
  run;

  proc transpose data=NegVal_&data._2 out=NegVal_&data._3; id Variable; run; /* proc transpose allows the transposition of tables, here from the dataset "NegVal_&data._2", the result of that transposition will be the dataset "NegVal_&data._3" , with "id" SAS asks to create as many variables as the variable "variable" has modalities */

  data NegVal_&data._4 (drop=_NAME_ _LABEL_);/* creation of a dataset "NegVal_&data._4"  where I do not keep the variables "_NAME_" and "_LABEL_" */ /* "NegVal_&data._4" will be the final table for the number of negative values */
  retain Country; /* we want the variable "Country" to appear first in the dataset "NegVal_&data._4" */
  set NegVal_&data._3; /* from the dataset "NegVal_&data._3" */
  Country = "&Country."; /* create a variable "Country" where the modality will be equal to the macro-parameter "&Country." */
  run;

  /**************************/
  /* for the missing values */
  /**************************/
  data MissVal_&data.; /* creation of a dataset "MissVal_&data." */
  set Num_Var_&data._Finfreq; /* from the dataset "Num_Var_&data._Finfreq" */
  where modality = ""; /* where the modality of the variable "modality" is equal to "" */
  run;

  data MissVal_&data. (drop= Variable rename = (Variable1 = Variable)); /* creation of a dataset "MissVal_&data." where I drop the variable "Variable" and after rename the variable "Variable1" by "Variable" */
  set MissVal_&data.; /* from the dataset "MissVal_&data." */
  Variable1 = compress (lowcase(Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* "Variable1" will be equal to the variable "Variable" in lowcases and without any kind of punctuations */
  run;

  proc transpose data=MissVal_&data. out=MissVal_&data._1; id Variable; run; /* transcription of the table "MissVal_&data." into the dataset "MissVal_&data._1", it will have as many variables as the variable "variable" has modalities*/

  data MissVal_&data._2 (drop= _NAME_ _LABEL_); /*creation of a dataset named "MissVal_&data._2" where we delete the variables "_NAME_" and "_LABEL_"*/ /* "MissVal_&data._2" will be the final table for the number of missing values */
  retain Country; /* we want the variable "Country" to appear first in the dataset "MissVal_&data._2" */
  set MissVal_&data._1; /* from the dataset "MissVal_&data._1" */
  Country = "&Country."; /* we create the variable "Country" where its modality will be equal to the macro-parameter &Country. */
  run;

  /************************************************************************************************************/
  /* The exports of the negative values and missing values for the datasets "HH" and "HM" for a given country */
  /************************************************************************************************************/

  /***************************/
  /* for the negative values */
  /***************************/
   proc sql noprint;
   /*select distinct modality into:diffmodalityneg separated by "" from NUM_VAR_&data._FINFREQ; */ /* select the different modalities of the variable "modality" that you will separated by "" from the dataset "NUM_VAR_&data._FINFREQ" into a macro-parameter named "diffmodalityneg" */
   /* emanuele :  I guess is better to avoid long macro variable because 
   we get error in the log when they are too long */
   select distinct modality from NUM_VAR_&data._FINFREQ;
   quit;

   %IF /*%index (&diffmodalityneg.,-) */ 
    &sqlobs > 0 /* emanuele: see my comment I guess is better to avoid long macro ...*/
   %then %do; /* if the occurence "-" happens in the macro-parameter "&diffmodalityneg." do the exportation of the number of negative values, if it is not present it won't do it*/


  proc export data=NegVal_&data._4 /* do the export of the dataset "NegVal_&data._4" */
	               outfile = "&path_DC_CE_REC./&data._NumberofNegativeValuebyNumVariablesAllCountries.txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
				   dbms= tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */
				   delimiter = ";"; /* the separator will be ";"*/
				   putnames = yes; /* we want the name of the variables to appear in the final outputs */
  run;



   %end; /* end of %IF %index (&diffmodalityneg.,-) %then %do on the previous code */

 /**************************/
 /* for the missing values */
 /**************************/
 data num_var_&data._finfreq_1; /* create a dataset "num_var_&data._finfreq_1" */
 set NUM_VAR_&data._FINFREQ; /* from the dataset "NUM_VAR_&data._FINFREQ" */
 if modality = "" then modality1 = "missing"; /* if the modality of the variable "modality" is equal to "" so create a variable "modality1" which will be equal to "missing"*/
 run;

 proc sql noprint;
 select distinct modality1 into:diffmodalitymiss separated by "" from num_var_&data._finfreq_1; /* select the different modalities of the variable "modality1" that you will separated by "" from the dataset "num_var_&data._finfreq_1" into a macro-parameter named "diffmodalitymiss"*/
 quit;

 %IF %index (&diffmodalitymiss.,missing) %then %do; /* if the occurence "missing" happens in the macro-parameter "&diffmodalitymiss." do the exportation of the number of missing values, if it is not present it won't do it */


 proc export data= MissVal_&data._2 /* do the export of the dataset "MissVal_&data._2" */
             outfile= "&path_DC_CE_REC./&data._NumberofMissingValuesByNumVariablesAllCountries.txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
			 dbms= tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */
		     delimiter = ";"; /* the separator will be ";"*/
		     putnames = yes; /* we want the name of the variables to appear in the final outputs */
  run;

  %end; /* end of %IF %index (&diffmodalityneg.,-) %then %do on the previous code */


  /*********************************************************/
  /* Deletion of intermediate tables that fill the library */
  /*********************************************************/
  proc datasets lib=work nolist;
  delete Num: NegVal_&data._1 - NegVal_&data._3 MissVal_&data. MissVal_&data._1 Miss_Num_Content_&data._&Country. Miss_Num_Content_&data._&Country._1
         NegVal_&data. ;
  run;

  %MEND Negative_Missing_Numvar; /* end of the macro %Negative_Missing_Numvar */


/*************************************************************************************************************************************************************************************/
/* The objectives of the macro "Missing_Disvar" are to :															                                                                 */
/* Check the number of missing values for the variables that are considered character in the text file "RecordLayout" and which are present for the files                            */
/* "HH" and "HM" and to export those results in a text file...if there are some missing values, for the export (txt file) we will have for variables "Country" (corresponding to the */
/* the country concerned) and the different variables where there are missing values with the number of times there are missing values for the corresponding variable                */
/* the datasets used for the export (once again if there are missing values) are "MissVal_Dis_HH_2" (for the file "HH") and "MissVal_Dis_HM_2" (for the file "HM")                   */
/*************************************************************************************************************************************************************************************/

%Macro Missing_Disvar (data,Country); /* it will have two parameters for this macro named "Missing_Disvar" "&data." and "&Country." */

proc contents data=&data._&Country. 
              out=Miss_Dis_Content_&data._&Country. /* Here we want to display the content of the data "HH" and "HM" for the country that we have chosen to run the codes */   
			  noprint;                              /* and named it "Miss_Dis_Content_&data._&Country." (&data. is corresponding to HH or HM and &Country. for the Country*/            
run;                                                /* that we have chosen */

proc sort data= Miss_Dis_Content_&data._&Country.;
by name;                                            /* We sort the table "Miss_Dis_Content_&data._&Country." by "name" that column corresponds to the different */                                              
run;                                                /* variables found in the dataset "&data._&Country." */

proc sql noprint;
create table Dislistvar as                          /* create a SAS dataset named "Dislistvar" */      
select distinct Variable as name                    /* where we are going to select the different modalities of the variable "Variable" that we will name "name"*/    
from RecordLayout                                   /* from the SAS dataset "RecordLayout" */                   
where type not in ('num' 'int');                    /* where the modalities of the variable "type" are not equal to "num" or "int"*/       
quit;

data Miss_Dis_Content_&data._&Country._1;           /* create a table named "Miss_Dis_Content_&data._&Country._1" */
merge Miss_Dis_Content_&data._&Country. (in = a) Dislistvar (in = b); /* by merging the two tables "Miss_Dis_Content_&data._&Country." and "Dislistvar"*/
by name; /* by the key variable "name" */
if a and b; /* if both modalies are in the dataset table "Miss_Dis_Content_&data._&Country." (corresponding to the tag "a") and the dataset "Dislistvar" (corresponding to the tag "b")*/
run;

proc sql noprint;

  select distinct name into:Dis_Varnamn_deux separated by ' - ' from Miss_Dis_Content_&data._&Country._1 where type eq 2; /* select the different modalities of the variable "name" that you will separate by ' - ' from the sas dataset "Miss_Dis_Content_&data._&Country._1" where the variable "type" is equal to 2 and contain that in a macro-parameter named "Dis_Varnamn_deux"  */

  select count (distinct name) into:Dis_Varnbn_deux from Miss_Dis_Content_&data._&Country._1 where type eq 2; /* Count the number of distinct modalities for the variable "name" where the variable "type" is equal to 2  from the dataset "Miss_Dis_Content_&data._&Country._1" and contain that in a macro-parameter named "Dis_Varnbn_deux" */

  select distinct name into:Dis_Varnamn_un separated by ' - ' from Miss_Dis_Content_&data._&Country._1 where type eq 1; /* select the different modalities of the variable "name" that you will separate by ' - ' from the sas dataset "Miss_Dis_Content_&data._&Country._1" where the variable "type" is equal to 1 and contain that in a macro-parameter named "Dis_Varnamn_un"  */

  select count (distinct name) into:Dis_Varnbn_un from Miss_Dis_Content_&data._&Country._1 where type eq 1; /* Count the number of distinct modalities for the variable "name" where the variable "type" is equal to 1  from the dataset "Miss_Dis_Content_&data._&Country._1" and contain that in a macro-parameter named "Dis_Varnbn_un" */


 quit;

  %DO i=1 %TO &Dis_Varnbn_deux.; /* create a loop that will be applicated "&Dis_Varnbn_deux." number of times */

   %LET Dis_Varnnc_deux = %Scan (&Dis_Varnamn_deux.,&i., ' - '); /* creation of a macro-variable "Dis_Varnnc_deux" which will be equal to the "i"th "word" of the variable "&Dis_Varnamn_deux.", those "words" are sseparated by "-" */

    data Dis_Varnnc_&data._gwn_&i.; /* create sas datasets named "Dis_Varnnc_&data._gwn_&i." where &i. represents &Dis_Varnbn_deux., so if &Dis_Varnbn_deux. equals to 5 we will have five datasets Dis_Varnnc_&data._gwn_1 until Dis_Varnnc_&data._gwn_5 (data is still representing HH or HM) */
	set &data._&Country. (keep = COUNTRY &Dis_Varnnc_deux.); /* from the dataset "&data._&Country." where you keep only the variables "COUNTRY" "&Dis_Varnnc_deux." in order to create the different "Dis_Varnnc_&data._gwn_&i." */
	varlab = "&Dis_Varnnc_deux."; /* creation of a variable "varlab" where the modality will be equal to "&Dis_Varnnc_deux." */
    rename &Dis_Varnnc_deux. = valuec; /* we rename the variable "&Dis_Varnnc_deux." by "valuec" */
	run;

	data Dis_Varnnc_&data._gwn_&i.; /* create datasets named "Dis_Varnnc_&data._gwn_&i." (the same than the set) */
	attrib variabletest length=$15.; /* where you create a variable named "variabletest" which will be a character variable and will have a length of 15*/
    set Dis_Varnnc_&data._gwn_&i.; /* from the same datasets "Dis_Varnnc_&data._gwn_&i." */
    COUNTRY = "&Country."; /* create a variable "Country" where the modality will be equal to the macro-parameter "&Country." */
    variabletest = input(valuec,$15.); /* calculation of the variable "variabletest" */
    run;

%END; /* end of the loop "%DO i=1 %TO &Dis_Varnbn_deux." */

  %DO j=1 %TO &Dis_Varnbn_un.; /* create a loop that will be applicated "&Dis_Varnbn_un." number of times */

    %LET Dis_Varnnc_un = %Scan (&Dis_Varnamn_un.,&j., ' - '); /* creation of a macro-variable "Dis_Varnnc_un" which will be equal to the "j"th "word" of the variable "&Dis_Varnamn_un.", those "words" are sseparated by "-" */

	data Nic_Dis_Varnnc_&data._gwn_&j._v2; /* create SAS datsets named "Nic_Dis_Varnnc_&data._gwn_&j._v2"*/
	set &data._&Country.(keep= COUNTRY &Dis_Varnnc_un.); /* from the dataset "&data._&Country." where you keep only the variables "COUNTRY" and "&Dis_Varnnc_un."*/
	varlab = "&Dis_Varnnc_un."; /* creation of a variable "varlab" where the modality will be equal to "&Dis_Varnnc_un." */
	rename &Dis_Varnnc_un. = valuec; /* we rename the variable "&Dis_Varnnc_un." by "valuec" */
	run;


	data Nic_Dis_Varnnc_&data._gwn_&j._v3 (drop= valuec rename=(valuec1 = valuec)); /* We create datasets "Nic_Dis_Varnnc_&data._gwn_&j._v3" where in first we do not keep the variable "valuec" from the datasets "Nic_Dis_Varnnc_&data._gwn_&j._v2" and after we rename the variable "valuec1" by "valuec" */
	set Nic_Dis_Varnnc_&data._gwn_&j._v2; /* from the datasets "Nic_Dis_Varnnc_&data._gwn_&j._v2" */
	valuec1 = input(valuec,$15.); /* calculation of the variable "valuec1" */
    variabletest = valuec1; /* calculation of the variable "variabletest" */
    run;

	proc datasets lib=work nolist; /*We delete the SAS datasets "Nic_Dis_Varnnc_&data._gwn_&j._v2" */
    delete Nic_Dis_Varnnc_&data._gwn_&j._v2;
    run;


%END; /* End of the loop %DO j=1 %TO &Dis_Varnbn_un. */

data Dis_Var_&data._Final (rename=(variabletest = valuec)) ; /* creation of the dataset "Dis_Var_&data._Final" where we rename the variable "variabletest" by "valuec" */
length Country $15.; /*We define the length of the Variable "Country" to avoid issue of length during the set of all the dataset tables*/
set Dis_Varnnc_&data._gwn_:(drop=valuec) Nic_Dis_Varnnc_&data._:(drop=valuec); /* from those datasets "Dis_Varnnc_&data._gwn_:"  "Nic_Dis_Varnnc_&data._:"  where we delete the variable "valuec" */
run;

 proc freq data= Dis_Var_&data._Final noprint; /* proc freq allows the construction of simple cross tables, here from the SAS dataset "Dis_Var_&data._Final" */
 table valuec*varlab /*construction of a simple cross table between the variables "valuec" and "varlab" */ / out = Dis_Var_&data._Finfreq (drop= Percent rename=(valuec = modality count=Frequency varlab=Variable)); /* the output of that simple cross table will be in a dataset named "Dis_Var_&data._Finfreq" where I dropped the variable "Percent" from the output and where I rename some variables (valuec by modality....count by frequency...varlab by variable)*/
 run;

 data Dis_Var_&data._Finfreq (drop=Variable rename=(Variable1 = Variable)); /* creation of a dataset "MissVal_&data." where I drop the variable "Variable" and after rename the variable "Variable1" by "Variable" */
 set Dis_Var_&data._Finfreq; /* from the dataset "Dis_Var_&data._Finfreq" */
 Variable1 = compress (lowcase(Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* The variable "Variable1" will be equal to the variable "Variable" in lowcases and without any kind of punctuations*/
 run;

 /******************************/
 /* spot of the missing values */
 /******************************/
  data MissVal_Dis_&data.; /* creation of a dataset "MissVal_Dis_&data." */
  set Dis_Var_&data._Finfreq; /* from the dataset "Dis_Var_&data._Finfreq" */
  where modality = ""; /* where the modality of the variable "modality" is equal to "" */
  run;  

  proc transpose data=MissVal_Dis_&data. out=MissVal_Dis_&data._1; id Variable; run; /* transcription of the table "MissVal_Dis_&data." into the dataset "MissVal_Dis_&data._1", it will have as many variables as the variable "variable" has modalities*/

  data MissVal_Dis_&data._2 (drop= _NAME_ _LABEL_); /*creation of a dataset named "MissVal_Dis_&data._2" where we delete the variables "_NAME_" and "_LABEL_"*/ /* "MissVal_Dis_&data._2" will be the final table for the number of missing values */
  retain Country; /* we want the variable "Country" to appear first in the dataset "MissVal_Dis_&data._2" */
  set MissVal_Dis_&data._1; /* from the dataset "MissVal_Dis_&data._1" */
  Country = "&Country."; /* we create the variable "Country" where its modality will be equal to the macro-parameter &Country. */
  run;

  /********************************/
  /* export of the missing values */
  /********************************/
  data Dis_Var_&data._Finfreq_1; /* create a dataset "Dis_Var_&data._Finfreq_1" */
 set Dis_Var_&data._Finfreq; /* from the dataset "Dis_Var_&data._Finfreq" */
 if modality = "" then modality1 = "missing"; /* if the modality of the variable "modality" is equal to "" so create a variable "modality1" which will be equal to "missing"*/
 run;

 proc sql noprint;
 select distinct modality1 into:diffmodalitycharmiss separated by "" from Dis_Var_&data._Finfreq_1; /* select the different modalities of the variable "modality1" that you will separated by "" from the dataset "Dis_Var_&data._Finfreq_1" into a macro-parameter named "diffmodalitycharmiss"*/
 quit;

 %IF %index (&diffmodalitycharmiss.,missing) %then %do; /* if the occurence "missing" happens in the macro-parameter "&diffmodalitycharmiss." do the exportation of the number of missing values, if it is not present it won't do it */

 proc export data= MissVal_Dis_&data._2 /* do the export of the dataset "MissVal_Dis_&data._2" */
             outfile= "&path_DC_CE_REC./&data._NumberofMissingValuesByDiscreteVariablesAllCountries.txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
			 dbms= tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */
		     delimiter = ";"; /* the separator will be ";"*/
		     putnames = yes; /* we want the name of the variables to appear in the final outputs */
  run;

  %END; /* end of %IF %index (&diffmodalitycharmiss.,missing) %then %do */

 /**************************************************************/
 /* Deletion of intermediate tables that fill the work library */
 /**************************************************************/
 proc datasets lib=work nolist;
 delete Miss_Dis_Content: Dis: Missval_Dis_&data. Missval_Dis_&data._1 Nic:;
 run;


%MEND Missing_Disvar; /* end of the macro Missing_Disvar */



/***************************/
/* Check Execution program */
/***************************/
/***********************************************************************************************************************************/
/* The objectives of the macro "Unexpected_Variables" is : 																		   */
/* -  To show the unexpected variables of the Country that we imported , the ones which are not found in the RecordLayout txt file */
/***********************************************************************************************************************************/

%Macro Unexpected_Variables (Country,data1,data2);
data test; /* We create a SAS dataset named "test" */

set &data1._&Country._VARS (keep=NAME) /* We are doing a set between the two datasets which contains the different variables for the two datasets */ 
     &data2._&Country._VARS (keep=NAME); /*(HH and HM) for a Country given , we will only keep the variable "NAME" which contains the name of the Variables */
run;

proc sort data=test out=test1 nodupkey; /* We are doing a proc sort nodpukey in case where it would have the same variable for each dataset */
by name;                                /* the result of that proc sort is located into a SAS dataset named "test1" */
run;

/* for the Country  */
data test2 (keep= name1); /* We create a SAS dataset named "test2" where we keep only the variable "name1" created after */
set test1; /* from the SAS dataset "test1" */
name1 = compress (lowcase(NAME),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* we create a variable named "name1" which will be equals to the variable "name" */
run;                                                                                       /* in lowercase and without any punctuation */

/* for the file RecordLayout */
data test3 (keep= Variable1); /* We create a dataset named "test3" where we only keep the variable "Variable1" that we have created after*/
set RECORDLAYOUT; /* from the SAS dataset "RECORDLAYOUT" */
Variable1 = compress(lowcase (Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* We create a variable named "Variable1" which will be equal to the variable*/
run;                                                                                               /* "Variable" in lowecase and without any punctuation */

/* the merge */

/* we will do a merge of the two datasets "test2" and "test3" in order to see if there are Variables of the Country concerned which are not found in "RecordLayout" */
proc sort data=test2 out=test4 nodupkey; by name1; run; /* proc sort of the dataset "test2" by the key variable "name1" where we do not want duplicates in the output dataset "test4" */

proc sort data=test3 out=test5 nodupkey; by Variable1; run; /* proc sort of the dataset "test3" by the key Variable "Variable1" where we do not want duplicates in the output dataset "test5" */


data test6 (rename=(Variables = Unexpected_Variables)); /* creation of a dataset named "test6" where we rename the variable "Variables" (that we created after) by "Unexpected_Variables"  */
merge test4(rename=(name1 = Variables) in=a) test5 (rename=(Variable1 = Variables) in=b); /* by merging the two datasets "test4" and "test5" */
by Variables; /* by the key variable "Variables" */
if a and not b; /* if the modalities which are in the dataset "test4" (coresponding to the tag "a") are not found in the dataset "test5" */
run;


proc contents data=test6 out=test7 noprint; /* Here we are doing the contents of the dataset "test6" and the data from that content will be named "test7"*/
run;

proc sql noprint;
select distinct NOBS into:nbreobs separated by "" from test7; /* We select the different modalities of the variable "NOBS" from the dataset "test7" that we separated by "" */
quit;

%IF &nbreobs. = 0 %then %do; /* %IF &nbreobs. = 0 means here if there are no unexpected variables */
%PUT "There are no unexpected variables for &Country."; /* Show in the log the following message "There are no unexpected variables for &Country." */
%end; /* end of the %IF &nbreobs. = 0 %then %do*/

%else %do; /* But if there are some unexpected variables you have to export them */
proc export data=test6 /* do the export of the dataset "test6" */
            outfile = "&path_DC_CE_REC./&Country._unexpected_variables.txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
            dbms= tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */
		    delimiter = ";"; /* the separator will be ";"*/
		    putnames = yes; /* we want the name of the variables to appear in the final outputs */
 run;

 %end; /* end of the %else %do; */

 /**********************************************************************************/
 /* Creation of  a sas dataset to have a look at the eventual unexpected variables */
 /**********************************************************************************/
 data &Country._unexpected_variables;
 set test6;
 run;

 /***************************************************************/
 /* Delete of the tables that fill the work library for nothing */
 /***************************************************************/
 proc datasets lib=work nolist;
 delete test test1 - test7;
 run;

%mend Unexpected_Variables;


/**************************************************************************************************************************************************************************/
/* The objective of the macro "Absent_Variables" is to have all the variables which are present in the dataset RecordLayout but which are absent for the Country imported */
/**************************************************************************************************************************************************************************/

%Macro Absent_Variables(data1,data2,Country);

/********************************************************************************************************************/
/* 1st step : We want to know all the variables which are located in the datasets "HH" and "HM" for a given country */
/********************************************************************************************************************/

proc contents data= &data1._&Country.
              out= &data1._&Country._1  noprint; /* &data1._&Country._1 : SAS dataset containing the different variables for the table "&data1._&Country." */
run;

data &data1._&Country._2 (drop= NAME rename=(Name1 = NAME)); /* we drop the variable "NAME" and we rename the variable "Name1" by "NAME" */
set &data1._&Country._1; /* from the dataset "&data1._&Country._1" */
Name1 = compress (lowcase(NAME),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* where the variable "Name1" will be equal to the variable "NAME" in lowcase and without any eventual punctuation */
run;

proc contents data=&data2._&Country.
              out =&data2._&Country._1 noprint; /* HM_&Country_imported._1 : SAS dataset containing the different variables for the table "&data2._&Country."*/
run;    

data &data2._&Country._2 (drop= NAME rename=(Name1 = NAME)); /* We drop the variable "NAME" and we rename the variable "Name1" by "NAME"*/
set &data2._&Country._1; /* from the SAS dataset "&data2._&Country._1" */
Name1 = compress (lowcase(NAME),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* where the variable "Name1" will be equal to the variable "NAME" in lowcase and without any eventual punctuation */
run;

data &data1._&data2._variables; /* Creation of a dataset "&data1._&data2._variables" which will contain all the variables found in "&data1._&Country._2" and "&data1._&Country._2"*/

set &data1._&Country._2 (keep= Name)         /* Set of the two datasets "&data1._EE_2" and "&data2._&Country._2" (for both we only keep=the variable "Name" to obtain the dataset "&data1._&data2._variables" */
    &data2._&Country._2 (keep= Name); 
 
run;   

proc sort data= &data1._&data2._variables 
          out=&data1._&data2._variables_1 nodupkey; /* In the dataset "&data1._&data2._variables" maybe we can have two times the same variables so we do a proc sort nodupkey to avoid that */
by name;                                            /* so in the dataset "&data1._&data2._variables_1" we will have all the variables with no duplication*/    
 
run;  

/*******************************************************************************************************************************************************************/
/* 2nd step : Create a SAS dataset where we will have all the variables (which actually are modalities of the variable "Variable") of the SAS table "RecordLayout" */
/*******************************************************************************************************************************************************************/
data RecordLayout1 (drop=Variable rename=(Variable1 = NAME)); /* Creation of a dataset "RecordLayout1" where we drop the variable "Variable" and rename the variable "Variable1" by "NAME" */
set RecordLayout; /* from the dataset "RecordLayout" */
Variable1 = compress (lowcase(Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ "); /* where the variable "Variable1" will be equal to the variable "Variable" in lowcase and without any eventual punctuation */
run;

proc sort data=RecordLayout1 
      out=RecordLayout2 nodupkey;    /* We have a proc sort nodupkey of the dataset "RecordLayout1" into "RecordLayout2" in order to not have the same modality of keyvariable twice*/
 by name; /* the key variable is the variable "name" */
run;

/*************************************************************************************************************************************************************/
/* 3rd step : We will create a SAS table (with the help of a merge statement) which will tell us the variables which are located in the file "RecordLayout2" */
/* but which are missing in the SAS dataset "&data1._&data2._variables_1", we will name that sas dataset "&Country._Absent_Variables"                        */
/*************************************************************************************************************************************************************/
data &Country._Absent_Variables (keep=NAME); /* creation of a dataset "&Country._Absent_Variables" where we keep only the variable "NAME" */
length NAME $32.; /* We assign the length of the variable "NAME" in order to not have a length issue during the merge*/
merge RecordLayout2 (in=a) &data1._&data2._variables_1 (in=b); /* merge between the two corresponding SAS tables "RecordLayout2" and "&data1._&data2._variables_1" */
by name; /* by the key variable "name", the proc sort has already been done for the datas that we are merging, so I do not need to do it again */
if a and not b then output; /* if the content is in the dataset "RecordLayout2" (with the tag "a") but not in the dataset "HH_HM_variables_1" do the output*/
run;



/***********************************************************************************************************************/
/* 4th step : Even if we spot all the variables which are in the dataset "RecordLayout2"                               */
/* and not in the dataset "&data1._&data2._variables_1" the R programmation asks to delete some of those which appears */
/* several conditions are mentionned to delete those variables                                                         */
/***********************************************************************************************************************/
data &Country._Absent_Variables_1;

set &Country._Absent_Variables;

/**********************************************************************************************************************************/
/* We create several intermediates variables in order to delete the good variables                                                */
/* "longueur" = allow us to determinate the length of the variable "NAME" by using the functions "length and "Compress"           */
/* "deletefirstcondition" + "deletesecondcondition" + "deletethirdcondition" + "deletefourthcondition" + "deletefifthcondition"   */
/* "deletesixthcondition" + "deleteseventhcondition" + "deleteeigthcondition" + "deleteninthcondition" + "deletetenthcondition" + */
/* "deleteeleventhcondition" will be use to delete easily the variables                                                           */
/**********************************************************************************************************************************/
longueur = length(compress(NAME));

if substr(NAME,1,2) eq "hq" then deletefirstcondition = "yes"; else deletefirstcondition = "no"; /* 1st condition (hq) : withdraw if the first two characters of the variable "NAME" = "hq" */
 

if index(NAME,"he") and substr(NAME,1,3) ne "eur" then deletesecondcondition = "yes"; else deletesecondcondition = "no"; /* 2nd condition (xxx_he) : withdraw if the modality contains "he" and if the first three characters of "NAME" ne "eur" */


if substr(NAME,1,2) eq "he" then deletethirdcondition = "yes"; else deletethirdcondition = "no"; /* 3rd condition (he_) : withdraw if the first two characters of the variable "NAME" = "he" */
 

if index(NAME,"hj") and substr(NAME,1,3) ne "eur" then deletefourthcondition = "yes"; else deletefourthcondition = "no"; /* 4th condition (xxx_hj) : withdraw if the modality contains "hj" and if the first three characters of "NAME" ne "eur" */


if substr(NAME,1,2) eq "hj" then deletefifthcondition = "yes"; else deletefifthcondition = "no";/* 5th condition (hj_) : withdraw if the first two characters of the variable "NAME" = "hj" */
 

if index(NAME,"he") and substr(NAME,longueur,longueur) = "a" then deletesixthcondition = "yes"; else deletesixthcondition = "no"; /* 6th condition (hexxa) : withdraw the modalities which contains "he" and end by "a" */


if index(NAME,"he") and substr(NAME,longueur,longueur) = "b" then deleteseventhcondition = "yes"; else deleteseventhcondition = "no"; /* 7th condition (hexxb) : withdraw the modalities which contains "he" and end by "b" */


if index(NAME,"hh") and substr(NAME,1,3) ne "eur" then deleteeigthcondition = "yes"; else deleteeigthcondition = "no"; /* 8th condition (xxx_hh) : withdraw if the modalities contains "hh" and if the first three characters of "NAME" ne "eur" */


if substr(NAME,1,2) eq "hh" then deleteninthcondition = "yes"; else deleteninthcondition = "no";/* 9th condition (hh_) : withdraw if the first two modalities of the variable "NAME" = "hh" */
 

if index(NAME,"mf") and substr(NAME,1,3) ne "eur" then deletetenthcondition = "yes"; else deletetenthcondition = "no"; /* 10th condition (xxx_mf) : withdraw if the modalities contains "mf" and if the first three characters of "NAME" ne "eur" */


if substr(NAME,1,2) eq "mf" then deleteeleventhcondition = "yes"; else deleteeleventhcondition = "no"; /* 11th condition (mf) : withdraw if the first two characters of the variable "NAME" = "mf" */


run;

/*****************************************************************************************************************/
/* 5th step : creation of the final dataset which will give us the variables by using the intermediate variables */
/* if one of the intermediate variable is equal to "yes" we delete the variable concerned                        */
/*****************************************************************************************************************/

data &Country._Absent_Variables_2 (keep= NAME rename=(NAME = Absent_Variables));

set &Country._Absent_Variables_1;

if deletefirstcondition = "yes" or deletesecondcondition = "yes" or deletethirdcondition = "yes" or deletefourthcondition = "yes" or deletefifthcondition = "yes"

   or deletesixthcondition = "yes" or deleteseventhcondition = "yes" or deleteeigthcondition = "yes" or deleteninthcondition = "yes" or deletetenthcondition = "yes"

   or deleteeleventhcondition = "yes" then delete;

run;


/******************************************************************************************/
/* 6th step : Export of the file &Country._absent_variables if there are absent variables */
/******************************************************************************************/
proc contents data=&Country._Absent_Variables_2 out=&Country._Absent_Variables_3 noprint; /* Here we are doing the contents of the dataset "&Country._Absent_Variables_2" and the data from that content will be named "&Country._Absent_Variables_2"*/
run;

proc sql noprint;
select distinct NOBS into:nbreobs separated by "" from &Country._Absent_Variables_3; /* We select the different modalities of the variable "NOBS" from the dataset "&Country._Absent_Variables_3" that we separated by "" */
quit;

%IF &nbreobs. = 0 %then %do; /* %IF &nbreobs. = 0 means here if there are no absent variables */
%PUT "There are no absent variables for &Country."; /* Show in the log the following message "There are no unexpected variables for &Country." */
%end; /* end of the %IF &nbreobs. = 0 %then %do*/

%else %do; /* But if there are some absent variables you have to export them */

proc export data= &Country._Absent_Variables_2  /* Do the export of the dataset "&Country._Absent_Variables_2"*/
            outfile= "&path_DC_CE_REC./&Country._absent_variables.txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
			dbms = tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */

			delimiter = "," ; /* the separator will be ","*/

			putnames = yes; /* we do not want the name of the variables to appear in the final outputs */
run;

%end;

/********************************************************************************/
/* 7th step : We delete the tables that fullfill the work library unnecessarily */
/********************************************************************************/
proc datasets lib=work nolist;
delete &Country._Absent_Variables_1 &data1._&Country._1 &data1._&Country._2 &data2._&Country._1 &data2._&Country._2 &data1._&data2._variables &data1._&data2._variables_1
       &Country._Absent_Variables &Country._Absent_Variables_3 RecordLayout1 RecordLayout2;
run;

%mend Absent_Variables;


/*******************************************************************************************************************************************************************************/
/* The objective of the macro %Unexpected_Modalities is to export the eventual unexpected Modalities of the variables in the Country imported taking into account RecordLayout */
/*******************************************************************************************************************************************************************************/
%Macro Unexpected_Modalities (data,Country);

data test1(drop=Variable);
set RecordLayout;
where Values ne "";
name = compress (lowcase(Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ ");
run;

data test2;
set &data._&Country.;
numero = _N_;
run;

proc transpose data=test2 out=test3;
by numero;
var _ALL_;
run;

data test4 (drop = _NAME_) ;
set test3;
name = compress (lowcase(_NAME_),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ ");
run;

proc sort data=test4 out=test5;
by numero;
run;

proc transpose data=test5 out=test6(drop= numero _NAME_); /* test 1 : recordlayout    test6: hm_ee)*/
by numero;
var COL1;
id name;
run;


proc sql noprint;
select distinct(name) into:diffvar separated by " - " from test1;
select count (distinct name) into:nbdiffvar from test1;
quit;

%Do i=1 %To &nbdiffvar.;

%LET choose_var = %scan (&diffvar.,&i., " - ");

proc sql noprint;
select distinct quote(values) into:diffvalues separated by " " from test1 where name = "&choose_var.";
quit;

proc contents data=test6 out=test7 noprint; run;

proc sql noprint;
select distinct NAME into:varcontent separated by " " from test7;
quit;

%If %index(&varcontent.,&choose_var.) %then %do;
data test8 (keep= &choose_var.);
set test6;
where &choose_var. not in (&diffvalues.);
run;

proc contents data=test8 out=test9 noprint; run;

proc sql noprint;
select nobs into:numberobs from test9 where NAME = "&choose_var.";
run;

%if &numberobs. > 0 %then %do;

proc export data= test8 
             outfile= "&path_DC_CE_REC./&Country._&data._unexpected_modalities_of_&choose_var..txt" 
			 dbms= tab replace; 
		     delimiter = ";"; 
		     putnames = yes; 
  run;

%end; /* end de %if %numberobs. > 0 %then %do */

%end; /* end de %If %index(&varcontent.,&choose_var.) %then %do */

%else %do;
%PUT Variable &choose_var. is not in the dataset &data._&Country.;
%end; /* end de %else %do*/



%end; /* end de %Do i=1 %To &nbdiffvar.*/
proc datasets lib=work nolist;
delete test1 - test9;
run;

%mend Unexpected_Modalities;


/**********************************************************************************************************************************************************************/
/* The objective of the macro %Cont_Var_Summaries is to Calculate the statistics for the continous variables in the Country imported taking into account RecordLayout */
/**********************************************************************************************************************************************************************/
%Macro Cont_Var_Summaries(data,Country);

data test1 (drop=Variable);
set RecordLayout;
name = compress (lowcase(Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ ");
run;

proc sql noprint;

select distinct (name) into:RLNV separated by " " from test1 where Type in("num" "int"); run; /* I select the different numeric variables in the RecordLayout dataset */
select count (distinct name) into:Nb_RLNV from test1 where Type in("num" "int") ; run; /* I count the number of numeric variables from the RecordLayout dataset */
quit;


data test2;
set &data._&Country.;
numero = _N_;
run;

proc transpose data=test2 out=test3;
by numero;
var _ALL_;
run;

data test4 (drop = _NAME_) ;
set test3;
name = compress (lowcase(_NAME_),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ ");
run;

proc sort data=test4 out=test5;
by numero;
run;

proc transpose data=test5 out=test6(drop= numero _NAME_); 
by numero;
var COL1;
id name;
run;

data test7 (keep = &RLNV.);
set test6;
run;


%Do i=1 %to &Nb_RLNV.;

%LET var_chosen = %scan(&RLNV.,&i.," ");

data test8 (keep= &var_chosen._1 rename=(&var_chosen._1 = &var_chosen.));
set test7;
&var_chosen._1 = input(&var_chosen.,22.);
run;

proc transpose data=test8 out=test9 (rename=(_NAME_ = Variable)); run;

data test10_&i. (drop =  COL:);
set test9;
minimum = min (of COL:);
firstquartile= pctl(25,of COL:);
median = median (of COL:);
moyenne = mean (of COL:);
thirdquartile = pctl(75,of COL:);
maximum = max (of COL:);
run;

%end; /* end de %Do i=1 %to &Nb_RLNV. */

data test11;
length Variable $32.;
set test10_:;
if minimum = . and firstquartile = . and median = . and moyenne = . and thirdquartile = . and maximum = . then delete; 
run;

proc sort data=test11 out=test12; by Variable; run;

proc export data= test12

            outfile= "&path_DC_CE_REC./&data._&Country._cont_var_summaries.txt"

			dbms=tab replace;

			delimiter = ";" ;

			putnames = no;
run;

data &data._&Country._cont_var_summaries;
set test12;
run;

/***********************************/
/* deletion of intermediate tables */
/***********************************/
proc datasets lib =  work nolist;
delete test1 - test9 test10_: test11 test12;
run;

%mend Cont_Var_Summaries;


/********************************************************************************************************************************************************************/
/* The objective of the macro %Dis_Var_Summaries is to Calculate the statistics for the discrete variables in the Country imported taking into account RecordLayout */
/********************************************************************************************************************************************************************/
%Macro Dis_Var_Summaries(data,Country);

data test1 (drop=Variable);
set RecordLayout;
name = compress (lowcase(Variable),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ ");
run;

proc sql noprint;

select distinct (name) into:RLDV separated by " " from test1 where Type not in("num" "int"); run; 
select count (distinct name) into:Nb_RLDV from test1 where Type not in("num" "int") ; run; 
quit;


data test2;
set &data._&Country.;
numero = _N_;
run;

proc transpose data=test2 out=test3;
by numero;
var _ALL_;
run;

data test4 (drop = _NAME_) ;
set test3;
name = compress (lowcase(_NAME_),"! ' # $ % ( ) * + , - . / : ; < = > ? @ [ ] ^ _ { } ~ ");
run;

proc sort data=test4 out=test5;
by numero;
run;

proc transpose data=test5 out=test6(drop= numero _NAME_); 
by numero;
var COL1;
id name;
run;

data test7 (keep = &RLDV.);
set test6;
run;

proc contents data=test7 out=test8 noprint; run;

proc sql noprint;
select distinct NAME into:vardiscr separated by " " from test8; run;
select count (distinct NAME) into:nbvardiscr from test8;run;
quit;

%Do i=1 %to &nbvardiscr.;

%LET var_chosen = %scan(&vardiscr.,&i.," ");

Data test9 (keep= &var_chosen.);
set test7;
run;

proc freq data= test9 noprint;
table &var_chosen./out=test10_&var_chosen. (drop=PERCENT rename=(COUNT = Frequency_&var_chosen.));
run;

data test11;
merge test10_:;
run;

data &data._&Country._discrete_var_summaries;
set test11;
run;

/***********************/
/* Export of the table */
/***********************/
proc export data= test11

            outfile= "&path_DC_CE_REC./&data._&Country._discrete_varsummaries.txt"

			dbms=tab replace;

			delimiter = "09"x ;

			putnames = yes;
run;

%end; /* end de  %Do i=1 %to &nbvardiscr.*/

/********************************/
/* delete of intermediate tables */
/********************************/
proc datasets lib=work nolist;
delete test1 - test9  test10_: test11;
run;


%mend Dis_Var_Summaries;



/*************/
/* R2CatVars */
/*************/
/************************************************************************************************************************/
/* The objective of the macro "%R2CatVars" is to replace the no specified values of some variables by the modality "NA" */
/************************************************************************************************************************/

%Macro R2CatVars (Country);

proc contents data=temp6 out=test1 noprint; run; /* the content of the country imported */

proc sql noprint;
select distinct NAME into:varscountry separated by " " from test1;  /* We select the different variables in the country imported */
quit;

data test2;
set temp6;

/* length de 2 */

%if %index(&varscountry.,HA08) %then %do; /* for ha08 */
if HA08 = "99" then HA08 = "NA";
%end;

%if %index(&varscountry.,HB075) %then %do; /* for hb075 */
if HB075 = "99" then HB075 = "NA";
%end;

%if %index(&varscountry.,HC23) %then %do; /* for hc23 */
if HC23 = "99" then HC23 = "NA";
%end;

%if %index(&varscountry.,HC24) %then %do; /* for hc24 */
if HC24 = "99" then HC24 = "NA";
%end;

%if %index(&varscountry.,MA05) %then %do; /* for ma05 */
if MA05 = "99" then MA05 = "NA";
%end;

%if %index(&varscountry.,MB01) %then %do; /* for mb01 */
if MB01 = "99" then MB01 = "NA";
%end;

%if %index(&varscountry.,MB011) %then %do; /* for MB011 */
if MB011 = "99" then MB011 = "NA";
%end;

%if %index(&varscountry.,MB012) %then %do; /* for MB012 */
if MB012 = "99" then MB012 = "NA";
%end;

%if %index(&varscountry.,MB03) %then %do; /* for MB03 */
if MB03 = "99" then MB03 = "NA";
%end;

%if %index(&varscountry.,ME0908) %then %do; /* for ME0908 */
if ME0908 = "99" then ME0908 = "NA";
%end;

%if %index(&varscountry.,ME0988) %then %do; /* for ME0988 */
if ME0988 = "99" then ME0988 = "NA";
%end;


/* length de 1 */

%if %index(&varscountry.,HA09) %then %do; /* pour HA09 */
attrib HA09_1 format=$char2. length=$2.;
HA09_1 = HA09;
if HA09 = "9" then HA09_1 = "NA";
drop HA09;
rename HA09_1 = HA09;
%end;


%if %index(&varscountry.,HI11) %then %do; /* pour HI11 */
attrib HI11_1 format=$char2. length=$2.;
HI11_1 = HI11;
if HI11 = "9" then HI11_1 = "NA";
drop HI11;
rename HI11_1 = HI11;
%end;

%if %index(&varscountry.,MB02) %then %do; /* pour MB02 */
attrib MB02_1 format=$char2. length=$2.;
MB02_1 = MB02;
if MB02 = "9" then MB02_1 = "NA";
drop MB02;
rename MB02_1 = MB02;
%end;

%if %index(&varscountry.,MB04) %then %do; /* pour MB04 */
attrib MB04_1 format=$char2. length=$2.;
MB04_1 = MB04;
if MB04 = "9" then MB04_1 = "NA";
drop MB04;
rename MB04_1 = MB04;
%end;

%if %index(&varscountry.,MB042) %then %do; /* pour MB042 */
attrib MB042_1 format=$char2. length=$2.;
MB042_1 = MB042;
if MB042 = "9" then MB042_1 = "NA";
drop MB042;
rename MB042_1 = MB042;
%end;

%if %index(&varscountry.,MB05) %then %do; /* pour MB05 */
attrib MB05_1 format=$char2. length=$2.;
MB05_1 = MB05;
if MB05 = "9" then MB05_1 = "NA";
drop MB05;
rename MB05_1 = MB05;
%end;

%if %index(&varscountry.,MC01) %then %do; /* pour MC01 */
attrib MC01_1 format=$char2. length=$2.;
MC01_1 = MC01;
if MC01 = "9" then MC01_1 = "NA";
drop MC01;
rename MC01_1 = MC01;
%end;

%if %index(&varscountry.,MC02) %then %do; /* pour MC02 */
attrib MC02_1 format=$char2. length=$2.;
MC02_1 = MC02;
if MC02 = "9" then MC02_1 = "NA";
drop MC02;
rename MC02_1 = MC02;
%end;

%if %index(&varscountry.,ME01) %then %do; /* pour ME01 */
attrib ME01_1 format=$char2. length=$2.;
ME01_1 = ME01;
if ME01 = "9" then ME01_1 = "NA";
drop ME01;
rename ME01_1 = ME01;
%end;

%if %index(&varscountry.,ME02) %then %do; /* pour ME02 */
attrib ME02_1 format=$char2. length=$2.;
ME02_1 = ME02;
if ME02 = "9" then ME02_1 = "NA";
drop ME02;
rename ME02_1 = ME02;
%end;

%if %index(&varscountry.,ME03) %then %do; /* pour ME03 */
attrib ME03_1 format=$char2. length=$2.;
ME03_1 = ME03;
if ME03 = "9" then ME03_1 = "NA";
drop ME03;
rename ME03_1 = ME03;
%end;

%if %index(&varscountry.,ME04) %then %do; /* pour ME04 */
attrib ME04_1 format=$char2. length=$2.;
ME04_1 = ME04;
if ME04 = "Z" then ME04_1 = "NA";
drop ME04;
rename ME04_1 = ME04;
%end;

%if %index(&varscountry.,ME12) %then %do; /* pour ME12 */
attrib ME12_1 format=$char2. length=$2.;
ME12_1 = ME12;
if ME12 = "9" then ME12_1 = "NA";
drop ME12;
rename ME12_1 = ME12;
%end;

%if %index(&varscountry.,ME13) %then %do; /* pour ME13 */
attrib ME13_1 format=$char2. length=$2.;
ME13_1 = ME13;
if ME13 = "9" then ME13_1 = "NA";
drop ME13;
rename ME13_1 = ME13;
%end;

run;

data &Country._R2CatVars;
set test2;
run;

/*******************************/
/* deletion of test1 and test2 */
/*******************************/
proc datasets lib=work nolist;
delete test1 test2;
run;

%mend R2CatVars;




/*************/
/* Recodings */
/*************/

/********************************************************************************************************/
/* The objectives of the macro "Recodings" is to Recode for annual age, marital status and define NUTS1 */
/********************************************************************************************************/
%Macro Recodings (Country);

proc contents data=&Country._R2CatVars out=test1 noprint; run; /* we want the different variables of the dataset table "EE_R2CatVars" */

proc sql noprint;
select distinct NAME into:VarCatvars separated by " " from test1; /* we get the different variables into a macro parameter */
quit;

/* top bottom coding for annual age */
data test2;
set &Country._R2CatVars;
%if %index (&VarCatvars.,&AGE.) %then %do; /* if the parameter AGE is in the table "EE_R2CatVars" then do */

age1 = input(&AGE.,2.); /* the name of the variable will be "age1" and will be numeric as said in the R codes */

/* ad hoc coding for age */
length age_adhoc $6.;
if age1 < = 14 then age_adhoc = "0_14";
if age1 >14 and age1 < 30 then age_adhoc = "15_29";
if age1 > 29 and age1 < 45 then age_adhoc = "30_44";
if age1 > 44 and age1 < 60 then age_adhoc = "45_59";
if age1 > 59 then age_adhoc = "60_Inf";

/* top coding for ages in classes having size = 5 years without bottom */
length age5 $6.;
if age1 < = 4 then age5 = "00_04";
if age1 >4 and age1 < 10 then age5 = "05_09";
if age1 > 9 and age1 < 15 then age5 = "10_14";
if age1 > 14 and age1 < 20 then age5 = "15_19";
if age1 > 19 and age1 < 25 then age5 = "20_24";
if age1 > 24 and age1 < 30 then age5 = "25_29";
if age1 > 29 and age1 < 35 then age5 = "30_34";
if age1 > 34 and age1 < 40 then age5 = "35_39";
if age1 > 39 and age1 < 45 then age5 = "40_44";
if age1 > 44 and age1 < 50 then age5 = "45_49";
if age1 > 49 and age1 < 55 then age5 = "50_54";
if age1 > 54 and age1 < 60 then age5 = "55_59";
if age1 > 59 and age1 < 65 then age5 = "60_64";
if age1 > 64 and age1 < 70 then age5 = "65_69";
if age1 > 69 and age1 < 75 then age5 = "70_74";
if age1 > 74 and age1 < 80 then age5 = "75_79";
if age1 > 79 and age1 < 85 then age5 = "80_84";
if age1 > 84 then age5 = "85_Inf";

/* top bottom coding for age in classes haveing size = 10 years */
length age10 $6.;
if age1 < = 14 then age10 = "00_14";
if age1 > 14 and age1 < 25 then age10 = "15_24";
if age1 > 24 and age1 < 35 then age10 = "25_34";
if age1 > 34 and age1 < 45 then age10 = "35_44";
if age1 > 44 and age1 < 55 then age10 = "45_54";
if age1 > 54 and age1 < 65 then age10 = "55_64";
if age1 > 64 and age1 < 75 then age10 = "65_74";
if age1 > 74 and age1 < 85 then age10 = "75_84";
if age1 > 84  then age10 = "85_inf";


run;

data &Country._Bottom;
set test2;
where age1 <= 14;
run;

data &Country._Top;
set test2;
where age1 >= 85;
run;

proc freq data= test2 noprint;
tables age1/missing /* tell SAS to include the missing values as a row in the table */ out=&Country._Frequencies_age1 (drop=percent rename=(COUNT = Frequency));
run;

proc freq data= test2 noprint;
tables age_adhoc/missing /* tell SAS to include the missing values as a row in the table */ out=&Country._Frequencies_age_adhoc (drop=percent rename=(COUNT = Frequency));
run;

proc freq data= test2 noprint;
tables age5/missing /* tell SAS to include the missing values as a row in the table */ out=&Country._Frequencies_age5 (drop=percent rename=(COUNT = Frequency));
run;

proc freq data= test2 noprint;
tables age10/missing /* tell SAS to include the missing values as a row in the table */ out=&Country._Frequencies_age10 (drop=percent rename=(COUNT = Frequency));
run;



proc print data=test2 (keep=age5 obs=10); run; /* print for age5 the first 10 rows */

proc print data=test2 (keep=age10 obs=10); run;/* print for age10 the first 10 rows */


/* get the last lines */
proc sql noprint;
select count (*) into:nbrobstest2 from test2;
quit;

/* print for age5 the last 10 rows */
data test3(keep= age5);
set test2;
if _n_> %eval (&nbrobstest2. - 10);
run;

proc print data=test3; run;

/* print for age10 the last 10 rows */
data test4(keep= age10);
set test2;
if _n_> %eval (&nbrobstest2. - 10);
run;

proc print data=test4; run;

%end; /* end de %if %index (&VarCatvars.,&AGE.) %then %do*/

%else %do;

%Put Annual age is ommited;

%end; /* end de %else %do */

run;

/*******************************/
/* recording of marital status */
/*******************************/

data test5;
set test2;

%if %index (&VarCatvars.,&MSTAT.) %then %do; /* if the parameter MSTAT is in the table "EE_R2CatVars" then do */
length &MSTAT._34 $2.;
if &MSTAT. = "4" then &MSTAT._34 = "3" ; 
else &MSTAT._34 = &MSTAT.;
run;

proc freq data= test5 noprint;
tables &MSTAT._34/missing /* tell SAS to include the missing values as a row in the table */ out=Frequencies_&MSTAT._34 (drop=percent rename=(COUNT = Frequency));
run;

%end; /* end de %if %index (&VarCatvars.,&MSTAT.) %then %do*/

%else %do;

%PUT &MSTAT. is not defined ;

%end; /* end de %else %do */
run;


/*********************/
/* recoding of NUTS1 */
/*********************/
data test6 ;
set test5;
%if %index (&VarCatvars.,&NUTS2.) %then %do; /* if the parameter NUTS2 is in the table "EE_R2CatVars" then do */
&NUTS2._length = length (&NUTS2.);
&NUTS2._minus_one = &NUTS2._length - 1;
NUTS1 = substr(&NUTS2.,1,&NUTS2._minus_one);
drop &NUTS2._length &NUTS2._minus_one;
%end; /* end de %if %index (&VarCatvars.,&NUTS2.) %then %do */

%else %do;
%PUT &NUTS2. is not defined;
run;
%end;/* end de else do */

/**************************************************************/
/* Weight and Number of household members have to be numeric  */
/* Weight and Number of household members are already numeric */                                 
/**************************************************************/

/******************************/
/* We will rename some tables */
/******************************/
data &Country._Age5_lastrows;
set test3;
run;

data &Country._Age10_Lastrows;
set test4;
run;

data &Country._AfterRecodings;
set test6;
run;

/**************************************************************/
/* Export of the table "&Country._AfterRecodings" in txt file */
/**************************************************************/
proc export data= &Country._AfterRecodings /* do the export of the dataset "&Country._AfterRecodings" */
             outfile= "&path_DC_CE_REC./&Country._AfterRecodings.txt" /* put the export at that location where you define the name of the output and its format (.txt here) */
			 dbms= tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */
		     delimiter = ";"; /* the separator will be ";"*/
		     putnames = yes; /* we want the name of the variables to appear in the final outputs */
 run;

 /******************************************/
 /* deletion of the intermediate variables */
 /******************************************/
 proc datasets lib=work nolist;
 delete test1 - test6;
 run;

%mend Recodings;


/************************************************************************/
/* The objective of the macro idc is to display the occupation variable */
/************************************************************************/
%Macro idc (Country);
proc contents data=&Country._R2CatVars out=test1 noprint;

data test2;
set test1 (keep= NAME);
where NAME in ("&ISCO88." "&ISCO08." "ME12" "ME13");
run;

proc contents data=test2 out=test3 noprint; run;

proc sql;
select NOBS into:nbrobstest3 from test3;
quit;

%IF &nbrobstest3. = 0 %then %DO;
%PUT The parameter occup is null;
%end;

%else %do;
proc sort data=test2 out=test4; by name; run;

data test5;
set test4;
order = _N_;
run;

proc sql noprint;
select NAME into:idc from test5 where order = 1;
quit;

%PUT The parameter idc is the variable &idc.; /* Here you see the value representing the parameter idc */

%end;

/**************************************/
/* deletion of intermediate variables */
/**************************************/
proc datasets lib=work nolist;
delete test1 - test5;
run;

%mend idc;


/***************/
/* R4_MFRfiles */
/***************/
/*********************************************************************************************************************************************************************/
/* The objective of the macro "Before_Step1_R4" is to create a sub-table of hh where you keep only the variables where the name contains the caracter chain "EUR_HE" */
/*********************************************************************************************************************************************************************/

%Macro Before_Step1_R4 (data,Country);

/*****************************************************************************************************************************************************/
/* 3) + 4)We create the table "dat.hh.eur.he a sub-table of hh where you keep only the variables where the name contains the caracter chain "EUR_HE" */
/*****************************************************************************************************************************************************/
data &Country._&data._EUR_HE (keep= EUR_HE:);
set &data._&Country.;
run;

/************************************************************************************************/
/* 5) on cree le vecteur EurHeVarList contenant le nom des variables de &Country._&data._EUR_HE */
/************************************************************************************************/
proc contents data=&Country._&data._EUR_HE out=&Country._test100 noprint; run;

proc sql noprint; 
select distinct (NAME) into:EurHeVarList separated by ' ' from &Country._test100 ;
quit;

/**************************************************************/
/* 6) si hm existe, on importe la table et on la nomme dat.hm */
/**************************************************************/

/**********************************************************************************************************************/
/* 7) on cree le vecteur countries qui reprend la liste des pays repris dans la table dat.hh dans la variable COUNTRY */
/**********************************************************************************************************************/
proc sql noprint; 
select distinct COUNTRY into:countries separated by ' ' from &data._&Country.; 
quit;

%mend Before_Step1_R4;


/************************************/
/* pour chaque pays dans une boucle */
/************************************/

/*****************************************************************************************************************************************************************************************************************************************************************************************************************************/
/* The objectives of the macro "R4_Step1" is the creation of multiple variables when it is possible for the data HH for a country given : &NUTS1. , &AGE._Recoded_5Classes , &AGE._Recoded_5YearsClasses, &COB._Recoded_3Categ, &COC._Recoded_3Categ, &COR._Recoded_3Categ,&MSTAT._Recoded_3Categ, &ISCO08._Recoded,HA04rand */
/*****************************************************************************************************************************************************************************************************************************************************************************************************************************/
%Macro R4_Step1 (Country,data);

/* 1) on cree la table temp , une sous table de dat.hh ne concernant que les observations concernant le pays concerne par l'iteration de la boucle */
data Temp;
set &data._&Country.;
run;

/* 2)on cree le vecteur vars.hh reprenant le nom des colonnes de temp */
proc contents data=Temp out=temp1 noprint; 
run;

proc sql noprint; 
select distinct (NAME) into:VarsHH separated by ' ' from temp1 ; 
run;

%PUT &VarsHH.;

/* 3) On defini la variable nuts1 
 a) si la variable comprise dans le parametre NUTS2 fait partie de la table temp:
i. Dans la table temp, on cree la variable nuts1 qui est determine sur la base de la variable comprise dans le parametre NUTS2.
Les valeurs de la variable nuts1 correspondent qux trois premiers caracteres des chaines de caractere de la variable comprise dans le parametre NUTS2
on place cette nouvelle variable a cote de la variable comprise dans le parametre NUTS2 et on replace le nom de cette derniere par son nom initial
auquel on concatene "_suppressed" (dans notre simulation ca donne "ha08_suppressed")*/

%if %index (&VarsHH.,&NUTS2.) %then %do; /* do numero 1 = si la variable comprise dans le parametre NUTS2 fait partie de la table temp */

data test101 (rename=(&NUTS2. = &NUTS2._suppressed));
retain NUTS1 &NUTS2.;
set temp;
NUTS1 = substr(&NUTS2.,1,3);
run;

%end; /* end numero 1 = si la variable comprise dans le parametre NUTS2 fait partie de la table temp */

%else %do; /* do numero 2 = si la variable comprise dans le parametre NUTS2 ne fait pas partie de la table temp*/
%PUT The variable &NUTS2. does not exist in the file &data. for the Country &Country. ;
data test101;
set temp;
run;
%end; /* end numero 2 = si la variable comprise dans le parametre NUTS2 ne fait pas partie de la table temp*/

/**********************************************************************************************/
/* si la variable comprise dans le parametre NUTS2 fait partie de la table temp alors:        */
/* Creation d'un dataset "test101" à partir du dataset "temp" 								  */
/* 																							  */
/* Si la variable comprise dans le parametre NUTS2 ne fait pas partie de la table temp alors: */
/* Creation d'un dataset "test101" à partir du dataset "temp"                                 */
/**********************************************************************************************/
 

/* 4) on recode les ages annuels 
a) Si la variable comprise dans le parametre AGE est comprise dans la table temp 
i. Dans la table temp, on cree la variable AGE_Recoded_5Classes que l'on place directement apres la variable comprise dans AGE.
Cette variable est egale  a "00_14" "15_29" "30_44" "45_59" "60_Inf" en fonction de l'age de l'observation 
ii. Attention, dans le nom de la variable, AGE doit etre remplace par le nom de la variable enregistree dans ce parametre.
Dans notre simulation cela donne mb03_recoded_5classes
iii. Dans la table temp, on cree la variable AGE_Recoded_5YearsClasses. Cette variable repartit les ages en fonction de tranche 
d'age de 5 ans : "0_4" "5_9" "10_14" "15_19".... "80_84" "85_inf". Attention, dans le nom de la variable, AGE doit etre remplace
par le nom de la variable enregistree dans ce parametre.
Dans notre simulation cela donne mb03_Recoded_5Classes et mb03_Recoded_5yearsClasses */

%if %index (&VarsHH.,&AGE.) %then %do; /* do numero 3 = Si la variable comprise dans le parametre AGE est comprise dans la table temp*/

data test102 (drop= &AGE._v2);
retain &AGE._Recoded_5Classes &AGE._Recoded_5YearsClasses;
set test101;

&AGE._v2 = input(&AGE.,best3.);

if &AGE._v2 >= 60 then &AGE._Recoded_5Classes = "60_Inf";
if 0 < = &AGE._v2 <= 14 then &AGE._Recoded_5Classes = "0_14";
if 15 < = &AGE._v2 <= 29 then &AGE._Recoded_5Classes = "15_29";
if 30 < = &AGE._v2 <= 44 then &AGE._Recoded_5Classes = "30_44";
if 45 < = &AGE._v2 <= 59 then &AGE._Recoded_5Classes = "45_59";

if &AGE._v2 >= 85 then &AGE._Recoded_5YearsClasses = "85_Inf";
if 0 < = &AGE._v2 <= 4 then &AGE._Recoded_5YearsClasses = "0_4";
if 5 < = &AGE._v2 <= 9 then &AGE._Recoded_5YearsClasses = "5_9";
if 10 < = &AGE._v2 <= 14 then &AGE._Recoded_5YearsClasses = "10_14";
if 15 < = &AGE._v2 <= 19 then &AGE._Recoded_5YearsClasses = "15_19";
if 20 < = &AGE._v2 <= 24 then &AGE._Recoded_5YearsClasses = "20_24";
if 25 < = &AGE._v2 <= 29 then &AGE._Recoded_5YearsClasses = "25_29";
if 30 < = &AGE._v2 <= 34 then &AGE._Recoded_5YearsClasses = "30_34";
if 35 < = &AGE._v2 <= 39 then &AGE._Recoded_5YearsClasses = "35_39";
if 40 < = &AGE._v2 <= 44 then &AGE._Recoded_5YearsClasses = "40_44";
if 45 < = &AGE._v2 <= 49 then &AGE._Recoded_5YearsClasses = "45_49";
if 50 < = &AGE._v2 <= 54 then &AGE._Recoded_5YearsClasses = "50_54";
if 55 < = &AGE._v2 <= 59 then &AGE._Recoded_5YearsClasses = "55_59";
if 60 < = &AGE._v2 <= 64 then &AGE._Recoded_5YearsClasses = "60_64";
if 65 < = &AGE._v2 <= 69 then &AGE._Recoded_5YearsClasses = "65_69";
if 70 < = &AGE._v2 <= 74 then &AGE._Recoded_5YearsClasses = "70_74";
if 75 < = &AGE._v2 <= 79 then &AGE._Recoded_5YearsClasses = "75_79";
if 80 < = &AGE._v2 <= 84 then &AGE._Recoded_5YearsClasses = "80_84";
run;

/* iv. Ensuite, on essaye d'ouvrir le fichier sous le nom :
"ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt", si il existe on nomme cette table
hh_at_risk */

%if %sysfunc(fileexist("&path_contvarsoutput./&Country._spont_t1000_s1_hh_at_risk.txt")) %then %do; /* do numero 4 = on essaye d'ouvrir le fichier sous le nom : "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt", si il existe on nomme cette table hh_at_risk*/

data HH_at_risk;
Length F1 $16.;
Format F1 $16.;
Informat F1 $16.;
infile "&path_contvarsoutput./&Country._spont_t1000_s1_hh_at_risk.txt"

LRECL = 16
ENCODING = "WLATIN1"
TERMSTR = CRLF
DLM = '7F'x
MISSOVER
DSD;

INPUT F1 : $16. ;

run;

/* v. Si ce fichier existe, on repere les observations de temp pour lesquelles la valeur de la variable comprise dans HID existe dans la table hh.at.risk */
/*Pour ces observations , la valeur reprise dans la classe d'age AGE_Recoded_5YearsClasses est effacee et remplacee par NA */

/* vi. La variable comprise dans le parametre AGE est renommee AGE_suppressed (avec AGE qui doit etre remplace par le nom de la variable enregistree dans le parametre AGE) */
/* et les valeurs de cette colonne sont toutes remplacees par NA */

proc sql noprint;
create table test103 as
select a.* , b.*
from test102 as a
left join HH_at_risk as b
on (a.&HID. = b.F1)
order by a.&HID.;
quit;

data test104 (rename=(&AGE. = &AGE._suppressed) drop=F1);
set test103;
if &HID. = F1 then &AGE._Recoded_5YearsClasses = "NA";
&AGE. = "NA";
run;

%end; /* end numero 4 = on essaye d'ouvrir le fichier sous le nom : "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt", si il existe on nomme cette table hh_at_risk*/

%else %do; /* do numero 5 = si le fichier sous le nom : "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" n'existe pas*/
%PUT The txt file &Country._spont_t1000_s1_hh_at_risk does not exist;
data test104;
set test102;
run;
%end; /* end numero 5 = si le fichier sous le nom : "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" n'existe pas*/

%end; /* end numero 3 = Si la variable comprise dans le parametre AGE est comprise dans la table temp */

%else %do; /* do numero 6 = Si la variable comprise dans le parametre AGE n'est pas comprise dans la table temp */
%PUT The variable &AGE. is not  in the table temp;
data test104;
set test101;
run;
%end; /* end numero 6 = Si la variable comprise dans le parametre AGE n'est pas comprise dans la table temp */

/******************************************************************************************************************************************/
/* Si la variable comprise dans le parametre AGE est comprise dans la table temp alors : (do numero 3)                                    */
/*  creation d'un dataset "test102" à partir du dataset "test101"                                                                         */
/*                                                                                                                                        */
/* Si le fichier sous le nom "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" existe on nomme                                     */
/* cette table "HH_at_risk" (condition imbriquée dans Si la variable comprise dans le parametre AGE est comprise dans la table temp alors */
/* creation d'une table "test103" issu d'un merge entre "test102" et "HH_at_risk"                                                         */
/* puis d'une table "test104" à partir de la table "test103"                                                                              */
/*                                                                                                                                        */
/* Si le fichier sous le nom "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" n'existe pas (do numero 5)                          */
/* création d'une table "test104" à partir de la table "test102"                                                                          */
/*                                                                                                                                        */
/* Si la variable comprise dans le parametre AGE n'est comprise dans la table temp alors : (do numero 6)                                  */
/* creation d'un dataset "test104" à partir du dataset "test101"                                                                          */
/******************************************************************************************************************************************/

/****************************************************************************/
/* 5. Recodage des codes pays pour suivre la classification ISO3166 alpha-2 */
/****************************************************************************/

/*****************************************************************************************************/
/* a. Importer la table EU2015-ISOalpha2.txt. C'est une table qui contient les codes deux digits des */ 
/* pays d'europe. On apelle cette table iso (attention a updater cette liste en fonction             */
/* des pays europeens                                                                                */
/*****************************************************************************************************/        
data iso (rename = (F1 = Countries));
length F1 $2.;
Format F1 $2.;
Informat F1 $2.;
infile &path_iso.;
input F1 : $2.;
run;

/*******************************************************************************************/
/* b. si la variable comprise dans le parametre COB est une variable de la table temp:     */
/*   i. On cree tmp, une sous table de temp ne comprenant que les variables comprises dans */ 
/*      le parametre COB                                                                   */
/*******************************************************************************************/
%IF %index (&VarsHH.,&COB.) %then %do; /* do numero 7 =  si la variable comprise dans le parametre COB est une variable de la table temp*/
data tmpcob (keep= &COB.);
set test104;
run;

proc sort data=tmpcob out=test105 nodupkey;
by &COB.;
run;

data test106;
set test105;
attrib variable6 length=$16.;
var1 = "10";
var2 = "21";
var3 = "22";
var4 = "2X";
var5 = "99";
if not(&COB. = var1 or &COB. = var2 or &COB. = var3 or &COB. = var4 or &COB. = var5) then variable6 = "problem";
else if (&COB. = var1 or &COB. = var2 or &COB. = var3 or &COB. = var4 or &COB. = var5) then variable6 = "no problem";
run;

proc sql;
select count (variable6) into:nbpbcob from test106 where variable6 = "problem" ;
quit;

/********************************************************************************************/
/* ii. Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes :     */ 
/* "10" "21" "22" "2X" "99" alors : 											            */
/*  1. on ajoute a temp la variable COB_Recoded_3Categ                                      */
/* (où COB est remplace par la variable qui est enregistre dans le parametre COB)           */
/*  2. Si la variable comprise dans COB prends le code du pays concerne par l'iteration     */ 
/* dans la table temp alors la nouvelle variable vaut "10".                                 */
/*  3. Si elle est differente du pays concerne par l'iteration mais concerne un pays repris */ 
/* dans la liste ISO, alors la nouvelle variable vaut "21" 									*/
/*  4. Dans tous les autres cas, elle vaut "22" 											*/
/*  5. Dans la table temp, on renomme la variable reprise dans COB, COB_suppressed          */ 
/* (dans notre cas mb01_suppressed) 													    */
/*  6. pour info, 10= national , 21= non national mais EU, 22 = non national et non EU      */
/********************************************************************************************/
%IF &nbpbcob. ne 0 %then %do; /* do numero 9 =  Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes :*/
data test107 (rename=(&COB. = &COB._suppressed));
set test104;
if &COB. = COUNTRY then &COB._Recoded_3Categ = "10";
if &COB. ne COUNTRY and &COB. in (&Country_isoalpha2.) then &COB._Recoded_3Categ = "21";
if &COB. ne COUNTRY and &COB. not in (&Country_isoalpha2.) then &COB._Recoded_3Categ = "22";
run;
%end; /* end numero 9 = Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes : */

%else %IF &nbpbcob. eq 0 %then %do; /* do numero 10 */
%PUT All the values of the Variable &COB. in the file &data. for the Country &Country. are valid;
data test107;
set test104;
run;
%end; /* end numero 10 */


%end; /* end numero 7 =  si la variable comprise dans le parametre COB est une variable de la table temp */

%else %do; /* do numero 8 = si la variable comprise dans le parametre COB n'est pas une variable de la table temp */
%PUT The variable &COB. is not in the table temp;
data test107;
set test104;
run;
%end; /* end numero 8 = si la variable comprise dans le parametre COB n'est pas une variable de la table temp */

/******************************************************************************************************/
/* iii. on fait exactement le meme travail pour les parametres COC et COR qui comcerne respectivement */ 
/* le pays de mationalite (country of citizenship) et le pays de residence.                           */                                      
/*  COB concernait le pays de naissance (Country of Birth).                                           */
/******************************************************************************************************/

/*************************/
/* pour le paramètre COC */
/*************************/
%IF %index (&VarsHH.,&COC.) %then %do; /* do numero 11 =  si la variable comprise dans le parametre COC est une variable de la table temp*/
data tmpcoc (keep= &COC.);
set test107;
run;

proc sort data=tmpcoc out=test108 nodupkey;
by &COC.;
run;

data test109;
set test108;
attrib variable6 length=$16.;
var1 = "10";
var2 = "21";
var3 = "22";
var4 = "2X";
var5 = "99";
if not(&COC. = var1 or &COC. = var2 or &COC. = var3 or &COC. = var4 or &COC. = var5) then variable6 = "problem";
else if (&COC. = var1 or &COC. = var2 or &COC. = var3 or &COC. = var4 or &COC. = var5) then variable6 = "no problem";
run;

proc sql;
select count (variable6) into:nbpbcoC from test109 where variable6 = "problem" ;
quit;

/********************************************************************************************/
/* ii. Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes :     */ 
/* "10" "21" "22" "2X" "99" alors : 											            */
/*  1. on ajoute a temp la variable COC_Recoded_3Categ                                      */
/* (où COB est remplace par la variable qui est enregistre dans le parametre COC)           */
/*  2. Si la variable comprise dans COC prends le code du pays concerne par l'iteration     */ 
/* dans la table temp alors la nouvelle variable vaut "10".                                 */
/*  3. Si elle est differente du pays concerne par l'iteration mais concerne un pays repris */ 
/* dans la liste ISO, alors la nouvelle variable vaut "21" 									*/
/*  4. Dans tous les autres cas, elle vaut "22" 											*/
/*  5. Dans la table temp, on renomme la variable reprise dans COC, COC_suppressed          */ 
/* (dans notre cas mb011_suppressed) 													    */
/*  6. pour info, 10= national , 21= non national mais EU, 22 = non national et non EU      */
/********************************************************************************************/

%IF &nbpbcoc. ne 0 %then %do; /* do numero 13 =  Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes :*/
data test110 (rename=(&COC. = &COC._suppressed));
set test107;
if &COC. = COUNTRY then &COC._Recoded_3Categ = "10";
if &COC. ne COUNTRY and &COC. in (&Country_isoalpha2.) then &COC._Recoded_3Categ = "21";
if &COC. ne COUNTRY and &COC. not in (&Country_isoalpha2.) then &COC._Recoded_3Categ = "22";
run;
%end; /* end numero 13 = Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes : */

%else %IF &nbpbcob. eq 0 %then %do; /* do numero 14 */
%PUT All the values of the Variable &COC. in the file &data. for the Country &Country. are valid;
data test110;
set test107;
run;
%end; /* end numero 14 */


%end; /* do numero 11 =  si la variable comprise dans le parametre COC est une variable de la table temp*/

%else %do; /* do numero 12 =  si la variable comprise dans le parametre COC n'est pas une variable de la table temp*/
%PUT The variable &COC. is not in the table temp;
data test110;
set test107;
run;
%end; /* do numero 12 =  si la variable comprise dans le parametre COC n'est pas une variable de la table temp*/


/*************************/
/* Pour le paramètre COR */
/*************************/
%IF %index (&VarsHH.,&COR.) %then %do; /* do numero 15 =  si la variable comprise dans le parametre COR est une variable de la table temp*/
data tmpcor (keep= &COR.);
set test110;
run;

proc sort data=tmpcor out=test111 nodupkey;
by &COR.;
run;

data test112;
set test111;
attrib variable6 length=$16.;
var1 = "10";
var2 = "21";
var3 = "22";
var4 = "2X";
var5 = "99";
if not(&COR. = var1 or &COR. = var2 or &COR. = var3 or &COR. = var4 or &COR. = var5) then variable6 = "problem";
else if (&COR. = var1 or &COR. = var2 or &COR. = var3 or &COR. = var4 or &COR. = var5) then variable6 = "no problem";
run;

proc sql;
select count (variable6) into:nbpbcoR from test112 where variable6 = "problem" ;
quit;

/********************************************************************************************/
/* ii. Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes :     */ 
/* "10" "21" "22" "2X" "99" alors : 											            */
/*  1. on ajoute a temp la variable COR_Recoded_3Categ                                      */
/* (où COR est remplace par la variable qui est enregistre dans le parametre COR)           */
/*  2. Si la variable comprise dans COR prends le code du pays concerne par l'iteration     */ 
/* dans la table temp alors la nouvelle variable vaut "10".                                 */
/*  3. Si elle est differente du pays concerne par l'iteration mais concerne un pays repris */ 
/* dans la liste ISO, alors la nouvelle variable vaut "21" 									*/
/*  4. Dans tous les autres cas, elle vaut "22" 											*/
/*  5. Dans la table temp, on renomme la variable reprise dans COR, COR_suppressed          */ 
/* (dans notre cas mb011_suppressed) 													    */
/*  6. pour info, 10= national , 21= non national mais EU, 22 = non national et non EU      */
/********************************************************************************************/

%IF &nbpbcor. ne 0 %then %do; /* do numero 16 =  Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes :*/
data test113 (rename=(&COR. = &COR._suppressed));
set test110;
if &COR. = COUNTRY then &COR._Recoded_3Categ = "10";
if &COR. ne COUNTRY and &COR. in (&Country_isoalpha2.) then &COR._Recoded_3Categ = "21";
if &COR. ne COUNTRY and &COR. not in (&Country_isoalpha2.) then &COR._Recoded_3Categ = "22";
run;
%end; /* end numero 16 = Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes : */

%else %IF &nbpbcor. eq 0 %then %do; /* do numero 17 */
%PUT All the values of the Variable &COR. in the file &data. for the Country &Country. are valid;
data test113;
set test110;
run;
%end; /* end numero 17 */


%end; /* do numero 15 =  si la variable comprise dans le parametre COR est une variable de la table temp*/

%else %do; /* do numero 18 =  si la variable comprise dans le parametre COR n'est pas une variable de la table temp*/
%PUT The variable &COR. is not in the table temp;
data test113;
set test110;
run;
%end; /* do numero 18 =  si la variable comprise dans le parametre COC n'est pas une variable de la table temp*/

/***************************************************************************************************************************/
/* 6. Recoder pour le statut matrimonial (variable enregistree dans le parametre MSTAT)                                    */
/*     a. Si la variable comprise dans MSTAT existe aussi dans temp :													   */
/*																														   */
/*          i. Dans la table temp, on cree la variable MSTAT_Recoded_3Categ (MSTAT est a remplacer par la variable qui     */
/*             est dans ce parametre, par exemple MB04_Recoded_3Categ)													   */
/*																														   */
/*          ii. Si la valeur de la variable enregistree dans MSTAT dans la table temp est egale a 4, alors on change et    */
/*              on lui donne la valeur 3. Sinon on ne change rien.														   */
/*																														   */
/*          iii. Dans la table temp, on renomme la variable comprise dans MSTAT pour l'appeler MSTAT_suppressed (MSTAT est */
/*               a remplacer par la variable). On remplace toutes les valeurs de cette variable par NA                     */
/***************************************************************************************************************************/

%IF %index (&VarsHH.,&MSTAT.) %then %do; /* do numero 19 */

         data test114 (drop=&MSTAT. rename=(&MSTAT._v2 = &MSTAT._suppressed));
		 set test113;

		 attrib &MSTAT._v2 length= $2. format= $2.;

		 if &MSTAT. = "4" then &MSTAT._Recoded_3Categ = "3";
		 else if &MSTAT. ne "4" then &MSTAT._Recoded_3Categ = &MSTAT.;
		 &MSTAT._v2 = &MSTAT.;
         &MSTAT._v2 = "NA";

		 run;

%end; /* end numero 19 */


%else %do; /* do numero 20 */
%PUT The variable &MSTAT. does not exist in the file &data. for the Country &Country.;
data test114;
set test113;
run;

%end; /* end numero 20 */

/*****************************************************************************************************************************************/
/* 7. Recoder la variable statut d'occupation : parametre ISCO08 (qui comprend la variable me0908 dans la simulation) 					 */
/*																																	     */
/*      a. Si la variable comprise dans ISCO08 est aussi une variable de la table temp: 												 */
/*																																		 */
/*          i. Dans la table temp, on cree la colonne ISCO_Recoded (dans notre simulation cela donne me0908_recoded)					 */
/*																																		 */
/*          ii. Si le premier caractere de la valeur de la variable comprise dans ISCO08 dans la table temp est un 0, alors on recode Z0 */
/*              Si c'est un 1, on recode "Z1"																							 */
/*              Sinon on laisse la meme valeur que la valeur initiale.																	 */
/*																																		 */
/*          iii. On renomme la variable initiale ISCO08_suppressed (me0908_suppressed) et on remplace les valeurs par NA 				 */
/*****************************************************************************************************************************************/
%IF %index (&VarsHH.,&ISCO08.) %then %do; /* do numero 21 */

        data test115 (rename=(&ISCO08. = &ISCO08._suppressed));
		set test114;
		if substr(&ISCO08.,1,1) = "0" then &ISCO08._Recoded = "Z0";
        if substr(&ISCO08.,1,1) = "1" then &ISCO08._Recoded = "Z1";
		if substr(&ISCO08.,1,1) not in("0" "1") then &ISCO08._Recoded = &ISCO08.;
		&ISCO08. = "NA";
		run;

%end; /* end numero 21 */

%else %do; /* do numero 22 */
%PUT The variable &ISCO08. does not exist in the file &data. for the Country &Country. ;
data test115;
set test114;
run;
%end; /* end numero 22 */

/**********************************************************************************************************/
/* 8. Transformation en variable numerique des variables de la table temp dont le nom commence par "EUR_" */
/**********************************************************************************************************/
data test116;
set test115;

/*array Numeur EUR_:;

do over Numeur;
Numeur = put(Numeur,best10.);
end;*/

run;

/******************************************************************************************************************/
/* 9. Arrondir les variables de revenu en euro (EUR_HH012 , EUR_HH023, EUR_HH032, EUR_HH095)					  */
/* 																												  */
/*    a. Si l'une de ces variables est dans la table temp, on l'arrondie a deux decimales 						  */
/*    																											  */
/*    b. Si la variable EUR_HH09 existe dans temp, alors on recalcule cette variable comme etant la somme de      */
/*       sa valeur initiale et de la difference entre la somme des valeurs arrondies des variables EUR_HH012,     */
/*       EUR_HH023, EUR_HH032, EUR_HH095 et la somme des valeurs non arrondies des variables EUR_HH012, EUR_HH023 */
/*       EUR_HH032, EUR_HH095																					  */
/******************************************************************************************************************/
%IF %index (&VarsHH.,EUR_HH012) %then %do; /* do numero 23 */
     data test117;
	 set test116;
	 Round_EUR_HH012 = round(EUR_HH012,0.01);
	 run;
%end; /* end numero 23 */

%else %do; /* do numero 24 */
%PUT the Variable EUR_HH012 does not exist in the file &data. for the Country &Country.;
data test117;
set test116;
run;
%end; /* end numero 24 */



%IF %index (&VarsHH.,EUR_HH023) %then %do; /* do numero 25 */
     data test118;
	 set test117;
	 Round_EUR_HH023 = round(EUR_HH023,0.01);
	 run;
%end; /* end numero 25 */

%else %do; /* do numero 26 */
%PUT the Variable EUR_HH023 does not exist in the file &data. for the Country &Country.;
data test118;
set test117;
run;
%end; /* end numero 26 */



%IF %index (&VarsHH.,EUR_HH032) %then %do; /* do numero 27 */
     data test119;
	 set test118;
	 Round_EUR_HH032 = round(EUR_HH032,0.01);
	 run;
%end; /* end numero 27 */

%else %do; /* do numero 28 */
%PUT the Variable EUR_HH032 does not exist in the file &data. for the Country &Country.;
data test119;
set test118;
run;
%end; /* end numero 28 */



%IF %index (&VarsHH.,EUR_HH095) %then %do; /* do numero 29 */
     data test120;
	 set test119;
	 Round_EUR_HH095 = round(EUR_HH095,0.01);
	 run;
%end; /* end numero 29 */

%else %do; /* do numero 30 */
%PUT the Variable EUR_HH095 does not exist in the file &data. for the Country &Country.;
data test120;
set test119;
run;
%end; /* end numero 30 */



%IF %index (&VarsHH.,EUR_HH099) %then %do; /* do numero 31 */
data test121 (drop= Round:);
set test120;
EUR_HH099 = EUR_HH099 + (Round_EUR_HH012 - EUR_HH012) + (Round_EUR_HH023 - EUR_HH023) + (Round_EUR_HH032 - EUR_HH032) + (Round_EUR_HH095 - EUR_HH095);
run;
%end; /* end numero 31 */

%else %do; /* do numero 32 */
%PUT The Variable EUR_HH099 does not exist in the file &data. for the Country &Country.;
data test121 (drop= Round:);
set test120;
run;
%end; /* end numero 32 */

/**********************************************************************************************************************/
/* 10. Si la variable EUR_HE023 est dans la table temp : 															  */
/* 																													  */
/*     a. Si une des observations de temp a une valeur pour la variable EUR_HE023 alors :							  */
/*   																											      */
/*        i. On cree le vecteur delta_eur_he02 egale a l'oppose des valeurs de la colonne eur_he023 de la table temp  */
/* 																													  */
/*        ii. On cree le vecteur delta_eur_he00 egale a l'oppose des valeurs de la colonne eur_he023 de la table temp */
/* 																													  */
/*        iii. On modifie la variable EUR_HE023 en remplacant toutes les valeurs pas NA								  */
/**********************************************************************************************************************/

%IF %index (&VarsHH.,EUR_HE023) %then %do; /* do numero 33 */

data test122 (keep = EUR_HE023 verhe023) ;
set test121;
attrib verhe023 length=$16.;
if EUR_HE023 = . then verhe023 = "problem";
else if EUR_HE023 ne . then verhe023 = "no problem";
run;

proc sql noprint;
select count (verhe023) into:nbpbhe023 from test122 where verhe023 = "no problem";
quit;

%if &nbpbhe023. ne 0 %then %do; /* do numero 34 */

data test123;
set test121;
delta_eur_he02 = 0 - EUR_HE023;
delta_eur_he00 = 0 - EUR_HE023;
EUR_HE023 = . ; /* pas de NA car c'est une variable numerique */
run;

%end; /* end numero 34 */

%else %if &nbpbhe023. eq 0 %then %do; /* do numero 35 */

%PUT All the values for The Variable EUR_HE023 for the Country &Country. for the Data &data. are already empty;

data test123;
set test121;
run;
%end; /* end numero 35 */

%end; /* end numero 33 */

%else %do; /* do numero 36 */

%PUT The variable EUR_HE023 for the Country &Country. for the Data &data. is not present;

data test123;
set test121;
run;

%end; /* end numero 36 */

/********************************************************************************/
/* 11. Si la variable EUR_HE0231 est dans la table temp :                       */
/*        a. Si une des observations de temp a une valeur pour cette variable : */
/*            i. On remplace les valeurs par NA                                 */
/********************************************************************************/
%IF %index (&VarsHH.,EUR_HE0231) %then %do; /* do numero 37 */
data test124 (keep= EUR_HE0231 verhe0231);
set test123;
attrib verhe0231 length=$16.;
if EUR_HE0231 = . then verhe0231 = "problem";
else if EUR_HE0231 ne . then verhe0231 = "no problem";
run;

proc sql noprint;
select count (verhe0231) into:nbpbhe0231 from test124 where verhe0231 = "no problem";
quit;

%if &nbpbhe0231. ne 0 %then %do; /* do numero 38 */
data test125;
set test123;
EUR_HE0231 = . ; /* pas de NA comme c'est une valeur numerique */
run;
%end; /* end numero 38 */

%if &nbpbhe0231. eq 0 %then %do; /* do numero 39 */
%PUT All the values for the variable EUR_HE0231 for data &data. for the Country &Country. are already empty;

data test125;
set test123;
run;

%end; /* end numero 39 */

%end; /* end numero 37 */

%else %do; /* do numero 40 */

%PUT The variable EUR_HE0231 is not present in the data &data. for the Country &Country.;
data test125;
set test123;
run;
%end; /* end numero 40 */

/*************************************************************************************************************************/
/* 12. Si la variable EUR_HE0943 est dans la table temp :																 */
/*   																													 */
/*     a. Si une des observations de temp a une valeur pour cette variable : 											 */
/* 																														 */
/*          i. On cree le vecteur delta_EUR_HE09 egal a l'oppose des valeurs de la colonne EUR_HE0943 de la table temp   */
/* 																														 */
/*          ii. On cree le vecteur delta_EUR_HE094 egal a l'oppose des valeurs de la colonne EUR_HE0943 de la table temp */
/* 																														 */
/*          iii. On soustrait au vecteur delta_EUR_HE00 les valeurs de la colonne EUR_HE0943 de la table temp 			 */
/* 																														 */
/*          iv. On modifie la valeur EUR_HE0943 en remplacant toutes les valeurs par NA 								 */
/*************************************************************************************************************************/
%IF %index (&VarsHH.,EUR_HE0943) %then %do; /* do numero 41 */
data test126 (keep= EUR_HE0943 verhe0943);
set test125;
attrib verhe0943 length=$16.;
if EUR_HE0943 = . then verhe0943 = "problem";
else if EUR_HE0943 ne . then verhe0943 = "no problem";
run;

proc sql noprint;
select count (verhe0943) into:nbpbhe0943 from test126 where verhe0943 = "no problem";
quit;

%IF &nbpbhe0943. ne 0 %then %do; /* do numero 42 */
data test127;
set test125;
delta_EUR_HE09 = 0 - EUR_HE0943;
delta_EUR_HE094 = 0 - EUR_HE0943;
delta_EUR_HE00 = delta_EUR_HE00 - EUR_HE0943;
EUR_HE0943 = . ;
run;
%end; /* end numero 42 */

%else %if &nbpbhe0943. eq 0 %then %do; /* do numero 43 */

%PUT All the values for the variable EUR_HE0943 are already blanked in the File &data. for the Country &Country.;
data test127;
set test125;
run;

%end; /* end numero 43 */

%end; /* end numero 41 */

%else %do; /* do numero 44 */

%PUT The variable EUR_HE0943 is not present in the file &data. for the Country &Country.;

data test127;
set test125;
run;

%end; /* end numero 44 */

/****************************************************************************/
/* 13. Si la variable EUR_HE09431 est dans la table temp : 					*/
/* 																			*/
/*    a. Si une des observations de temp a une valeur pour cette variable : */
/*         i. On remplace les valeurs par NA								*/
/****************************************************************************/
%IF %index (&VarsHH.,EUR_HE09431) %then %do; /* do numero 45 */
data test128 (keep= EUR_HE09431 verhe09431);
set test127;
attrib verhe09431 length=$16.;
if EUR_HE09431 = . then verhe09431 = "problem";
else if EUR_HE09431 ne . then verhe09431 = "no problem";
run;

proc sql noprint;
select count (verhe09431) into:nbpbhe09431 from test128 where verhe09431 = "no problem";
quit;

%if &nbpbhe09431. ne 0 %then %do; /* do numero 46 */
data test129;
set test127;
EUR_HE09431 = . ; /* pas de NA car c'est une variable numerique */
run;
%end; /* end numero 46 */

%else %if &nbpbhe09431. eq 0 %then %do; /* do numero 47 */
%PUT All the values of the variable EUR_HE09431 are blanked for the file &data. for the Country &Country.;
data test129;
set test127;
run;
%end; /* end numero 47 */

%end; /* end numero 45 */

%else %do; /* do numero 48 */

%PUT The variable EUR_HE09431 is not present in the file &data. for the Country &Country.;

data test129;
set test127;
run;

%end; /* end numero 48 */

/******************************************************************************************************************/
/* 14. Si la variable EUR_HE122 est dans la table temp : 														  */
/* 																												  */
/*   a. Si une des observations de temp a une valeur pour cette variable : 										  */
/* 																												  */
/*      i. On cree le vecteur delta_EUR_HE12 egal a l'oppose des valeurs de la colonne EUR_HE122 de la table temp */
/*    																											  */
/*      ii. On soustrait au vecteur delta_EUR_HE00 les valeurs de la colonne EUR_HE122 de la table temp 		  */
/* 																												  */
/*      iii. On modifie la variable EUR_HE122 en remplacant toutes les valeurs par NA 							  */
/******************************************************************************************************************/
%IF %index (&VarsHH.,EUR_HE122) %then %do; /* do numero 49 */

data test130 (keep= EUR_HE122 verhe122);
set test129;
attrib verhe122 length=$16.;
if EUR_HE122 = . then verhe122 = "problem";
else if EUR_HE122 ne . then verhe122 = "no problem";
run;

proc sql noprint;
select count (verhe122) into:nbpbhe122 from test130 where verhe122 = "no problem";
quit;

%if &nbpbhe122. ne 0 %then %do; /* do numero 50 */
data test131;
set test129;
delta_EUR_HE12 = 0 - EUR_HE122;
delta_EUR_HE00 = delta_EUR_HE00 - EUR_HE122;
EUR_HE122 = . ;
run;
%end; /* end numero 50 */

%else %if &nbpbhe122. eq 0 %then %do; /* do numero 51 */

%PUT All the values for the Variable EUR_HE122 are already blanked;

data test131;
set test129;
run;

%end; /* end numero 51 */

%end; /* end numero 49 */

%else %do; /*do numero 52 */
%PUT The variable EUR_HE122 is not present in the file &data. for the Country &Country.;
data test131;
set test129;
run;
%end; /* end numero 52 */

/****************************************************************************/
/* 15. Si la variable EUR_HE1221 est dans la table temp : 					*/
/* 																			*/
/*    a. Si une des observations de temp a une valeur pour cette variable : */
/* 																			*/
/*        i. on remplace les valeurs par NA 								*/
/****************************************************************************/

%IF %index (&VarsHH.,EUR_HE1221) %then %do; /* do numero 53 */
data test132(keep= EUR_HE1221 verhe1221);
set test131;
attrib verhe1221 length=$16.;
if EUR_HE1221 = . then verhe1221 = "problem";
else if EUR_HE1221 ne . then verhe1221 = "no problem";
run;

proc sql noprint;
select count (verhe1221) into:nbpbhe1221 from test131 where verhe1221 = "no problem";
quit;

%if &nbpbhe1221. ne 0 %then %do; /* do numero 54 */
data test133;
set test131;
EUR_HE1221 = . ;
run;
%end; /* end numero 54 */

%if &nbpbhe1221. eq 0 %then %do; /* do numero 55 */
%PUT All the values of the variable EUR_HE1221 are already blanked in the data &data. for the Country &Country.;
data test133;
set test131;
run;
%end; /* end numero 55 */

%end; /* end numero 53*/

%else %do; /* do numero 56 */
%PUT The variable EUR_HE1221 is not present in the data &data. for the Country &Country.;
data test133;
set test131;
run;
%end; /* end numero 56 */

/********************************************************************************/
/* 16. Si la variable EUR_HE12211 est dans la table temp : 						*/
/*     																			*/
/*       a. Si une des observations de temp a une valeur pour cette variable :  */
/*         																		*/
/*          i. On remplace les valeurs par NA 									*/
/********************************************************************************/
%IF %index (&VarsHH.,EUR_HE12211) %then %do; /* do numero 57 */
data test134 (keep= EUR_HE12211 verhe12211);
set test133;
attrib verhe12211 length = $16.;
if EUR_HE12211 = . then verhe12211 = "problem";
else if EUR_HE12211 ne . then verhe12211 = "no problem";
run;

proc sql noprint;
select count (verhe12211) into:nbpbhe12211 from test134 where verhe1221 = "no problem";
quit;

%if &nbpbhe12211. ne 0 %then %do; /* do numero 58 */
data test135;
set test133;
EUR_HE12211 = . ;
run;
%end; /* end numero 58*/

%if &nbpbhe12211. eq 0 %then %do; /* do numero 59 */
%PUT All the values for the variable EUR_HE12211 for the data &data. for the country &country. are already blanked;
data test135;
set test133;
run;
%end; /* end numero 59 */

%end; /* end numero 57 */

%else %do; /* do numero 60 */
%PUT The variable EUR_HE12211 is not present in the data &data. for the Country &Country. ;
data test135;
set test133;
run;
%end; /* end numero 60 */

/********************************************************************************/
/* 17. Si la variable EUR_HE00 est dans la table temp :							*/
/*																				*/
/*     a. Alors on ajoute a ses valeurs , les valeurs du vecteur delta_EUR_HE00 */
/********************************************************************************/
%IF %index (&VarsHH.,EUR_HE00) %then %do; /* do numero 61 */
data test136;
set test135;
EUR_HE00 = EUR_HE00 + delta_eur_he00;
run;
%end; /* end numero 61 */

%else %do; /* do numero 62 */
%PUT The variable EUR_HE00 is not present in the file &data. for the Country &Country.;
data test136;
set test135;
run;
%end; /* end numero 62 */

/******************************************************************************/
/* 18. Si la variable EUR_HE02 est dans la table temp : 					  */
/* 																			  */
/*    a. Alors on ajoute a ses valeurs, les valeurs du vecteur delta_EUR_HE02 */
/******************************************************************************/
%IF %index (&VarsHH.,EUR_HE02) %then %do; /* do numero 62_bis */
data test137;
set test136;
EUR_HE02 = EUR_HE02 + delta_EUR_HE02;
run;
%end; /* end numero 62_bis */

%else %do; /* do numero 63 */
%PUT The variable EUR_HE02 is not present in the file &data. for the Country &Country.;
data test137;
set test136;
run;
%end; /* end numero 63 */

/******************************************************************************/
/* 19. Si la variable EUR_HE09 est dans la table temp: 						  */
/* 																			  */
/*    a. Alors on ajoute a ses valeurs, les valeurs du vecteur delta_EUR_HE09 */
/******************************************************************************/
%IF %index (&VarsHH.,EUR_HE09) %then %do; /* do numero 64 */
data test138;
set test137;
EUR_HE09 = EUR_HE09 + delta_EUR_HE09;
run;
%end; /* end numero 64 */

%else %do; /* do numero 65 */
%PUT The variable EUR_HE09 is not present in the file &data. for the Country &Country.;
data test138;
set test137;
run;
%end; /* end numero 65 */

/******************************************************************************/
/* 20. Si la variable EUR_HE94 est dans la table temp: 						  */
/* 																			  */
/*    a. Alors on ajoute a ses valeurs, les valeurs du vecteur delta_EUR_HE94 */
/******************************************************************************/
%IF %index (&VarsHH.,EUR_HE94) %then %do; /* do numero 66 */
data test139;
set test138;
EUR_HE94 = EUR_HE94 + delta_EUR_HE94;
run;
%end; /* end numero 66 */

%else %do; /* do numero 67 */
%PUT The variable EUR_HE94 is not present in the file &data. for the Country &Country.;
data test139;
set test138;
run;
%end; /* end numero 67 */

/******************************************************************************/
/* 21. Si la variable EUR_HE12 est dans la table temp: 						  */
/* 																			  */
/*    a. Alors on ajoute a ses valeurs, les valeurs du vecteur delta_EUR_HE12 */
/******************************************************************************/
%IF %index (&VarsHH.,EUR_HE12) %then %do; /* do numero 68 */
data test140;
set test139;
EUR_HE12 = EUR_HE12 + delta_EUR_HE12;
run;
%end; /* end numero 68 */


%else %do; /* do numero 69 */
%PUT The variable EUR_HE12 is not present in the file &data. for the Country &Country.;
data test140;
set test139;
run;
%end; /* end numero 69 */

/**********************************************************************************************************/
/* 22. On arrondi toutes les variables numeriques a une seule decimale  a l'exception de la variable ha10 */
/**********************************************************************************************************/
proc contents data=test140 out=test141 noprint;
run;

proc sql noprint;
select distinct NAME into:Numvartemp separated by ' ' from test141 where length=8 and Name ne "HA10";
quit;

data test142;
set test140;
array varnum &Numvartemp.;
do over varnum; /* do numero 70 */
Varnum = round(Varnum,0.1);
end; /* end numero 70 */
run;

/***********************************************************************************************/
/* 23. Si elles existent dans temp, on remplace les valeurs des variables ha06 et ha07 par NA. */
/*     On renomme ces variables ha06.suppressed et ha07.suppressed                             */
/***********************************************************************************************/
%IF %index (&VarsHH.,HA06) %then %do; /* do numero 71 */
data test143 (rename=(HA06 = HA06_suppressed));
set test142;
HA06 = . ; /* c'est une variable numerique donc pas de NA*/
run;
%end; /* end numero 71 */

%else %do; /* do numero 72 */
%PUT The variable HA06 does not exist in the file &data. for the Country &Country. ;
data test143;
set test142;
run;
%end; /* end numero 72 */

%IF %index (&VarsHH.,HA07) %then %do; /* do numero 73 */
data test144_&data._&Country. (rename= (HA07 = HA07_suppressed));
set test143;
HA07 = . ; /* c'est une variable numerique donc pas de NA*/
run;
%end; /* end numero 73 */

%else %do; /* do numero 74 */
%PUT The variable HA07 does not exist in the file &data. for the Country &Country. ;
data test144_&data._&Country.;
set test143;
run;
%end; /* end numero 74 */

/**********************************************************************************/
/* 24. On enregistre la table temp par pays sous le nom : MFR/codepays_MFR_hh.txt */
/**********************************************************************************/
proc export data=test144_&data._&Country.
            outfile= "&path_MFR4./&Country._MFR_&data..txt"
			dbms = tab replace;
			delimiter = "," ;
			putnames = yes;
run;

/*****************************************/
/* Suppression des tables intermediaires */
/*****************************************/
proc datasets lib=work nolist;
delete temp temp1 iso HH_&Country._at_risk tmpcob_&data._&Country. tmpcoc_&data._&Country. tmpcor_&data._&Country. test101 - test143;
run;

%mend R4_Step1;


/************************************/
/* Pour chaque pays dans une boucle */
/************************************/

/*****************************************************************************************************************************************************************************************************************************************************************************************************************************/
/* The objectives of the macro "R4_Step2" is the creation of multiple variables when it is possible for the data HM for a country given : &NUTS1. , &AGE._Recoded_5Classes , &AGE._Recoded_5YearsClasses, &COB._Recoded_3Categ, &COC._Recoded_3Categ, &COR._Recoded_3Categ,&MSTAT._Recoded_3Categ, &ISCO08._Recoded,HA04rand */
/*****************************************************************************************************************************************************************************************************************************************************************************************************************************/

%Macro R4_Step2 (data,Country,HIDHM);

/**********************************************************************/
/* Recodage du fichier hm (s'il existe, sinon, on passe à la suite) : */
/**********************************************************************/
%if %sysfunc(fileexist("&anon_root./1_EE/&data._&Country..sas7bdat")) %then %do; /* do numero 1 = si la SAS table HM_EE existe */

/***************************************************************************/
/* 1. On crée la table temp comprenant les données de la table hm.csv pour */ 
/* le pays concernés par l'itération de la boucle (une par pays).          */
/***************************************************************************/
data temp;
set "&anon_root./1_EE/&data._&Country..sas7bdat";
run;

/* 2)on cree le vecteur vars.hm reprenant le nom des colonnes de temp */
proc contents data=Temp out=temp1 noprint; 
run;

proc sql noprint; 
select distinct (NAME) into:VarsHM separated by ' ' from temp1 ; 
quit;

/**********************************************************************************/
/* 3) On defini la variable nuts1                                                 */
/* a) si la variable comprise dans le parametre NUTS2 fait partie de la table     */
/* temp 																		  */
/* i. Dans la table temp, on cree la variable nuts1 qui est determine sur la base */
/* de la variable comprise dans le parametre NUTS2.                               */
/* Les valeurs de la variable nuts1 correspondent qux trois premiers caracteres   */
/* des chaines de caractere de la variable comprise dans le parametre NUTS2       */
/* on place cette nouvelle variable a cote de la variable comprise dans           */
/* le parametre NUTS2 et on replace le nom de cette derniere par son nom initial  */
/* auquel on concatene "_suppressed"                                              */
/* (dans notre simulation ca donne "ha08_suppressed")                             */
/**********************************************************************************/
%if %index (&VarsHM.,&NUTS2.) %then %do; /* do numero 3 */

data test101 (rename=(&NUTS2. = &NUTS2._suppressed));
retain NUTS1 &NUTS2.;
set temp;
NUTS1 = substr(&NUTS2.,1,3);
run;

%end; /* end numero 3 */

%else %do; /* do numero 4 */
%PUT The variable &NUTS2. does not exist in the file &data. for the Country &Country. ;
data test101;
set temp;
run;
%end; /* end numero 4 */

/********************************************************************************/
/* 4) on recode les ages annuels                                                */
/* a) Si la variable comprise dans le parametre AGE est comprise dans la        */
/* table temp                                                                   */
/* i. Dans la table temp, on cree la variable AGE_Recoded_5Classes que l'on     */ 
/* place directement apres la variable comprise dans AGE.                       */
/* Cette variable est egale  a "00_14" "15_29" "30_44" "45_59" "60_Inf"         */ 
/* en fonction de l'age de l'observation                                        */
/* ii. Attention, dans le nom de la variable, AGE doit etre remplace par le nom */ 
/*  de la variable enregistree dans ce parametre.                               */
/* Dans notre simulation cela donne mb03_recoded_5classes                       */
/* iii. Dans la table temp, on cree la variable AGE_Recoded_5YearsClasses.      */
/* Cette variable repartit les ages en fonction de tranche                      */
/* d'age de 5 ans : "0_4" "5_9" "10_14" "15_19".... "80_84" "85_inf".           */
/* Attention, dans le nom de la variable, AGE doit etre remplace                */
/* par le nom de la variable enregistree dans ce parametre.                     */
/* Dans notre simulation cela donne mb03_Recoded_5Classes                       */
/* et mb03_Recoded_5yearsClasses                                                */
/********************************************************************************/

%if %index (&VarsHM.,&AGE.) %then %do; /* do numero 5 = Si la variable comprise dans le parametre AGE est comprise dans la table temp */

data test102 (drop= &AGE._v2);
retain &AGE._Recoded_5Classes &AGE._Recoded_5YearsClasses;
set test101;

&AGE._v2 = input(&AGE.,best3.);

if &AGE._v2 >= 60 then &AGE._Recoded_5Classes = "60_Inf";
if 0 < = &AGE._v2 <= 14 then &AGE._Recoded_5Classes = "0_14";
if 15 < = &AGE._v2 <= 29 then &AGE._Recoded_5Classes = "15_29";
if 30 < = &AGE._v2 <= 44 then &AGE._Recoded_5Classes = "30_44";
if 45 < = &AGE._v2 <= 59 then &AGE._Recoded_5Classes = "45_59";

if &AGE._v2 >= 85 then &AGE._Recoded_5YearsClasses = "85_Inf";
if 0 < = &AGE._v2 <= 4 then &AGE._Recoded_5YearsClasses = "0_4";
if 5 < = &AGE._v2 <= 9 then &AGE._Recoded_5YearsClasses = "5_9";
if 10 < = &AGE._v2 <= 14 then &AGE._Recoded_5YearsClasses = "10_14";
if 15 < = &AGE._v2 <= 19 then &AGE._Recoded_5YearsClasses = "15_19";
if 20 < = &AGE._v2 <= 24 then &AGE._Recoded_5YearsClasses = "20_24";
if 25 < = &AGE._v2 <= 29 then &AGE._Recoded_5YearsClasses = "25_29";
if 30 < = &AGE._v2 <= 34 then &AGE._Recoded_5YearsClasses = "30_34";
if 35 < = &AGE._v2 <= 39 then &AGE._Recoded_5YearsClasses = "35_39";
if 40 < = &AGE._v2 <= 44 then &AGE._Recoded_5YearsClasses = "40_44";
if 45 < = &AGE._v2 <= 49 then &AGE._Recoded_5YearsClasses = "45_49";
if 50 < = &AGE._v2 <= 54 then &AGE._Recoded_5YearsClasses = "50_54";
if 55 < = &AGE._v2 <= 59 then &AGE._Recoded_5YearsClasses = "55_59";
if 60 < = &AGE._v2 <= 64 then &AGE._Recoded_5YearsClasses = "60_64";
if 65 < = &AGE._v2 <= 69 then &AGE._Recoded_5YearsClasses = "65_69";
if 70 < = &AGE._v2 <= 74 then &AGE._Recoded_5YearsClasses = "70_74";
if 75 < = &AGE._v2 <= 79 then &AGE._Recoded_5YearsClasses = "75_79";
if 80 < = &AGE._v2 <= 84 then &AGE._Recoded_5YearsClasses = "80_84";
run;

/*************************************************************/
/* iv. Ensuite, on essaye d'ouvrir le fichier sous le nom :  */
/* "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt", */ 
/* si il existe on nomme cette table hh_at_risk              */
/*************************************************************/
%if %sysfunc(fileexist("&path_contvarsoutput./&Country._spont_t1000_s1_hh_at_risk.txt")) %then %do; /* do numero 6 = si le fichier sous le nom "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" existe */

data HH_at_risk;
Length F1 $16.;
Format F1 $16.;
Informat F1 $16.;
infile "&path_contvarsoutput./&Country._spont_t1000_s1_hh_at_risk.txt"

LRECL = 16
ENCODING = "WLATIN1"
TERMSTR = CRLF
DLM = '7F'x
MISSOVER
DSD;

INPUT F1 : $16. ;

run;

/**********************************************************************************/
/* v. Si ce fichier existe, on repere les observations de temp pour lesquelles la */ 
/* valeur de la variable comprise dans HID existe dans la table hh.at.risk        */
/*Pour ces observations , la valeur reprise dans la classe d'age                  */
/* AGE_Recoded_5YearsClasses est effacee et remplacee par NA                      */
/* vi. La variable comprise dans le parametre AGE est renommee AGE_suppressed     */
/*(avec AGE qui doit etre remplace par le nom de la variable enregistree dans le  */ 
/* parametre AGE)                                                                 */
/* et les valeurs de cette colonne sont toutes remplacees par NA                  */
/**********************************************************************************/
proc sql noprint;
create table test103 as
select a.* , b.*
from test102 as a
left join HH_at_risk as b
on (a.&HIDHM. = b.F1)
order by a.&HIDHM.;
quit;

data test104 (rename=(&AGE. = &AGE._suppressed) drop=F1);
set test103;
if &HIDHM. = F1 then &AGE._Recoded_5YearsClasses = "NA";
&AGE. = "NA";
run;
%end; /* end numero 6 = si le fichier sous le nom "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" existe */

%else %do; /* do numero 7 = si le fichier sous le nom "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" n'existe pas */
%PUT the text file HH_at_risk does not exist;
data test104;
set test102;
run;
%end; /* end numero 7 = si le fichier sous le nom "ContVarsOutput/(codepays)_spont_t100_s1_hh_at_risk.txt" n'existe pas */

%end; /* end numero 5 = Si la variable comprise dans le parametre AGE est comprise dans la table temp */

%else %do; /* do numero 8 = Si la variable comprise dans le parametre AGE n'est pas comprise dans la table temp */
%PUT The variable &AGE. does not exist in the file &data. for the Country &Country. ;
data test104;
set test101;
run;
%end; /* end numero 8 = Si la variable comprise dans le parametre AGE n'est pas comprise dans la table temp */


/****************************************************************************/
/* 5. Recodage des codes pays pour suivre la classification ISO3166 alpha-2 */
/****************************************************************************/

/*******************************************************************************/
/* a. Importer la table EU2015-ISOalpha2.txt. C'est une table qui contient les */
/* codes deux digits des pays d'europe. On apelle cette table iso (attention a */
/* updater cette  liste en fonction des pays europeens                         */
/*******************************************************************************/
data iso (rename = (F1 = Countries));
length F1 $2.;
Format F1 $2.;
Informat F1 $2.;
infile &path_iso.;
input F1 : $2.;
run;

/**************************************************************************/
/* b. si la variable commprise dans le parametre COB est une variable     */
/* de la table temp:												      */
/* i. On cree tmp, une sous table de temp ne comprenant que les variables */ 
/* comprises dans le parametre COB                                        */
/**************************************************************************/
%IF %index (&VarsHM.,&COB.) %then %do; /* do numero 9 = si la variable commprise dans le parametre COB est une variable de la table temp */

data tmpcob(keep= &COB.);
set test104;
run;

proc sort data=tmpcob out=test105 nodupkey;
by &COB.;
run;

data test106;
set test105;
attrib variable6 length=$16.;
var1 = "10";
var2 = "21";
var3 = "22";
var4 = "2X";
var5 = "99";
if not(&COB. = var1 or &COB. = var2 or &COB. = var3 or &COB. = var4 or &COB. = var5) then variable6 = "problem";
else if (&COB. = var1 or &COB. = var2 or &COB. = var3 or &COB. = var4 or &COB. = var5) then variable6 = "no problem";
run;

proc sql noprint;
select count (variable6) into:nbpbcob from test106 where variable6 = "problem" ;
quit;

/**************************************************************************************/
/* ii. Si au moins une des valeurs de tmp n'est pas egale a une des valeurs suivantes */ 
/* "10" "21" "22" "2X" "99" alors : 												  */
/* 1. on ajoute a temp la variable COB_Recoded_3Categ                                 */
/* (où COB est remplace par la variable qui est enregistre dans le parametre COB)     */
/* 2. Si la variable comprise dans COB prends le code du pays concerne par            */
/* l'iteration dans la table temp alors la nouvelle variable vaut "10".               */
/* 3. Si elle est differente du pays concerne par l'iteration mais concerne un        */
/* pays repris dans la liste ISO, alors la nouvelle variable vaut "21" 				  */
/* 4. Dans tous les autres cas, elle vaut "22" 									      */
/* 5. Dans la table temp, on renomme la variable reprise dans COB,                    */
/* COB_suppressed (dans notre cas mb01_suppressed)                                    */
/* 6. pour info, 10= national , 21= non national mais EU, 22 = non national et non EU */
/**************************************************************************************/
%IF &nbpbcob. ne 0 %then %do; /* do numero 11 */
data test107 (rename=(&COB. = &COB._suppressed));
set test104;
if &COB. = COUNTRY then &COB._Recoded_3Categ = "10";
if &COB. ne COUNTRY and &COB. in (&Country_isoalpha2.) then &COB._Recoded_3Categ = "21";
if &COB. ne COUNTRY and &COB. not in (&Country_isoalpha2.) then &COB._Recoded_3Categ = "22";
run;
%end; /* end numero 11 */

%else %IF &nbpbcob. eq 0 %then %do; /* do numero 12 */
%PUT All the values of the Variable &COB. in the file &data. for the Country &Country. are valid;
data test107;
set test104;
run;
%end; /* end numero 12 */

%end; /* end numero 9 = si la variable comprise dans le parametre COB est une variable de la table temp */

%else %do; /* do numero 10 = si la variable comprise dans le parametre COB n'est pas une variable de la table temp */
%PUT The variable &COB. is not in the file &data. for the Country &Country.;
data test107;
set test104;
run;
%end; /* do numero 10 = si la variable comprise dans le parametre COB n'est pas une variable de la table temp */

/*********************************************************************************/
/* iii. on fait exactement le meme travail pour les parametres COC et COR qui    */
/* concerne respectivement le pays de mationalite (country of citizenship) et    */ 
/* le pays de residence. COB concernait le pays de naissance (Country of Birth). */
/*********************************************************************************/

/*************************/
/* pour le parametre COC */
/*************************/
%IF %index (&VarsHM.,&COC.) %then %do; /* do numero 13 */

data tmpcoc (keep= &COC.);
set test107;
run;

proc sort data=tmpcoc out=test108 nodupkey;
by &COC.;
run;

data test109;
set test108;
attrib variable6 length=$16.;
var1 = "10";
var2 = "21";
var3 = "22";
var4 = "2X";
var5 = "99";
if not(&COC. = var1 or &COC. = var2 or &COC. = var3 or &COC. = var4 or &COC. = var5) then variable6 = "problem";
else if (&COC. = var1 or &COC. = var2 or &COC. = var3 or &COC. = var4 or &COC. = var5) then variable6 = "no problem";
run;

proc sql noprint;
select count (variable6) into:nbpbcoc from test109 where variable6 = "problem" ;
quit;

%IF &nbpbcoc. ne 0 %then %do; /* do numero 15 */
data test110 (rename=(&COC. = &COC._suppressed));
set test107;
if &COC. = COUNTRY then &COC._Recoded_3Categ = "10";
if &COC. ne COUNTRY and &COC. in (&Country_isoalpha2.) then &COC._Recoded_3Categ = "21";
if &COC. ne COUNTRY and &COC. not in (&Country_isoalpha2.) then &COC._Recoded_3Categ = "22";
run;
%end; /* end numero 15 */

%else %IF &nbpbcoc. eq 0 %then %do; /* do numero 16 */
%PUT All the values of the Variable &COC. in the file &data. for the Country &Country. are valid;
data test110;
set test107;
run;
%end; /* end numero 16 */

%end; /* end numero 13 */

%else %do; /* do numero 12 */
%PUT The variable &COC. is not in the file &data. for the Country &Country.;
data test110;
set test107;
run;
%end; /* end numero 12 */

/*************************/
/* pour le parametre COR */
/*************************/
%IF %index (&VarsHM.,&COR.) %then %do; /* do numero 17 */
data tmpcor (keep= &COR.);
set test110;
run;

proc sort data=tmpcor out=test111 nodupkey;
by &COR.;
run;

data test112;
set test111;
attrib variable6 length=$16.;
var1 = "10";
var2 = "21";
var3 = "22";
var4 = "2X";
var5 = "99";
if not(&COR. = var1 or &COR. = var2 or &COR. = var3 or &COR. = var4 or &COR. = var5) then variable6 = "problem";
else if (&COR. = var1 or &COR. = var2 or &COR. = var3 or &COR. = var4 or &COR. = var5) then variable6 = "no problem";
run;

proc sql noprint;
select count (variable6) into:nbpbcor from test112 where variable6 = "problem" ;
quit;

%IF &nbpbcor. ne 0 %then %do; /* do numero 19 */
data test113 (rename=(&COR. = &COR._suppressed));
set test110;
if &COR. = COUNTRY then &COR._Recoded_3Categ = "10";
if &COR. ne COUNTRY and &COR. in (&Country_isoalpha2.) then &COR._Recoded_3Categ = "21";
if &COr. ne COUNTRY and &COR. not in (&Country_isoalpha2.) then &COR._Recoded_3Categ = "22";
run;
%end; /* end numero 19 */

%else %IF &nbpbcor. eq 0 %then %do; /* do numero 20 */
%PUT All the values of the Variable &COR. in the file &data. for the Country &Country. are valid;
data test113;
set test110;
run;
%end; /* end numero 20 */

%end; /* end numero 17 */

%else %do; /* do numero 18 */
%PUT The variable &COR. is not in the file &data. for the Country &Country.;
data test113;
set test110;
run;
%end; /* end numero 18 */

/***************************************************************************************************************************/
/* 6. Recoder pour le statut matrimonial (variable enregistree dans le parametre MSTAT)                                    */
/*     a. Si la variable comprise dans MSTAT existe aussi dans temp :													   */
/*																														   */
/*          i. Dans la table temp, on cree la variable MSTAT_Recoded_3Categ (MSTAT est a remplacer par la variable qui     */
/*             est dans ce parametre, par exemple MB04_Recoded_3Categ)													   */
/*																														   */
/*          ii. Si la valeur de la variable enregistree dans MSTAT dans la table temp est egale a 4, alors on change et    */
/*              on lui donne la valeur 3. Sinon on ne change rien.														   */
/*																														   */
/*          iii. Dans la table temp, on renomme la variable comprise dans MSTAT pour l'appeler MSTAT_suppressed (MSTAT est */
/*               a remplacer par la variable). On remplace toutes les valeurs de cette variable par NA                     */
/***************************************************************************************************************************/

%IF %index (&VarsHM.,&MSTAT.) %then %do; /* do numero 21 */

         data test114 (drop=&MSTAT. rename=(&MSTAT._v2 = &MSTAT._suppressed));
		 set test113;

		 attrib &MSTAT._v2 length= $2. format= $2.;

		 if &MSTAT. = "4" then &MSTAT._Recoded_3Categ = "3";
		 else if &MSTAT. ne "4" then &MSTAT._Recoded_3Categ = &MSTAT.;
		 &MSTAT._v2 = &MSTAT.;
         &MSTAT._v2 = "NA";

		 run;

%end; /* end numero 21 */


%else %do; /* do numero 22 */
%PUT The variable &MSTAT. does not exist in the file &data. for the Country &Country.;
data test114;
set test113;
run;

%end; /* end numero 22 */

/******************************************************************************************************************************************************************************************************************************************************************************************/
/* 6.	Recoder la variable statut d'occupation : paramÃ¨tre ISCO08 (qui comprend la variable me0908 dans la simulation).																																								  */
/*       a. Si la variable compris dans ISCO08 est aussi une variable de la table temp :																																															      */
/*             i.	Dans la table temp, on crÃ©e la colonne ISCO_Recoded (dans notre simulation Ã§a donnera me0908_Recoded).																																							      */
/*             ii. Si les deux premiers caractÃ¨res de la valeur de la variable comprise dans ISCO08 dans la table temp sont "Z1", "Z2" ou "Z3", alors on recode "AF". Si ce sont "11", "12", "13" ou "14", on recode "LM". Sinon, on laisse la mÃªme valeur que dans la variable initiale. */
/*             iii.	On renomme la variable initiale ISCO08.suppressed (me0908.suppressed) et on remplace ses valeurs par NA.																																							  */
/******************************************************************************************************************************************************************************************************************************************************************************************/
%IF %index (&VarsHM.,&ISCO08.) %then %do; /* do numero 23 */
data test115 (rename=(&ISCO08. = &ISCO08._suppressed));
set test114;
if substr(&ISCO08.,1,2) in ("Z1" "Z2" "Z3") then &ISCO08._Recoded = "AF";
else if substr(&ISCO08.,1,2) in ("11" "12" "13" "14") then &ISCO08._Recoded = "LM";
else if substr(&ISCO08.,1,2) not in ("Z1" "Z2" "Z3" "11" "12" "13" "14") then &ISCO08._Recoded = &ISCO08.;
&ISCO08. = "NA";
run;
%end; /* end numero 23 */

%else %do; /* do numero 24 */
%PUT The variable &ISCO08. does not exist in the file &data. for the Country &Country.;
data test115;
set test114;
run;
%end; /* end numero 24 */

/**********************************************************************************/
/* 7.	On transforme les variables contenant les caractères "eur_" dans leur nom */ 
/* en variable numérique.														  */
/**********************************************************************************/
data test116;
set test115;
run;

/*************************************************************************************/
/* 8. Si elle existe dans la table temp, on arrondi la variable eur_mf099 à l'unité. */
/*************************************************************************************/
%IF %index (&VarsHM.,EUR_MF099) %then %do; /* do numero 25 */
data test117(drop= EUR_MF099 rename=(EUR_MF099_bis = EUR_MF099));
set test116;
EUR_MF099_bis = round(EUR_MF099,1);
run;
%end; /* end numero 25 */

%else %do; /* do numero 26 */
%PUT The variable EUR_MF099 is not present in the file &data. for the country &Country. ;
data test117;
set test116;
run;
%end; /* end numero 26 */

/************************************************************************************************/
/* 9. On enregistre la table temp dans le fichier MFR/codepays_MFR_HM.txt  (MFR/BE_MFR_hm.txt). */
/************************************************************************************************/
proc export data=test117
            outfile= "&path_MFR4./&Country._MFR_&data..txt"
			dbms = tab replace;
			delimiter = "," ;
			putnames = yes;
run;

/*****************************************/
/* suppression des tables intermediaires */
/*****************************************/
proc datasets lib=work nolist;
delete temp temp1 test101 - test116 
       HH_at_risk iso tmpcob tmpcoc tmpcor;
run;

%end; /* end numero 1 = si la SAS table HM_EE existe */

%else %do; /* do numero 2 = si la SAS table HM_EE n'existe pas */
%PUT The file &data. is not present for the Country &Country.;
%end; /* end numero 2 = si la SAS table HM_EE n'existe pas*/

%mend R4_Step2;


/*********************************/
/* Randomisation de HA04 et MA04 */
/*********************************/

/**********************************************************************************/
/* The objective of the Macro R4_Step3 is to export The files HH and HM for every */ 
/* country after the creation of the different variables                          */
/**********************************************************************************/

/********************************************************************************/
/* 1.Par pays, on ouvre les fichiers MFR/BE_MFR_hm.txt et MFR/BE_MFR_hh.txt que */
/* l'on nomme respectivement MFR.hm et MFR.hh.                                  */
/********************************************************************************/
%Macro R4_step3 (Country,data1,data2);

/* pour HH */
proc import datafile ="&path_MFR4./&Country._MFR_&data1..txt"
            out=MFR_&data1.
            dbms=dlm replace;
            delimiter=',';
            getnames=yes;
run;

/* pour HM */
proc import datafile ="&path_MFR4./&Country._MFR_&data2..txt"
            out=MFR_&data2.
            dbms=dlm replace;
            delimiter=',';
            getnames=yes;
run;


/***************************************************************************************/
/* 2.	Dans MFR.hh, on ajouter une colonne que l'on nomme ha04rand                    */
/* et qui reprend les mÃªmes valeurs que la variable ha04 mais dans un ordre randomisÃ©. */
/* On garde la colonne ha04 initiale. 												   */
/***************************************************************************************/
proc sql;
   create table randha04_&Country. as
   select ha04 
   from MFR_&data1. 
   order by rand('uniform');
quit;

data randha04_&Country._v2 (rename=(ha04 = ha04rand));
set randha04_&Country.;
run; 

data &Country._MFR_&data1._v2;
merge MFR_&data1. randha04_&Country._v2;
run;

/**************************************************************************************/
/* 3. On merge ensuite la table MFR.hm à une sous-table de MFR.hh composée uniquement */ 
/* des colonnes ha04 et ha04rand avec comme clé de fusion ma04 pour MFR.hm et ha04    */ 
/* pour la sous-table de MFR.hh.                                                      */
/**************************************************************************************/
proc sql noprint;
create table &Country._MFR_&data2._v2 as
select a.*, b.ha04, b.ha04rand
from MFR_&data2. as a
left join &Country._MFR_&data1._v2 as b
on (a.ma04 = b.ha04);
quit;

/*********************************************************************************************************/
/* 4.	Dans MFR.hm, on nomme ma04keep la variable anciennement nommÃ©e ma04 et on nomme ma04 la variable */ 
/* anciennement nommÃ©e ha04rand. 																		 */
/*********************************************************************************************************/
data &Country._MFR_&data2._v3 (rename=(ma04 = ma04keep   ha04rand = ma04));
set &Country._MFR_&data2._v2;
run;

/*******************************************************************************/
/* 5.	On sauve ces deux tables MFR.hm et MFR.hh dans des fichiers initiaux : */
/* a.	 MFR/BE_MFR_hm.txt													   */
/* b.	MFR/BE_MFR_hh.txt													   */
/*******************************************************************************/

/* pour HH */
proc export data=&Country._MFR_&data1._v2
            outfile= "&path_MFR4./&Country._MFR_&data1..txt"
			dbms = tab replace;
			delimiter = "," ;
			putnames = yes;
run;

/* pour HM */
proc export data=&Country._MFR_&data2._v3
            outfile= "&path_MFR4./&Country._MFR_&data2..txt"
			dbms = tab replace;
			delimiter = "," ;
			putnames = yes;
run;

/********************************************/
/* 6. Suppression des tables intermédiaires */
/********************************************/
proc datasets lib=work nolist;
delete MFR_&data1. MFR_&data2. randha04_&Country. randha04_&Country._v2 
        &Country._MFR_&data2._v2;
run;

%mend R4_step3;