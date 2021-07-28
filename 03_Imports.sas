/********************************************************************************************************************************************************************/
/*                                                                   Imports                                                                                        */
/*                                                                                                                                                                  */         
/*                             In that program "Imports" we import the csv files "HH" and "HM" for a given country and the txt file "RecordLayout"                  */
/********************************************************************************************************************************************************************/

/*******************************************************/
/* Import of the HH file for the corresponding country */
/*******************************************************/
data HH_&Country_imported.; /* creation of a dataset "HH_&Country_imported." */
set donnees.HH_&Country_imported.; /* from that SAS dataset located at that path....donnes is a libname which is created in the "Parameters" program*/
run;

/*******************************************************/
/* Import of the HM file for the corresponding country */
/*******************************************************/
data HM_&Country_imported.; /* creation of a dataset "HM_&Country_imported." */
set donnees.HM_&Country_imported.; /* from that SAS dataset located at that path....donnes is a libname which is created in the "Parameters" program*/
run;



/******************************/
/* Import of the RecordLayout */
/******************************/
Data RecordLayout;
set inputRL.RecordLayout;
run;


data RecordLayout;
set RecordLayout; /* Here from the dataset "RecordLayout that we create previously */
where substr(Variable,1,3) not in ("NAC" "PPS") and substr(Variable,1,2) ne "HE"; /* we want the records where the first 3 elements of the variable "Variable" are not equal to "NAC" and "PPS" and where the first 2 elemets of the variable "Variable" are not equal to "HE" */
run;