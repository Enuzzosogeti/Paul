/*
MODIFICATION:
20210312: gryseol: (add semicolon) replace %let expression_4 = &expression_4. &sep. t1.&key_val. = t2.&key_val. by %let expression_4 = &expression_4. &sep. t1.&key_val. = t2.&key_val.;

*/
%Macro ScenarioB(key,weight,HMID,scenario);

/*********************************************************************************/
/* On ne conserve dans key que les éléments qui sont le nom d'une colonne de dd. */
/*********************************************************************************/
data Key_&Country_imported.  (keep= &key.);
set &Country_imported._AfterRecodings;
run;

proc contents data=Key_&Country_imported.  
              out=Key_&Country_imported._Content; 
run;

proc sql;
select distinct NAME into:key separated by ' '  /* je conserve dans le macro-parametre &key. uniquement les variables qui sont le nom d'une colonne de dd */
from Key_&Country_imported._Content;
quit;



/***********************************************************************************************************************/
/* Preparation of the arguments for the function BFP [ Risk Measures according to Benedetti-Franconi-Polettini method] */
/* rr est une sous table de dtemp ne contenant que les variables listées dans key 									   */
/***********************************************************************************************************************/
data rr_&Country_imported. (keep= &key.);
set &Country_imported._AfterRecodings;
run;

/*************************************************************************************/
/* ww est une sous table de dtemp ne contenant que les variables listées dans WEIGHT */
/* ww=dtemp[,WEIGHT]                                                                 */
/*************************************************************************************/
data ww_&Country_imported. (keep=&weight.);
set &Country_imported._AfterRecodings;
run;

/*********************************************************/
/* temp est une table résultant de la fusion de rr et ww */
/* temp=data.frame(rr,ww)                                */
/*********************************************************/
data temp_&Country_imported.;
merge rr_&Country_imported. ww_&Country_imported.;
run;


/************************************************************************************************************************************/
/* Call the function BFP to compute the individual risk                       													    */
/* FONCTION BFP. Elle est très longue, je te la décris étape par étape:                                                             */
/* 1. Application de la fonction d'aggrégation des catégories avec Missing data                                                     */
/* 1.1. Pour l'ensemble des variables listées dans key on calcul la fréquence de chacune des combinaisons de ces variables          */
/* 1.2. Si il existe une variable de pondération (ww), on calcul la fréquence pondérée de chacune des combinaisons de ces variables */
/* 1.3. Si une observation/ligne contient une valeur manquante à une ou plusieurs variables,                                        */
/* il faut considérer toutes les possibilités de remplacement de la valeur manquante.                                               */
/* La méthode est bien expliquée dans le document "Documentation freqcalc" dans la section 4. frequencies calculation               */
/* 1.4 Il ressort de cette fonction une table de deux colonnes,                                                                     */
/* la première "fk" avec les fréquences simples de chaque combinaison de catégories de variables                                    */
/* la seconde "Fk" avec les fréquences pondérées de chaque combinaison de catégories de variables                                   */
/************************************************************************************************************************************/

/******************************************************************************/
/* 1.	On ajoute deux colonnes à la table dat.                               */
/* a.	Ces deux colonnes sont nommées fk et Fk.                              */
/* b.	fk vaut 1 pour chaque observation.                                    */
/* c.	Fk est une copie de la colonne wh de la table dat. Si wh n'existe pas */
/* et donc qu'il n'y a pas de variable de pondération, alors Fk vaut 1 pour   */
/* chaque observation.                                                        */
/******************************************************************************/
proc contents data=temp_&Country_imported. 
              out=tempcontent; /* on veut connaitre les differentes variables de la table sas "temp_&Country_imported." */
run;                           /* à l'aide d'une proc content */


proc sql;
select distinct NAME into:vartemp separated by ' ' /* les differents noms des variables de la table "tempcontent" */
from tempcontent;                                 /* seront regroupées dans un macro-paramètre "vartemp" */
quit;

/***********************************************************************************/
/* Objectifs macro "aggregation" 												   */
/* 																		           */
/* 1)Creer les variables "small_f" (fk) et "big_f" (Fk) en fonction de la presence */
/* ou pas de la variable &Weight. dans la table "temp_EE"                          */
/***********************************************************************************/

                                                               /********************************************************/
%IF %Index (&vartemp.,&weight.) %then %do; /* do numero 1 */   /* si la variable "&weight." est présente dans la liste */
                  										       /* des variables de la table "dat" faire cela           */                 														
data temp_&Country_imported._1;                                /********************************************************/
set temp_&Country_imported.;
small_f = 1;
big_f = &weight.;
run;

%END; /* end numero 1 */
                                     /*****************************************************/
%else %do; /* do numero 2*/          /* si la variable "&weight." n'est pas presente dans */
data temp_&Country_imported._1;      /* la liste des variables faire cela                 */
set temp_&Country_imported.;         /*****************************************************/
small_f = 1;
big_f = 1;
run;

%end; /* end numero 2 */



/**********************************************************************************/
/* 2.	Dans les variables keys de la table dat, on remplace tous les NA par "@". */
/**********************************************************************************/

/******************************************************************************************/
/* on remplace toutes les valeurs manquantes dans les differentes variables "key" par "@" */
/******************************************************************************************/
%local ii dim_key sep n expression_1 expression_2 expression_3 expression_4 expression_5 expression_6;

%LET dim_key = %sysfunc(countw(&key.));

%put dim_key = &dim_key.;

data temp_&Country_imported._2;
set temp_&Country_imported._1;

%Do ii=1 %to &dim_key.; /* do numero 3 */
%LET Key_val = %scan(&key.,&ii.);
%if &Key_val. = " " %then &Key_val. = "@";
%end; /* end numero 3 */

run;

/**************************************************************************/
/* 3. On agrège la table dat en regroupant selon les variables keys et en */ 
/* additionnant les valeurs des colonnes fk et Fk.                        */
/**************************************************************************/

/*************************/
/* Aide Olivier De Gryse */
/*************************/
%let sep=;
%let expression_1=;
%let expression_2=;

%do ii=1 %to &dim_key.; /* do numero 4 */
    %let key_val = %scan(&key,&ii);
    %let expression_1 = &expression_1.&sep. t1.&key_val.;
    %let expression_2 = &expression_2.&sep. &key_val.;
    %let sep = ,;
  %end; /* end numero 4 */

%let sep=;
%let expression_3=;

%do ii=1 %to &dim_key.; /* do numero 5 */
    %let key_val=%scan(&key,&ii);
    %let expression_3 = &expression_3. &sep. (t1.&key_val. = t2.&key_val. or t1.&key_val. is missing or t2.&key_val. is missing);
    %let sep = and;
  %end; /* end numero 5 */

  proc sql;
    create table freqcalc_result as

    select &expression_1.
      ,count(*) as n,
      sum(t2.big_f) as F

    from (select distinct &expression_2. from temp_&Country_imported._2) as t1
      left join temp_&Country_imported._2 as t2
        on &expression_3.
      group by &expression_1.;
  quit;


%let sep=;
%let expression_4=;

%do ii=1 %to &dim_key.; /* do numero 6 */
    %let key_val=%scan(&key,&ii);
	%let expression_4 = &expression_4. &sep. t1.&key_val. = t2.&key_val.;
	%let sep = and;
%end; /* end numero 6 */

proc sql;
create table temp_&Country_imported._3 as       /* permet le meme affichage que dans le pdf où l'on additionne les small_f et les big_f des lignes identiques sur les differentes variables key */
select &expression_1.,
t2.n as small_f,
t2.F as big_f
from temp_&Country_imported._2 as t1
left join freqcalc_result as t2
on &expression_4.
;
quit;


/********************************************************************************/
/* 4. On calcule la variable mm dans la table temp_EE_3. Si une des valeurs des */
/*  variables keys est égale à "@", alors mm est égale à 0. Sinon mm égale 1.   */
/********************************************************************************/
data temp_&Country_imported._4;
set temp_&Country_imported._3;

%Do ii=1 %TO &dim_key.; /* do numero 7 */

%LET key_val = %Scan(&key,&ii);

%If &Key_val. = "@" %then %do; /* do numero 8 */
mm = 0;
%end; /* end numero 8 */

%else %if &Key_val. ne "@" %then %do; /* do numero 9 */
mm = 1;
%end; /* end numero 9 */

%end; /* do numero 7 */

run;


/********************************************************************************************/
/* 5.	Si la table "temp_EE_4" compte au moins une observation pour laquelle mm            */  
/* est égal à 0 alors on continue la procédure, sinon on arrête ici et on reprend au point… */ 
/********************************************************************************************/ 
proc sql;
select count (mm) into:nbzeromm /* dans le macro-paramètre "&nbzeromm." */ 
from temp_&Country_imported._4 /* je mets le nombre d'observations issues de la table "temp_EE_4" */
where mm = 0; /*où la variable "mm" vaut 0 */
quit;

/***************************************************************************************************************/
/* En fonction du nombre d'observations de la table "temp_EE_4" où la variable "mm"                            */
/* est égale à 0  on va creer soit la table "Adat" (si nombre d'observations où la variable "mm" est égale à 0 */
/* est nulle																								   */
/*  soit les tables "A1" "A2" et "A2_temp" (si le nombre  d'observations où la variable "mm" est égale         */
/* à 0 n'est pas nulle 																				           */
/***************************************************************************************************************/
%if &nbzeromm. = 0 %then %do; /* do numero 10 */
/* Paul m'a signalé que l'on va directement au point 13 										       */
/* 13.	On remplace les valeurs "@" par des valeurs NA dans les variables de Keys.					   */
/* 14. On créé la table Adat qui garde l'ensemble des lignes mais ne conserve que les colonne fk et Fk */

data Adat (keep= small_f big_f);
set temp_&Country_imported._4;
run;
%end; /* end numero 10*/


%else %if &nbzeromm. ne 0 %then %do; /* do numero 11 */
/***********************************************************************/
/* 6. On créé une table A1 comme une sous table de temp_EE_4 contenant */ 
/* uniquement les lignes pour lesquelles mm est égal à 1               */
/***********************************************************************/
data A1;
set temp_&Country_imported._4;
where mm = 1;
run;


/******************************************************************************************/
/* 7.	On créé une table A2 et A2.temp comme des sous tables de temp_EE_4 contenant      */
/* uniquement les lignes pour lesquelles mm est égal à 0. (A2 et A2.temp sont identiques).*/ 
/******************************************************************************************/
data A2;
set temp_&Country_imported._4;
where mm = 0;
run;

data A2_temp;
set A2;
run;

/**********************************************************************************************************************************************************/
/* 8.	Boucle "for" pour i allant de 1 à n-1, n étant égal au nombre de ligne de A2,																	  */
/*																																						  */
/* 9.	Boucle "for" pour j allant de (i+1) à n, n étant égal au nombre de ligne de A2 :																  */
/*      a.	On créé la table t comme une sous table de A2 conservant uniquement les lignes i  et j et les colonnes des variables keys.                    */
/*																																						  */
/*      b.	Si l'une des lignes comporte un "@" dans une ou plusieurs variables, l'autre ligne se voit forcer un "@" sur cette/ces variables.			  */
/*																																						  */
/*      c.	Si, après ces modifications, les lignes sont identiques en tout point, alors on additionne aux valeurs des variables fk et Fk de la ligne i   */
/*        de la table A2, les valeurs des variables fk et Fk de la ligne j de la table A2.temp. De même, on additionne aux valeurs des variables fk et Fk */ 
/*        de la ligne j de la table A2, les valeurs des variables fk et Fk de la ligne i de la table A2.temp.											  */
/*																																						  */
/* 10.	Fin de la double boucle.																														  */
/**********************************************************************************************************************************************************/

/**********************************************************************/
/* A2_temp et A2 sont equivalents 									  */
/* 																	  */
/* A2_temp au fur et à mesure des itérations n'est jamais modifiée	  */
/* 		   															  */
/* C'est la table A2 qui est modifiée si les conditions sont remplies */
/*                                                                    */
/* au fur et à mesure des itérations 		   						  */
/**********************************************************************/

proc contents data=A2 out=A2_Content; run;

proc sql;
select nobs into:nobsA2 /* je recupere le nombre de lignes dans le dataset "A2" */
from A2_Content ; /* à l'aide de son content la table "A2_Content" */
quit;

/**********************************************************/
/* 1ere etape : Création d'une variable "numero de ligne" */
/**********************************************************/
data A2_temp;
set A2_temp;
numero_ligne = _N_ ;
run;

data A2;
set A2;
numero_ligne = _N_ ;
run;

/********************************************************************************/
/* Boucle "for" pour i allant de 1 à n-1, n étant égal au nombre de ligne de A2 */
/********************************************************************************/
%Do i=1 %to %eval(&nobsA2. - 1) ; /* do numero 12 */

/************************************************************************************/
/* Boucle "for" pour j allant de (i+1) à n, n étant égal au nombre de ligne de A2 : */
/************************************************************************************/
%DO j= %eval(&i. + 1) %TO &nobsA2.; /* do numero 13 */

/**************************************************************************************/
/* 2ième etape : on va faire une selection de lignes sur les tables "A2" et "A2_temp" */
/* selon l'iteration et donc en s'aidant des indices i et j                           */
/**************************************************************************************/
data A2_&i._&j.;
set A2;
where numero_ligne in (&i. &j.);
run;


data A2_temp_&i._&j.;
set A2_temp;
where numero_ligne in (&i. &j.);
run;

/****************************************************************************************/
/* 3ieme etape : Pour chacune des tables "A2_&i._&j." et "A2_temp_&i._&j."              */
/* si la modalité d'une variable de "key" est egale à "@" la modalité de la variable de */
/* la ligne suivante vaudra egalement "@" 											    */
/****************************************************************************************/
data A2_&i._&j._v2;
set A2_&i._&j.;

%Do ii=1 %To &dim_key.; /* do numero 14 */
%LET key_val = %scan (&key.,&ii.);
L&key_val. = lag (&key_val.);
if _n_ eq 2 and L&key_val. eq "@" then &key_val. = L&key_val.;
drop L&key_val.;
%end; /* end numero 14 */

run;


proc sort data=A2_&i._&j._v2 out=A2_&i._&j._v2;
by descending numero_ligne;
run;

data A2_&i._&j._v2;
set A2_&i._&j._v2;

%Do ii=1 %To &dim_key.; /* do numero 15 */
%LET key_val = %scan (&key.,&ii.);
L&key_val. = lag (&key_val.);
if _n_ eq 2 and L&key_val. eq "@" then &key_val. = L&key_val.;
drop L&key_val.;
%end; /* end numero 15 */

run;


proc sort data=A2_&i._&j._v2 out=A2_&i._&j._v2;
by numero_ligne;
run;


data A2_temp_&i._&j._v2;
set A2_temp_&i._&j.;

%Do ii=1 %To &dim_key.; /* do numero 16 */
%LET key_val = %scan (&key.,&ii.);
L&key_val. = lag (&key_val.);
if _n_ eq 2 and L&key_val. eq "@" then &key_val. = L&key_val.;
drop L&key_val.;
%end; /* end numero 16 */

run;

proc sort data=A2_temp_&i._&j._v2 out=A2_temp_&i._&j._v2;
by descending numero_ligne;
run;


data A2_temp_&i._&j._v2;
set A2_temp_&i._&j._v2;

%Do ii=1 %To &dim_key.; /* do numero 17 */
%LET key_val = %scan (&key.,&ii.);
L&key_val. = lag (&key_val.);
if _n_ eq 2 and L&key_val. eq "@" then &key_val. = L&key_val.;
drop L&key_val.;
%end; /* end numero 17 */

run;

proc sort data=A2_temp_&i._&j._v2 out=A2_temp_&i._&j._v2;
by numero_ligne;
run;

/**************************************************************************/
/* 4ieme etape : Si les deux lignes sont equivalentes pour les variables  */
/* "key1" "key2" "key3" "key4" de la table "A2_&i._&j._v2" avec l'aide de */ 
/* la table "test1_A2_&i._&j._v2" alors on passe à la 6ième etape         */
/* (faute dans ma numerotation)											  */
/**************************************************************************/
proc transpose data=A2_&i._&j._v2
               out=test1_A2_&i._&j._v2;
			   var &keys.;
run;

data test2_A2_&i._&j._v2;
set test1_A2_&i._&j._v2;
if COL1 = COL2 then flag= "yes";
else if COL1 ne COL2 then flag = "no";
run;

proc sql noprint;
select distinct (flag) into:valueflagA2 from test2_A2_&i._&j._v2;
quit;

%if %index(&valueflagA2.,no) %then %do; /* do numero 18 */
data A2_&i._&j._v3;
set A2_&i._&j.  A2(where=(numero_ligne not in(&i. &j.)));
run;

proc sort data=A2_&i._&j._v3 
          out=A2 ; 
          by numero_ligne; 
run;
%end; /* end numero 18 */

%else %do; /* do numero 19 */

/***********************************************************************************/
/* 6ième etape : Explications 												       */
/* 																			       */
/* Dans la table "A2_&i._&j." 													   */
/* 																		           */
/* La nouvelle valeur de (small_f,big_f) à la ligne &i. de la table A2_&i._&j.     */
/* sera egale à la valeur de (small_f,big_f) à la ligne &i. de la table A2_&i._&j. */
/* plus la valeur de (small_f,big_f) à la ligne &j. de la table "A2_temp_&i._&j."  */
/* 																		           */
/* La nouvelle valeur de (small_f,big_f) à la ligne &j. de la table A2_&i._&j.     */
/* sera egale à la valeur de (small_f,big_f) à la ligne &j. de la table A2_&i._&j. */
/* plus la valeur de (small_f,big_f) à la ligne &i. de la table "A2_temp_&i._&j."  */
/***********************************************************************************/

/*******************************************************************/
/* 7ieme etape :												   */
/*																   */
/* On renomme la variable small_f par small_f_new puis la variable */
/* big_f par big_f_new dans la table A2_temp_&i._&j.               */
/*																   */
/* 9ieme etape : on ajoute une variable bidon egale SUCCESSIVEMENT */
/* à 2 et 1														   */
/*******************************************************************/
data A2_temp_&i._&j._v3 (rename=(big_f = big_f_new small_f = small_f_new));
set A2_temp_&i._&j._v2;
if _N_ = 1 then bidon = 2;
if _N_ = 2 then bidon = 1;
run;


/**********************************************************************************/
/* 8ieme etape : 															      */
/*																			      */
/* Dans la table A2_&i._&j._v2 on ajoute la variable "bidon" egale SUCCESSIVEMENT */
/* à 1 et 2																	      */
/**********************************************************************************/
data A2_&i._&j._v3;
set A2_&i._&j.;
if _N_ eq 1 then bidon = 1;
if _N_ eq 2 then bidon = 2;
run;

/**********************************************************************************/
/* 10ième etape:														          */
/*																			      */
/* On fait le proc sql pour le merge entre la table A2_&i._&j._v3 et			  */
/*																			      */
/* A2_temp_&i._&j._v3 (on ne va garder que les colonnes small_f_new et big_f_new) */
/*																			      */
/* et la clé de tri sera la variable "bidon"                                      */
/**********************************************************************************/
proc sql;

create table A2_&i._&j._v4 as

select t1.*,
       t2.small_f_new,
       t2.big_f_new

from A2_&i._&j._v3 as t1

left join A2_temp_&i._&j._v3 as t2

on t1.bidon = t2.bidon

;

quit;


/***********************************/
/* 11ième etape :                  */
/*								   */
/* small_f = small_f + small_f_new */
/*								   */
/* big_f = big_f + big_f_new       */
/***********************************/
data A2_&i._&j._v5 (drop= small_f_new big_f_new bidon);
set A2_&i._&j._v4;
small_f = small_f + small_f_new;
big_f = big_f + big_f_new;
run;


/******************************************************************/
/* 12ieme etape:												  */
/*																  */
/* On va selectionner les lignes qui n'etaient pas egales à &i.	  */
/*																  */
/* et à &j. pour la variable "numero_ligne" dans la table A2      */
/*																  */
/* du debut puis on va la set à la table A2_&i._&j._v5  		  */
/******************************************************************/
data A2_&i._&j._v6;

set A2_&i._&j._v5

    A2 (where=(numero_ligne not in (&i. &j.)));

run;


/***********************************/
/* 13ieme etape :                  */
/*                                 */
/* on va trier par numero de ligne */
/*                                 */
/***********************************/
proc sort data=A2_&i._&j._v6 out=A2 ; 
           by numero_ligne; 
run;

%end; /* end numero 19 */

%end; /* end numero 13 */

/****************************************/
/* suppression de tables intermediaires */
/****************************************/
proc datasets lib=work nolist;
delete A2_&i._&j.  A2_&i._&j._v2 - A2_&i._&j._v6   A2_temp_&i._&j. A2_temp_&i._&j._v2  A2_temp_&i._&j._v3  test1_A2_&i._&j._v2  test2_A2_&i._&j._v2;
run;

%end; /* end numero 12 */



/*************************************************************************/
/* 1.	Nouvelle boucle : pour chaque ligne de la table A2     			 */
/*(Le point 11 est expliqué par l'exemple à la page suivante). 			 */
/* 																		 */
/* a.	On crée une id1 une sous-table de A2 contenant une 				 */
/* seule ligne (celle concernée par l'itération) et contenant 			 */
/*uniquement les variables de Keys dont la valeur est différente de "@". */
/*************************************************************************/

/* je vais mettre dans un paramètre le nombre d'observations de la table A2 */
/* avec l'aide la proc contents */

proc contents data=A2 out=A2_Contents ; run;

proc sql;
select nobs into:nobsA2 from A2_Contents; 
quit;

data A2_v1;
set A2;
numero_ligne = _N_;
run;

data id1_&i.;
set A2_v1;
where numero_ligne = &i.;
run;

data id1_&i._char(keep= _CHAR_ numero_ligne);
set id1_&i.;
run;

proc transpose data=id1_&i._char 
               out=id1_&i._char_v2;
               var _CHAR_; 
run;

data id1_&i._char_v3; 
set id1_&i._char_v2;
if COL1 = "@" then delete;
run;

proc transpose data=id1_&i._char_v3 
               out=id1_&i._char_v4;
               id _NAME_; 
               var col1; 
run;

data id1_&i._char_v5 (drop=_NAME_); /* ici dans cette table "id1_&i._char_v5" on a uniquement les variables charactères (en plus de la variable "numero_ligne" mais celle-ci servira pour le merge suivant) dès lors on va merger avec la table "id1_&i." (en lui retirant les variables characteres pour ne pas avoir un message selon lequel cette variable est déja présente) et on aura donc dans la table issue de ce merge une seule ligne avec toutes les variables du debut de cette table sauf les variables qui étaient egales à "@" */
set id1_&i._char_v4;
numero_ligne = &i.;
run;


/**************************************************************/
/* le proc sort par la variable "numero_ligne" avant le merge */
/**************************************************************/
proc sort data=id1_&i. out=id1_&i._v2(drop=_CHAR_); by numero_ligne; run;

proc sort data=id1_&i._char_v5 out=id1_&i._char_v6; by numero_ligne; run;


/***************************************************************************************/
/* merge final pour obtenir la table "id1_&i._v3" 									   */
/* Cette table sera id1 une sous-table de A2 contenant une seule ligne                 */
/*(celle concernée par l'itération) et contenant uniquement les variables de Keys dont */
/* la valeur est différente de "@".                                                    */
/***************************************************************************************/

data id1_&i._v3 (drop=small_f big_f numero_ligne mm); /* id1_&i._v3 = sous-table de A2 contenant une seule ligne (celle concernée par l'itération) et contenant uniquement les variables de Keys dont la valeur est différente de "@".*/

merge id1_&i._v2 id1_&i._char_v6;

by numero_ligne;

run;

/*******************************************************************/
/* b.	On créé A1.temp une sous table de A1 en gardant toutes les */
/* colonnes mais en ne gardant que les lignes pour lesquelles les  */
/* valeurs prise par les variables présentent dans id1 sont        */
/* équivalente à celles de id1.            						   */
/*******************************************************************/
/* 1) je mets dans un paramètre les variables contenues dans id1_&i._v3, */
/* faire le keep de ces variables sur A1 pour creer A1_1_v2 */
proc contents data=id1_&i._v3 out=id1_&i._v4; run;

proc sql;
select distinct NAME into:varid1v3 separated by ' ' from id1_&i._v4;
quit;

data A1_&i._v2 /*(keep= &varid1v3. small_f big_f)*/;
set A1;
run;

/* 2) creer une variable "bidon" dans id1_&i._v3 */
/* avec une modalité qui vaut "oui" */
data id1_&i._v4;
set id1_&i._v3;
bidon = "oui";
run;

/* 3) faire un proc sort pour "A1_&i._v2" et "id1_&i._v4" */
/* avant le merge */

proc sort data=A1_&i._v2 out=A1_&i._v3; by &varid1v3.; run;

proc sort data= id1_&i._v4 out=id1_&i._v5; by &varid1v3.; run;

data A1_&i._v4;
merge A1_&i._v3 id1_&i._v5;
by &varid1v3.; 
run;

/* 4) on fait une restriction sur la variable "bidon" qui vaut "oui" */
/* et cette table sera "A1_temp" (= A1_&i._v5)*/
data A1_&i._v5 (drop=bidon);
set A1_&i._v4;
where bidon = "oui";
run;


/**********************************************************************/
/*c.On additionne aux valeurs de fk et Fk de la ligne de A2 concernée */
/* par l'itération, la somme des valeurs des fk et Fk de A1.temp. 	  */
/**********************************************************************/

/* 1 ere etape : on fait une selection sur la variable "numero_ligne" */
/* de A2_v1 qui deviendra A2_V1_1 car on fait une selection sur la premiere ligne */

data A2_V1_&i.;
set A2_V1;
where numero_ligne = &i.;
run;

/* 2ième etape: on calcule la somme des modalités des variables */
/* "small_f" et "big_f" de la table "A1_&i._V5" (=A1_temp) */

data A1_&i._V6 (keep=big_f small_f);
set A1_&i._V5;
run;

proc transpose data=A1_&i._V6 out=A1_&i._V7; run;

data A1_&i._V8;
set A1_&i._V7;
COL3 = COL1 + COL2;
run;

proc sql;
select COL3 into:newsmallf from A1_&i._V8 where _NAME_ = "small_f";
select COL3 into:newbigf from A1_&i._V8 where _NAME_ = "big_f";
quit;


data A1_&i._V9;
set A2_V1;
where numero_ligne = &i. ;
small_f = small_f + %eval(&newsmallf.);
big_f = big_f + %eval(&newbigf.);
run;

data A1_&i._V10; /* A1_&i._V10 = ce sera le nouveau A2 */
set A1_&i._V9 A2_V1 (where=(numero_ligne ne &i.));
run;

/****************************************************************************/
/* d.On additionne les valeurs de fk et Fk de la ligne de A2 concernée      */
/* par l'itération aux valeurs de fk et Fk de chacune des lignes de A1.temp */
/****************************************************************************/

/* Etape 1 : On crée une variable "numero_ligne" = 1 dans la table "A1_1_V5" */
/* qui deviendra "A1_1_v11 */

data A1_&i._v11;
set A1_&i._v5;
numero_ligne = &i.;
run;

/* Etape 2 : On renomme les variables "small_f" et "big_f" par 
"smallfnew" et "bigfnew" dans id1_1 */
data id1_&i._v6 (rename=(small_f = smallfnew  big_f = bigfnew));
set id1_&i.;
run;

/* Etape 3 : Merge entre id1_&i._v6 et A1_&i._V11 avec la clé */
/* "numero_ligne" (on obtient la creation de la table "A1_&i._v12" */

/* Etape 4 : On fait le calcul dans la table "A1_&i._v12" */
/* smallfnew1 = small_f + smallfnew */
/* bigfnew1*/
proc sql;
create table A1_&i._V12 as 
select t1.*,
       t2.bigfnew,
	   t2.smallfnew,
	   small_f + smallfnew as smallfnew1,
	   big_f + bigfnew as bigfnew1

from A1_&i._v11 as t1
left join id1_&i._v6 as t2
on t1.numero_ligne = t2.numero_ligne
;
quit;

/* Etape 5 : On fait le merge entre "A1_&i._v12" et "A1" avec */
/* les clés "key1" "key2" "key3" "key4" "small_f" et "big_f" */
data A1_&i._V13;
set A1;
numerolignes = _N_;
run;


proc sql;

create table A1_&i._V14 as

select

&expression_1.,
t1.small_f,
t1.big_f,
t2.smallfnew1,
t2.bigfnew1

from A1_&i._V13 as T1

left join A1_&i._v12 as T2

on

&expression_4.

order by t1.numerolignes

;

quit;


/* A1_&i._V15 = le nouveau A1 */
data A1_&i._V15 (drop=small_f big_f rename=(smallfnew1 = small_f bigfnew1 = big_f));
set A1_&i._V14;
if smallfnew1 = . then smallfnew1 = small_f;
if bigfnew1 = . then bigfnew1 = big_f;
run;

data A1;
set A1_&i._V15;
run;

data A2;
set A1_&i._V10;
run;


/*****************************************/
/* suppression des tables intermédiaires */
/*****************************************/
proc datasets lib=work nolist;
delete id1_&i. id1_&i._v2 - id1_&i._v6

       id1_&i._char id1_&i._char_v2 - id1_&i._char_v6

	   A1_&i._v2 - A1_&i._v15

	   A2_v1_&i. ;
run;




/*****************************************************/
/* 12.	On réuni les tables A1 et A2 ainsi modifiée. */
/*****************************************************/
data A1_A2; 
set A1 A2;
run; 


/***********************************************************************************/
/* 13.	On remplace les valeurs "@" par des valeurs NA dans les variables de Keys. */
/***********************************************************************************/
data A1_A2;
set A1_A2;
array varkey &key.;
do over varkey;
varkey = tranwrd(varkey,"@"," ");
end;
run;


/***********************************************************************************/
/* 14.	On créé la table Adat qui garde l'ensemble des lignes mais ne conserve que */ 
/* les colonne fk et Fk                                                            */
/***********************************************************************************/
data Adat(keep=small_f big_f);
set A1_A2;
run;

/**************************************/
/*** fin de la fonction d'aggregation */
/**************************************/

%end; /* end numero 11 */

/*************************************************************************************/
/* #2. Sur base de ces deux colonnes, on calcul p comme la proportion de fk dans FK. */
/* #p=fk/Fk                                                                          */
/*************************************************************************************/
data Adat;
set Adat;
p = small_f/big_f;

/* #3. Si p=1, alors on fixe p=0.9999 */

%if p = 1 %then %do; /* do numero 20 */
p = 0.9999;
%end; /* end numero 20 */

/*************************************************************************************************/
/* #4. En fonction de la valeur de fk, on détermine trois fonctions à appliquer pour calculer la */ 
/*nouvelle colonne rk:                                                                           */
/*************************************************************************************************/

/*****************************************/
/* #4.1 si fk=1, rk=(p/(1 - p))*log(1/p) */
/*****************************************/
%if small_f = 1 %then %do; /* do numero 21 */
rk = (p/(1-p)) * (log10(1/p));
%end; /* end numero 21 */

/*****************************************************/
/* #4.2 si fk=2, rk=(p/((1 - p)^2))*(p*log(p)+(1-p)) */
/*****************************************************/
%else %if small_f = 2 %then %do; /* do numero 22 */
rk = (p/((1-p)**2)) * (p * log10(p) + (1 - p));
%end; /* end numero 22 */

/*************************************************************************/
/* #4.3 si fk>2, rk=(fp[2]/fp[1])*(1+a1+a2+a3+a4+a5+a6+a7) où            */    
/* #a1=(1-p)/(fk+1)                                                      */
/* #a2=2*((1-p)^2)/((fk+1)*(fk+2))										 */
/* #a3=6*((1-p)^3)/((fk+1)*(fk+2)*(fk+3))								 */
/* #a4=24*((1-p)^4)/((fk+1)*(fk+2)*(fk+3)*(fk+4)) 					     */
/* #a5=120*((1-p)^5)/((fk+1)*(fk+2)*(fk+3)*(fk+4)*(fk+5))                */
/* #a6=720*((1-p)^6)/((fk+1)*(fk+2)*(fk+3)*(fk+4)*(fk+5)*(fk+6))         */
/* #a7=5040*((1-p)^7)/((fk+1)*(fk+2)*(fk+3)*(fk+4)*(fk+5)*(fk+6)*(fk+7)) */
/*************************************************************************/
%else %if small_f >2 %then %do; /* do numero 23 */
a1 = (1 - p)/(small_f +1);

a2 = (2 * ((1-p)**2)) / ((small_f +1) * (small_f +2));

a3 = (6 * ((1-p)**3)) / ((small_f +1) * (small_f +2) * (small_f + 3));

a4 = (24 * ((1-p)**4)) / ((small_f +1) * (small_f +2) * (small_f + 3) * (small_f + 4));

a5 = (120 * ((1-p)**5)) / ((small_f +1) * (small_f +2) * (small_f + 3) * (small_f + 4) * (small_f + 5));

a6 = (720 * ((1-p)**6)) / ((small_f +1) * (small_f +2) * (small_f + 3) * (small_f + 4) * (small_f + 5) * (small_f + 6));

a7 = (5040 * ((1-p)**7)) / ((small_f +1) * (small_f +2) * (small_f + 3) * (small_f + 4) * (small_f + 5) * (small_f + 6) * (small_f + 7));

rk =  (sum(a1-a7) + 1) * (p/small_f);

%end; /* end numero 23 */

run;


/**************************************************************************************/
/* #5. Il ressort finalement de cette function BFP, une table (que l'on nomme "risk") */ 
/* avec 4 colonnes: fk, Fk, p, rk     												  */
/**************************************************************************************/
data  Risk_&Country_imported. (keep= small_f big_f p rk);
set Adat;
run;


/**************************************************************************************************************************/
/* #On crée une nouvelle table nommée at.risk contenant le même nombre de ligne que la table risk.						  */
/* #Pour les différentes valeurs de thresholds définies dans le script manage_progs_2015							      */
/* #1. On crée une nouvelle variable dans la table at.risk nommée par le palier de thesholds (0.0005, 0.001, 0.01, ...)   */
/* #2. Pour chaque ligne de la table risk, si la valeur de rk est plus élevée que le palier considéré (0.01, 0.001, ...), */
/* #alors on assigne une valeur de "1" a la nouvelle variable de la table at.risk.									      */
/* #Si la valeur de rk est plus petite ou égale au palier considéré, alors la valeur de cette variable est 0.			  */
/* #3. Construction de la table drr qui conserve les mêmes colonnes que at.risk et une seule ligne calculée				  */
/* #comme étant la moyenne (arrondie à 3 décimales) de chaque colonne de at.risk.										  */
/* #																													  */
/* #Ci-dessous un exemple de table drr																					  */
/* #     0.0005 0.001 0.005 0.01 0.05 ---> nom des colonnes															      */
/* #[1,]  0.253 0.125 0.050 0.02 0.01 ---> moyenne des colonnes de la table at.risk 									  */
/**************************************************************************************************************************/
data Risk_&Country_imported.;

set Risk_&Country_imported.;

if rk <= 0.0005 then cinq_puissance_moins_quatre = 0; else if rk > 0.0005 then cinq_puissance_moins_quatre = 1;

if rk <= 0.001 then un_puissance_moins_trois = 0; else if rk > 0.001 then un_puissance_moins_trois = 1;

if rk <= 0.005 then cinq_puissance_moins_trois = 0; else if rk > 0.005 then cinq_puissance_moins_trois = 1;

if rk <= 0.01 then un_puissance_moins_deux = 0; else if rk > 0.01 then un_puissance_moins_deux = 1;

if rk <= 0.05 then cinq_puissance_moins_deux = 0; else if rk > 0.05 then cinq_puissance_moins_deux = 1;

run;

proc transpose data=Risk_&Country_imported. 
               out=Risk_&Country_imported._transpose;
run;

data Risk_&Country_imported._transpose (keep= _NAME_ moyenne);
set Risk_&Country_imported._transpose;

moyenne = round(mean (of COL:),0.001);
run;

proc transpose data=Risk_&Country_imported._transpose out=Risk_&Country_imported._transpose_1; run;


/*************************************************************************************************************************/
/* #Preparation of the scenario description to be saved in the output                                                    */
/* #Description du scénario sous forme de table.                                                                         */
/* #La première colonne donne le numéro du scénario retenu (de 1 aux nombres de scénarios possibles (SS.A1, SS.A2, ...)) */
/* #"SC. A1"																											 */
/* #La seconde colonne donne le nom des variables clées (mb02, mb05, ...)                                                */
/* #Les colonnes suivantes sont celles de la table drr                                                                   */
/* #Un exemple:                                                                                                          */
/* #     Scenario  V1     V2     0.0005 0.001 0.005 0.01 0.05 <-Nom des colonnes                                         */
/* #[1,] "Sc. A1:" "mb02" "mb05" 0.253 0.125 0.050 0.02 0.01 <-Ligne descriptive 									     */
/*************************************************************************************************************************/
%Let expression_5 = ;
%Let expression_6 = ;

%Do ii=1 %to &dim_key.; /* do numero 24 */
 %let Key_Val = %scan (&key.,&ii.);
 %let expression_5 = &expression_5. V&ii.;
 %let expression_6 = &expression_6. %str(V&ii. = "&key_val.";);
%end; /* end numero 24 */

data test10_scB (rename=(cinq_puissance_moins_quatre = '0.0005'n  un_puissance_moins_trois = '0.001'n  cinq_puissance_moins_trois = '0.005'n  un_puissance_moins_deux = '0.01'n  cinq_puissance_moins_deux = '0.05'n)
                 keep = Scenario &expression_5. cinq_puissance_moins_quatre  un_puissance_moins_trois  cinq_puissance_moins_trois   un_puissance_moins_deux  cinq_puissance_moins_deux);
retain Scenario &expression_5. cinq_puissance_moins_quatre  un_puissance_moins_trois  cinq_puissance_moins_trois   un_puissance_moins_deux  cinq_puissance_moins_deux;
set Risk_&Country_imported._transpose_1;
&expression_6.
Scenario = &scenario.;
run;

/*************************************/
/* suppression des tables de la work */
/*************************************/

proc datasets lib=work nolist;

delete Key_&Country_imported.  

       Key_&Country_imported._Content

     dtemp_&Country_imported.

     rr_&Country_imported.

     ww_&Country_imported.

     temp_&Country_imported.

     tempcontent

     temp_&Country_imported._1 - temp_&Country_imported._4

     freqcalc_result ;

run;

%mend ScenarioB;

%ScenarioB (key = NUTS1 HA09 HB05 HB074 MB05,
            weight = HA10,
			HMID = MB05,scenario = "SC. B1:");