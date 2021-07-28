/********************************************/
/* 1.	Définition des paramètre suivants : */
/* a.	candidates                          */
/* b.	Size								*/
/* c.	side                                */
/* d.	Exp.zeros                           */
/* e.	Inc.zeros                           */
/* f.	k1                                  */
/********************************************/

/* defined in the program "Parameters"

/*********************************************/
/* faux fichier que je crée pour mon exemple */
/*********************************************/
/*data &Country_imported._AfterRecodings;
<snipped>
*/


/****************************************************************/
/* 2.Dans la table dd on défini la colonne Intercept égale à 1. */
/****************************************************************/
data &Country_imported._AfterRecodings;
set &Country_imported._AfterRecodings;
Intercept = "1";
run;


/**************************************************************/
/* 3.	On définit le paramètre key_CV ("Intercept","nuts1"). */
/**************************************************************/

/* Fait au debut dans le programme "Parameters" */

/************************************************************************************************/
/* 4.SumW est un vecteur défini comme la colonne Fk de la table résultante de l'application     */
/* de la fonction d'agrégation aggrm appliquée sur les variables enregistrées dans le paramètre */ 
/* key de la table dd et avec comme variable de pondération, la variable enregistrée dans le    */ 
/* paramètre WEIGHT.																			*/
/************************************************************************************************/
options mprint;
%Macro Aggregation(tableentree,tablesortie,varchoisies);
/*********************************************************************************/
/* On ne conserve dans key que les éléments qui sont le nom d'une colonne de dd. */
/*********************************************************************************/
data Key_&Country_imported.  (keep= &varchoisies.);
set &tableentree.;
run;

proc contents data=Key_&Country_imported.  
              out=Key_&Country_imported._Content; 
run;

proc sql;
select distinct NAME into:varchoisies separated by ' '  /* je conserve dans le macro-parametre &varchoisies. uniquement les variables qui sont le nom d'une colonne de dd */
from Key_&Country_imported._Content;
quit;

/*****************************************************************************************/
/* On ne garde que les observations/lignes pour lesquelles HMID est égal à 1.			 */
/* On ne conserve que les colonnes listées dans WEIGHT                                   */
/*(paramètre défini dans le script manage_progs_2015) et les variables listées dans key. */	
/* dtemp=dd[dd[,HMID]=="1",c(WEIGHT,key)]                                                */ 
/*****************************************************************************************/
data dtemp_&Country_imported. (keep= &varchoisies. &Weight_CV.);
set &tableentree.;
/*where &HMID. = "1";*/
run;

/***********************************************************************************************************************/
/* Preparation of the arguments for the function BFP [ Risk Measures according to Benedetti-Franconi-Polettini method] */
/* rr est une sous table de dtemp ne contenant que les variables listées dans key 									   */
/***********************************************************************************************************************/
data rr_&Country_imported. (keep= &varchoisies.);
set dtemp_&Country_imported.;
run;

/*************************************************************************************/
/* ww est une sous table de dtemp ne contenant que les variables listées dans WEIGHT */
/* ww=dtemp[,WEIGHT]                                                                 */
/*************************************************************************************/
data ww_&Country_imported. (keep=&Weight_CV.);
set dtemp_&Country_imported.;
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
%IF %Index (&vartemp.,&Weight_CV.) %then %do; /* do numero 1 */   /* si la variable "&weight." est présente dans la liste */
                  										       /* des variables de la table "dat" faire cela           */                 														
data temp_&Country_imported._1;                                /********************************************************/
set temp_&Country_imported.;
small_f = 1;
big_f = &Weight_CV.;
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
%local ii dim_varchoisies sep n expression_1 expression_2 expression_3 expression_4 expression_5 expression_6;

%LET dim_varchoisies = %sysfunc(countw(&varchoisies.));

%put dim_varchoisies = &dim_varchoisies.;

data temp_&Country_imported._2;
set temp_&Country_imported._1;

%Do ii=1 %to &dim_varchoisies.; /* do numero 3 */
%LET Varchoisies_val = %scan(&varchoisies.,&ii.);
%if &Varchoisies_val. = " " %then &Varchoisies_val. = "@";
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

%do ii=1 %to &dim_varchoisies.; /* do numero 4 */
    %let Varchoisies_val = %scan(&varchoisies,&ii);
    %let expression_1 = &expression_1.&sep. t1.&Varchoisies_val.;
    %let expression_2 = &expression_2.&sep. &Varchoisies_val.;
    %let sep = ,;
  %end; /* end numero 4 */

%let sep=;
%let expression_3=;

%do ii=1 %to &dim_varchoisies.; /* do numero 5 */
    %let Varchoisies_val =%scan(&varchoisies,&ii);
    %let expression_3 = &expression_3. &sep. (t1.&Varchoisies_val. = t2.&Varchoisies_val. or t1.&Varchoisies_val. is missing or t2.&Varchoisies_val. is missing);
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

%do ii=1 %to &dim_varchoisies.; /* do numero 6 */
    %let Varchoisies_val=%scan(&varchoisies,&ii);
	%let expression_4 = &expression_4. &sep. t1.&Varchoisies_val. = t2.&Varchoisies_val.;
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
%local ii dim_varchoisies varchoisies_val sep expression_971;

%let sep = ;
%let expression_971 = ;
%LET dim_varchoisies = %sysfunc(countw(&varchoisies.));

%DO ii=1 %To &dim_varchoisies.;
%LET varchoisies_val = %scan(&varchoisies.,&ii.);
%LET expression_971 = &varchoisies_val. = "@" &sep. &expression_971.;
%LET sep = or;
%end;

data temp_&Country_imported._4;
set temp_&Country_imported._3;

if &expression_971. then do;
mm = 0;
end;

else do;
mm=1;
end;

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

data &tablesortie.(keep= big_f);
set temp_&Country_imported._4;
run;

%end; /* end numero 10 */

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

%Do ii=1 %To &dim_varchoisies.; /* do numero 14 */
%LET varchoisies_val = %scan (&varchoisies.,&ii.);
L&varchoisies_val. = lag (&varchoisies_val.);
if _n_ eq 2 and L&varchoisies_val. eq "@" then &varchoisies_val. = L&varchoisies_val.;
drop L&varchoisies_val.;
%end; /* end numero 14 */

run;


proc sort data=A2_&i._&j._v2 out=A2_&i._&j._v2;
by descending numero_ligne;
run;

data A2_&i._&j._v2;
set A2_&i._&j._v2;

%Do ii=1 %To &dim_varchoisies.; /* do numero 15 */
%LET varchoisies_val = %scan (&varchoisies.,&ii.);
L&varchoisies_val. = lag (&varchoisies_val.);
if _n_ eq 2 and L&varchoisies_val. eq "@" then &varchoisies_val. = L&varchoisies_val.;
drop L&varchoisies_val.;
%end; /* end numero 15 */

run;


proc sort data=A2_&i._&j._v2 out=A2_&i._&j._v2;
by numero_ligne;
run;


data A2_temp_&i._&j._v2;
set A2_temp_&i._&j.;

%Do ii=1 %To &dim_varchoisies.; /* do numero 16 */ 
%LET varchoisies_val = %scan (&varchoisies.,&ii.);
L&Varchoisies_val. = lag (&varchoisies_val.);
if _n_ eq 2 and L&varchoisies_val. eq "@" then &varchoisies_val. = L&varchoisies_val.;
drop L&varchoisies_val.;
%end; /* end numero 16 */

run;

proc sort data=A2_temp_&i._&j._v2 out=A2_temp_&i._&j._v2;
by descending numero_ligne;
run;


data A2_temp_&i._&j._v2;
set A2_temp_&i._&j._v2;

%Do ii=1 %To &dim_varchoisies.; /* do numero 17 */
%LET varchoisies_val = %scan (&varchoisies.,&ii.);
L&varchoisies_val. = lag (&varchoisies_val.);
if _n_ eq 2 and L&varchoisies_val. eq "@" then &varchoisies_val. = L&varchoisies_val.;
drop L&varchoisies_val.; 
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
			   var &varchoisies.;
run;

data test2_A2_&i._&j._v2;
set test1_A2_&i._&j._v2;
if COL1 = COL2 then flag= "yes";
else if COL1 ne COL2 then flag = "no";
run;

proc sql noprint;
select distinct (flag) into:valueflagA2 from test2_A2_&i._&j._v2;
quit;

%if %index(&valueflagA2.,no) %then %do;  /* do numero 18 */
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
/****************************************/
/* suppression de tables intermediaires */
/****************************************/
proc datasets lib=work nolist;
delete A2_&i._&j.  A2_&i._&j._v2 - A2_&i._&j._v6   A2_temp_&i._&j. A2_temp_&i._&j._v2  A2_temp_&i._&j._v3  test1_A2_&i._&j._v2  test2_A2_&i._&j._v2;
run;
%end; /* end numero 13 */

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
length &varid1v3. $20.;
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
COL3 = sum (of COL:);
if COL3 = . then COL3 = 0;
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
array varchoisies &varchoisies.;
do over varchoisies; /* do 19 bis */
varchoisies = tranwrd(varchoisies,"@"," ");
end; /* end 19 bis */
run;


/***********************************************************************************/
/* 14.	On créé la table Adat qui garde l'ensemble des lignes mais ne conserve que */ 
/* les colonne fk et Fk                                                            */
/***********************************************************************************/
data &tablesortie. (keep= big_f);
set A1_A2;
run;

/**************************************/
/*** fin de la fonction d'aggregation */
/**************************************/

/**************************************************************/
/* suppression des tables qui remplissent la work inutilement */
/**************************************************************/
proc datasets lib=work nolist;
delete Key_&Country_imported. 
       Key_&Country_imported._content 
       dtemp_&Country_imported.
	   rr_&Country_imported.
	   ww_&Country_imported.
	   temp_&Country_imported.
	   tempcontent
	   temp_&Country_imported._1
       temp_&Country_imported._2
	   freqcalc_result
	   temp_&Country_imported._3
       temp_&Country_imported._4
	   A1
	   A2
	   A2_temp
	   A2_Content
	   A2_Contents
	   A2_V1
	   A1_A2
;

run;

%end; /* end numero 11 */

%mend Aggregation;

%Aggregation(tableentree = &Country_imported._AfterRecodings ,tablesortie = SumW , varchoisies = &key_CV.);

data SumW (rename=(big_f = sumw));
set SumW;
run;

/***********************************************************************************************/
/* 5. On crée sps un vecteur ne contenant que les noms de variables qui sont à la fois compris */
/* dans le paramètre spont.scen (créé à la ligne 207 du script manage_progs.r) et dans         */
/* la table dd.                                                                                */
/***********************************************************************************************/
data test2 (keep= &spont_scen.);
set &Country_imported._AfterRecodings;
run;

proc contents data=test2 out=test3 noprint;
run;

proc sort data=test3 out=test4; by varnum; run;


data sps (keep=NAME rename=(NAME = sps));
set test4;
run;

proc sql noprint;
select distinct (sps) into:sps separated by ' ' from sps;
select count(distinct(sps)) into:nbssps from sps
;
quit;


/************************************************************************************/
/* 6.	On crée inc.id, un vecteur reprenant les indices des variables enregistrées */ 
/* dans les paramètres H1Inc et H2Inc dans le vecteur sps.                          */
/************************************************************************************/
proc sql noprint;
select distinct varnum into:inc_id separated by " " from test4
where NAME in ("&H1Inc." "&H2Inc.")
;
quit; /* ma version */

/* version Paul */
data inc_id (keep= Varnum rename=(Varnum = inc_id));
set test4;
where NAME in ("&H1Inc." "&H2Inc.");
run;


/*******************************************************************************************/
/* 7. On crée Xsc, une sous table de la table dd, on garde uniquement les lignes           */
/* pour lesquelles la variable comprise dans le paramètre HMID est égale à 1 et uniquement */
/* les colonnes comprises dans les paramètres HID, sps et NHM. On transforme toutes les    */
/* colonnes de Xsc en variables numériques.                                                */
/*******************************************************************************************/
data Xsctest(keep = &HID. &sps. &NHM.);
set &Country_imported._AfterRecodings;
where &HMID. = "1";
run;

proc contents data=Xsctest out=Xsctest1 noprint; run;

proc sql noprint;
select distinct NAME  into:varcharxsc separated by ' ' from Xsctest1 where type eq 2;
select count (distinct NAME)  into:nbvarcharxsc from Xsctest1 where type eq 2;
quit;


/****************************************************************************************************/
/* Avec la macro "charnumcontvars" on transforme toutes les colonnes de Xsc en variables numeriques */ 
/****************************************************************************************************/
%macro charnumcontvars;

%Do i=1 %To &nbvarcharxsc.;  /* do numero 20 */

%LET varchosen = %scan (&varcharxsc.,&i.,' ');

data blabla_&i. (keep= varchosennew rename=(varchosennew = &varchosen.));
set Xsctest;
varchosennew = input(&varchosen.,best16.);
run;

%end; /* end numero 20 */

%mend charnumcontvars;

%charnumcontvars;

data Xsc;
merge Xsctest (drop=&varcharxsc.) blabla_:;
run;


/*********************************************************************************/
/* 8.	Création de la fonction extreme de définition des paliers de             */
/* valeurs extrêmes d'une suite de valeurs.                                      */
/*                                                                               */
/* Les paliers des valeurs extrêmes sont calculés comme étant :                  */
/*                                                                               */
/* a.	Palier inférieur : le premier quartile moins k*l'écart interquartile     */
/* (distance entre le premier quartile et le troisième). k est un paramètre fixé */
/*                                                                               */
/* b.	Palier extérieur : le troisième quartile plus k* l'écart interquartile.  */
/* k est un paramètre fixé.                                                      */
/*********************************************************************************/
/* extreme=function(x,k) 
{
   q1=quantile(x,prob=0.25,na.rm=T,type=7)
   q3=quantile(x,prob=0.75,na.rm=T,type=7)
   names(q1)=names(q3)=NULL
   lower=q1-k*(q3-q1)
   upper=q3+k*(q3-q1)
   c(lower,upper)
} */

/*%Macro extreme(dataentree,datasortie,k1);
data &datasortie.(keep=_name_ lower upper rename=(_NAME_ = Variables));
set &dataentree.;
q1 = pctl(25, of COL:);
q3 = pctl (75,of COL:)
lower = q1 - &k1.(q3 - q1);
upper = q1 + &k1.(q3 - q1);
run;
%mend extreme;*/

%Macro ContVars (size1,size2);
/**********************************************************************/
/* 9. Boucle ouverte pour les valeurs comprises dans le vecteur size. */
/**********************************************************************/
%Do ctr_t = &size1. %To &size2. %by %eval(&size2. - &size1.); /* Do numero 21 */ /* = boucle ouverte pour les valeurs comprises dans le vecteur size, je les ai defini dans les paramètres de la macro */

/*************************************************************/
/* 10.	Seconde boucle ouverte pour couvrir deux scénarios : */
/*************************************************************/
%Do ctr_s = 1 %To 2  %by 1; /* do numero 22 */ /* = boucle ouverte pour couvrir deux scenarios */

/*******************************************************************************/
/* a. Scénarios 1 : le paramètre stratum contient les variables contenues dans */
/* les paramètres DEGURB et SEX ainsi que les variables nuts1 et age10.        */
/*******************************************************************************/
%IF &ctr_s. = 1 %then %do; /* do numero 23 */    /* = définition du paramètre stratum pour le scenario 1 */
%LET stratum = &DEGURB. &SEX. nuts1 age10;
%end; /* end numero 23 correspondant à la définition du paramètre stratum pour le scenario 1 */

/*********************************************************************************/
/* b.	Scénarios 2 : le paramètre stratum contient les variables contenues dans */
/* les paramètres DEGURB et SEX ainsi que les variables nuts1 et age.adhoc.      */
/*********************************************************************************/
%If &ctr_s. = 2 %then %do; /* do numero 24 */ /* = definition du paramètre stratum pour le scenario 2 */
%LET stratum = &DEGURB. &SEX. nuts1 age_adhoc;
%end; /* end numero 24 correspondant à la definition du paramètre startum pour le scenario 2 */

/*****************************************************************************************************/
/* c. On modifie stratum en ne gardant que les variables qui sont aussi des variables de la table dd */
/*****************************************************************************************************/
data testons (keep= &stratum.);
set &Country_imported._AfterRecodings;
run;

proc contents data=testons 
              out=testons_content noprint; 
run;

proc sql noprint;
select distinct Name into:stratum separated by ' ' from testons_content;
quit;

%LET stratum = &stratum.; /* ici modification de stratum en ne gardant que les variables qui sont aussi des variables de la table dd */

/*****************************************************************************************************/
/* d. on cree Q3 une matrice (que tu peux resumer a une table SAS) de deux colonnes sur le nombre de */
/* lignes que possede la table sps creee auparavant. On remplit la matrice de 0                      */
/*****************************************************************************************************/
data Q3 (drop= sps);
set sps;
var1 = 0;
var2 = 0;
run;


/*******************************************************************************************/
/* e.	On crée stat3, une matrice avec une seule colonne et autant de ligne qu'en possède */ 
/* la table sps créée auparavant. On remplie la matrice de 0.                              */
/*******************************************************************************************/
data stat3(drop=sps);
set sps;
var1 = 0;
run;



/**********************************************************************************/
/* f.	On crée deux vecteurs allrec3 et allhh3 qu'on laisse vide pour le moment. */
/**********************************************************************************/
data allrec3;
allrec3 = " ";
run;

data allhh3;
allhh3 = " ";
run;

/**************************************************************************/
/* g. On crée la table d1 équivalente à dd                                */
/* i. On ne conserve que les lignes de d1 pour lesquelles la valeur de la */  
/*    variable enregistrée dans le paramètre HMID est égale à 1.          */
/**************************************************************************/
data d1;
set &Country_imported._AfterRecodings;
where &HMID. = "1";
run;

/*************************************************************/
/* h.	Dans la table d1 on crée la colonne ratio qui        */
/* est le rapport entre SumW et la valeur du paramètre size. */
/*************************************************************/
data d1;
merge d1 SumW;
run;

data d1;
set d1;
ratio = sumw/&ctr_t.;
run;

/************************************************************************************************/
/* j.	Création de la table FFkk construite par application de la fonction d'agrégation        */
/* des catégories (déjà utilisée dans les scénarios 1 et 3) sur la table d1 ne comprenant que   */
/* les variables enregistrées dans le paramètre stratum et avec la variable enregistrée dans le */ 
/* paramètre WEIGHT comme variable de pondération. On ne garde de cette agrégation              */
/* que la colonne Fk.                                                                           */
/************************************************************************************************/
%Aggregation(tableentree = d1 ,tablesortie = FFkk , varchoisies = &stratum.);

data FFkk (rename=(big_f = FFkk));
set FFkk;
run;

/**********************************************/
/* k.	On colle la table FFkk à la table d1. */
/**********************************************/
data d1;
merge d1 FFkk;
run;

/************************************************************************************************/
/* l.	Modification de la table d1. On ne conserve que les observations dont la valeur sur     */
/* la variable ratio est supérieur à la valeur sur la variable Fk calculé à l'étape précédente. */
/************************************************************************************************/
data d1;
set d1;
where ratio > FFkk;
run;

/******************************************************************************/
/* m.	Nouvelle boucle, pour chaque variable comprise dans le paramètre sps. */ 
/******************************************************************************/

/****************************************************************************************************/
/* i.	On calcule le vecteur temp par la division de chaque variable comprise dans le paramètre    */
/* sps (prise une à une dans la boucle) de Xsc par la variable enregistrée dans le paramètre NHM et */ 
/* qui appartient à Xsc.                                                                            */
/****************************************************************************************************/

/*1*/ data XSC_1 (keep= &sps. &NHM.);
set Xsc;
run;

/*2*/ proc contents data = Xsc_1
              out = Xsc_1_contents;
run;

/* 2 bis */ proc sort data = Xsc_1_contents out = Xsc_1_contents; by varnum; run;

/*3*/proc sql;
select distinct Name into:choosesps separated by ' ' from Xsc_1_contents where Name not in ("&NHM.");
select count (distinct NAME) into:nbchoosesps from Xsc_1_contents where Name not in ("&NHM.");
quit;

%PUT les variables de choosesps = &choosesps.;

%Do j=1 %to &nbchoosesps.; /* do numero 25 = m.Nouvelle boucle, pour chaque variable comprise dans le paramètre sps. */

%LET varspschosen = %scan(&choosesps.,&j., ' ');

data temp (keep= &varspschosen.);
set XSC_1;
&varspschosen. = &varspschosen. / &NHM.;
run;

/*************************************************************/
/* ii.	On crée le vecteur temp3 équivalent à la table temp. */
/*************************************************************/
data temp3;
set temp;
run;

/*****************************************************************/
/* iii.	Si le paramètre Exp.zeros est différent de la valeur y   */
/* et que j n'est pas inclus dans le paramètre inc.id (inc.id    */
/* est un vecteur reprenant les indices des variables comprises  */
/* dans les paramètres H1Inc et H2Inc dans le vecteur sps) alors */ 
/* on ne garde que les valeurs supérieures à 0 dans les vecteurs */
/* temp3 et temp.                                                */
/*****************************************************************/

/*  if(Exp.zeros!="y" & !j%in%inc.id) { 
	                                      temp3=temp[temp>0]  
										  temp=temp3  
									  } */

%If &Exp_zeros. ne y and not %index(&inc_id.,&j.) %then %do; /* do numero 26 = Si le paramètre Exp.zeros est différent de la valeur y et que j n'est pas inclus dans le paramètre inc.id (inc.id est un vecteur reprenant les indices des variables comprises dans les paramètres H1Inc et H2Inc dans le vecteur sps) alors on ne garde que les valeurs supérieures à 0 dans les vecteurs temp3 et temp.*/
data temp;
set temp;
array numtemp _NUMERIC_;

do over numtemp; /* do numero 27 */
if numtemp < 0 then delete;
end; /* end numero 27 */

run;

data temp3;
set temp;
run;

%end; /* end numero 26 */



/***************************************************************************************************/
/* iv.Si le paramètre Inc.zeros est différent de la valeur y et que j est inclus dans le paramètre */
/* inc.ind alors on ne garde que les valeurs supérieures à 0 dans temp3, temp reste, lui, inchangé.*/
/***************************************************************************************************/
%if &Inc_Zeros. ne y and %index(&inc_id.,&j.) %then %do; /* do numero 28 = Si le paramètre Inc.zeros est différent de la valeur y et que j est inclus dans le paramètre inc.ind alors on ne garde que les valeurs supérieures à 0 dans temp3, temp reste, lui, inchangé. */

data temp3;
set temp3;
array numtemp3 _NUMERIC_;

do over numtemp3; /* do over 29 */
if numtemp3 < 0 then delete;
end; /* end numero 29 */

run;

data temp;
set temp;
run;

%end; /* end numero 28 = Si le paramètre Inc.zeros est différent de la valeur y et que j est inclus dans le paramètre inc.ind alors on ne garde que les valeurs supérieures à 0 dans temp3, temp reste, lui, inchangé. */

/***************************************************************************************************/
/* v. Avec la fonction extreme précédemment définie, on calcule pour chaque colonne de temp3,      */
/* les paliers extrêmes inférieurs et supérieurs. Ces deux valeurs sont placées dans la matrice Q3 */ 
/* dans les colonnes 1 (palier inférieur) et 2 (palier supérieur) à la ligne numéro j              */
/* (qui défini les itérations de la boucle).                                                       */
/***************************************************************************************************/
proc transpose data=temp3 out=temp3content; run;

data temp3content_test (keep=_name_ lower upper);
set temp3content;
Q1 = pctl(25,of COL:);
Q3 = pctl(75,of COL:);
lower = Q1 - &k1. * (Q3 - Q1);
upper = Q1 + &k1. * (Q3 - Q1);
run;

data testnicolas;
length _NAME_ $50.;
%if %sysfunc(exist(testnicolas)) %then %do; /* do numero 30 */
set temp3content_test 
testnicolas;
run;

proc sort data=testnicolas
          out= testnicolas nodupkey;
by _NAME_;
run;

data testnicolas;
set testnicolas;
if _NAME_ = " " then delete;
run;

proc sql;
create table testnicolas1 as
select a.NAME,a.Varnum,b.lower,b.upper
from Xsc_1_contents as a 
left join testnicolas as b
on a.NAME = b._NAME_
;
quit;

proc sort data=testnicolas1
out= testnicolas2;
by varnum;
run;

data Q3 (drop=varnum);
set testnicolas2;
if NAME = "&NHM." then delete;
run;



/*********************************************************************************/
/* vi. Si le paramètre side est égal à "upper", le paramètre idx prend comme     */
/* valeur les indices des valeurs du vecteur temp qui sont supérieures au palier */ 
/* supérieur pour la ligne j.                                                    */
/*********************************************************************************/
%if &side. = upper %then %do; /* do numero 31 = si le paramètre side est egale à upper */
data temp_1;
set temp;
numero_ligne = _N_;
run;

proc contents data= temp_1 out= temp_2; run;

proc sql;
select NAME into:varupper from temp_2 where NAME ne "numero_ligne";
quit;

data Q3upper(keep= NAME upper);
set Q3;
where NAME = "&varupper.";
run;

proc transpose data=temp_1 out=temp_3;
id numero_ligne;
var &varupper.;
run;

data temp_4;
merge Q3upper temp_3 (drop=_Name_);
run;

proc contents data=temp_4 out=temp_5; run;

proc sql;
select distinct (NAME) into:varuppertemp5 separated by " " from temp_5 where NAME not in ("NAME" "upper");
quit;

%local aa dim_choosevartemp5  varchooseuppertemp5;

%LET dim_choosevartemp5 = %sysfunc(countw(&varuppertemp5.));

data temp_6;
set temp_4;

%Do aa=1 %TO &dim_choosevartemp5.; /* do numero 32 */
%LET varchooseuppertemp5 = %scan(&varuppertemp5.,&aa.);
if upper > "&varchooseuppertemp5."n then do; /* do numero 33 */
drop "&varchooseuppertemp5."n;
end; /* end numero 33 */
%end; /* end numero 32 */

run;

proc contents data=temp_6 out=temp_7; run;

data temp_8(keep=NAME);
set temp_7;
where NAME not in ("NAME" "upper");
run;

data idx (keep=idx);
set temp_8;
idx = input(NAME,8.);
run;

proc sql;
select distinct idx into:idx separated by " " from idx;
quit;

%end; /* end numero 31 = si le paramètre side est egale à upper */

/*********************************************************************************/
/* vii.	Si le paramètre side est égal à "lower", le paramètre idx prend comme    */
/* valeur les indices des valeurs du vecteur temp qui sont inférieures au palier */ 
/* inférieur pour la ligne j.                                                    */
/*********************************************************************************/

%if &side. = lower %then %do; /* do numero 34 = Si le paramètre side est égal à "lower" */
data temp_1;
set temp;
numero_ligne = _N_;
run;

proc contents data= temp_1 out= temp_2; run;

proc sql;
select NAME into:varlower from temp_2 where NAME ne "numero_ligne";
quit;

data Q3lower(keep= NAME lower);
set Q3;
where NAME = "&varlower.";
run;

proc transpose data=temp_1 out=temp_3;
id numero_ligne;
var &varlower.;
run;

data temp_4;
merge Q3lower temp_3 (drop=_Name_);
run;

proc contents data=temp_4 out=temp_5; run;

proc sql;
select distinct (NAME) into:varlowertemp5 separated by " " from temp_5 where NAME not in ("NAME" "lower");
quit;

%local aa dim_choosevartemp5  varchooselowertemp5;

%LET dim_choosevartemp5 = %sysfunc(countw(&varlowertemp5.));

data temp_6;
set temp_4;

%Do aa=1 %TO &dim_choosevartemp5.; /* do numero 35*/
%LET varchooselowertemp5 = %scan(&varlowertemp5.,&aa.);
if lower > "&varchooselowertemp5."n then do; /* do numero 36  */
drop "&varchooselowertemp5."n;
end; /* end numero 36*/
%end; /* end numero 35*/

run;

proc contents data=temp_6 out=temp_7; run;


data temp_8(keep=NAME);
set temp_7;
where NAME not in ("NAME" "lower");
run;

data idx (keep=idx);
set temp_8;
idx = input(NAME,8.);
run;

proc sql;
select distinct idx into:idx separated by " " from idx;
quit;

%end; /* end numero 34 = si le paramètre side est egale à lower */


/*********************************************************************************/
/* viii. Si le paramètre side est égal à "both", le paramètre idx prend comme    */
/* valeur les indices des valeurs du vecteur temp qui sont supérieures au palier */ 
/* supérieur ou inférieures au palier inférieure pour la ligne j.                */
/*********************************************************************************/
%if &side. = both %then %do; /* do numero 37 = Si le paramètre side est égal à "both" */

data temp_1;
set temp;
numero_ligne = _N_;
run;

proc contents data= temp_1 out= temp_2; run;

proc sql;
select NAME into:varboth from temp_2 where NAME ne "numero_ligne";
quit;

data Q3both (keep= NAME lower upper);
set Q3;
where NAME = "&varboth.";
run;

proc transpose data=temp_1 out=temp_3;
id numero_ligne;
var &varboth.;
run;

data temp_4;
merge Q3both temp_3 (drop=_Name_);
run;

proc contents data=temp_4 out=temp_5; run;

proc sql;
select distinct (NAME) into:varbothtemp5 separated by " " from temp_5 where NAME not in ("NAME" "lower" "upper");
quit;

%local aa dim_choosevartemp5  varchoosebothtemp5;

%LET dim_choosevartemp5 = %sysfunc(countw(&varbothtemp5.));

data temp_6;
set temp_4;

%Do aa=1 %TO &dim_choosevartemp5.; /* do numero 38 */
%LET varchoosebothtemp5 = %scan(&varbothtemp5.,&aa.);
if lower > "&varchoosebothtemp5."n or upper > "&varchoosebothtemp5."n then do; /* do numero 39*/
drop "&varchoosebothtemp5."n;
end; /* end numero 39*/
%end; /* end numero 38 */

run;

proc contents data=temp_6 out=temp_7; run;

data temp_8(keep=NAME);
set temp_7;
where NAME not in ("NAME" "lower" "upper");
run;

data idx (keep=idx);
set temp_8;
idx = input(NAME,8.);
run;

proc sql;
select distinct idx into:idx separated by " " from idx;
quit;


%end; /* end numero 37 = Si le paramètre side est egale à both */

/*******************************************************************/
/* ix.	idx est donc un vecteur, reprenant les indices des valeurs */
/* extrêmes du vecteur temp.                                       */
/*******************************************************************/


/***************************************************************/
/* x.	Si idx comprend au moins une valeur et que la table d1 */ 
/* comprend au moins une ligne, alors :                        */
/***************************************************************/
proc contents data=idx out=idxcontents; run;

proc sql;
select NOBS into:nobsidx from idxcontents;
quit;

proc contents data=d1 out=d1contents; run;

proc sql;
select NOBS into:nobsd1 from d1contents;
quit;

%if &nobsidx. ne 0 and &nobsd1. ne 0 %then %do; /* do numero 40 = Si idx comprend au moins une valeur et que la table d1 comprend au moins une ligne, alors : */

/******************************************************************************************/
/* 1. On crée la table iX qui est une sous table de Xsc pour les lignes d'indices compris */ 
/* dans idx et pour les variables comprises dans le paramètre HID.                        */
/******************************************************************************************/
data Xsc;
set Xsc;
numero_ligne = _N_;
run;

data iX (keep= &HID.);
set Xsc;
where numero_ligne in (&idx.);
run;

data Ix_1(keep= Ix));
set Ix;
Ix = input(&HID.,8.);
run;

proc sql;
select distinct Ix into:Ix separted by " " from Ix_1;
quit;

/*******************************************************************************************/
/* 2.	On crée la table temp qui est une sous table de d1, qui garde toutes les variables */         
/* mais uniquement les lignes pour lesquelles la valeur sur la variable comprise dans le   */
/* paramètre HID est incluse dans le vecteur iX.										   */
/*******************************************************************************************/
data d1_1;
set d1;
&HID._1 = input(&HID.,8.);
run;


data temp(drop= &HID._1);
set d1_1;
where &HID._1 in (&Ix.);
run;


/******************************************************/
/* 3.	Si la table temp comprend au-moins une ligne: */
/******************************************************/
proc contents data=temp out=tempcontents ; run;

proc sql;
select nobs into:nobstemp from tempcontents;
run;

%if &nobstemp. ne 0 %then %do; /* do numero 41 = Si la table temp comprend au-moins une ligne : */

/**************************************************************/
/* a. On crée le vecteur allrec3 composé du paramètre allrec3 */ 
/* et de la colonne HID de la table temp.                     */
/**************************************************************/
/*data allrec3;
set temp (keep=&HID.);
run;*/

data allrec3;
set temp(keep=&HID. rename=(&HID.=allrec3)) allrec3;
run;

data allrec3;
set allrec3;
where allrec3 ne " ";
run;

/***********************************************************************************/
/* b.	Pour chaque valeur de j (itération de la boucle), on complète la valeur de */ 
/* la matrice stat3 pour la ligne j et la première colonne par le rapport entre le */
/* nombre de ligne de la table temp et le nombre de ligne de la table dd.          */
/***********************************************************************************/
proc contents data= &Country_imported._AfterRecodings
              out= ddcontents;
run;

proc sql;
select nobs into:nobsdd from ddcontents;
quit;

data stat3;
set stat3;
var1 = &nobstemp./&nobsdd.;
run;

%end; /* end numero 41 = Si la table temp comprend au-moins une ligne */

%end; /* end numero 40 = Si idx comprend au moins une valeur et que la table d1 comprend au moins une ligne, alors : */

%end; /* end numero 30 */

%end; /* end numero 25 = m.Nouvelle boucle, pour chaque variable comprise dans le paramètre sps. */


/*****************************************************/
/* n. On crée la table d2 équivalente à la table dd. */
/*****************************************************/
data d2;
set &Country_imported._AfterRecodings;
run;

/**********************/
/* en attente de Paul */
/**********************/

/*******************************************************************/
/* o. Dans la table d2 on crée la colonne ratio qui est le rapport */ 
/* entre SumW et la valeur du paramètre size.                      */
/*******************************************************************/
data d2;
merge d2 sumW;
ratio = sumW/&ctr_t.;
run;

/***********************************************************************************/
/* p. Création de la table FFkk construite par application de la fonction          */
/* d'agrégation des catégories (déjà utilisée dans les scénarios 1 et 3) sur       */
/* la table d2 ne comprenant que les variables enregistrées dans le paramètre      */
/* stratum et avec la variable enregistrée dans le paramètre WEIGHT comme variable */ 
/* de pondération. On ne garde de cette agrégation que la colonne Fk.              */
/***********************************************************************************/
%Aggregation(tableentree = d2 ,tablesortie = FFkk , varchoisies = &stratum.);

data FFkk (rename=(big_f = Fk));
set FFkk;
run;
/*******************************************************************************************/
/* q. On réduit la table d2 aux observations dont la valeur sur la variable ratio est       */
/* plus grande que la valeur de la colonne Fk de la table FFkk pour la ligne correspondante.*/
/********************************************************************************************/
data d2;
merge d2 FFkk;
run;

data d2;
set d2;
where ratio > Fk;
run;


/****************************************************************************/
/* r. Si une variable "individual income" est enregistrée dans le paramètre */ 
/* InInc (créé dans le script manage_progs à la ligne 192).                 */
/****************************************************************************/
/*%if %symexist(&Ininc.) %then %do;
%put %nrstr(%symexist(&Ininc.)) = TRUE;
%end;*/

/*%else %do;
data nicolasabcd;
set d1;
run;
%end;*/

%if &Ininc. ne "" %then %do; /* do numero 42 = Si une variable "individual income" est enregistrée dans le paramètre InInc (créé dans le script manage_progs à la ligne 192) */

/**********************************************************************************************/
/* i. On crée temp, un vecteur issu de la table dd dont on garde uniquement la variable       */
/* enregistrée dans le paramètre InInc. Cette variable est transformée en variable numérique. */
/**********************************************************************************************/
data temp (keep= &Ininc.);
set &Country_imported._AfterRecodings;
run;

proc contents data=temp out=contentstemp; run;

proc sql;
select Type into:vartype from contentstemp;
quit;

%if &vartype. eq 1 %then %do; /* do numero 43 */
data temp (keep= &Ininc.);
set &Country_imported._AfterRecodings;
run;
%end; /* end numero 43 */

%else %do; /* do numero 44 */
data temp (keep= &Ininc._1 rename=(&Ininc._1 = &Ininc.));
set &Country_imported._AfterRecodings;
&Ininc._1 = input(&Ininc.,8.);
run;
%end; /* end numero 44 */

/**********************************************************************/
/* ii. Si le paramètre Inc.zeros est différent de "y", on ne conserve */
/* que les valeurs de temp plus grandes que 0.                        */
/**********************************************************************/
%if &Inc_Zeros. ne y %then %do; /* do numero 45 */
data temp;
set temp;
where &Ininc. > 0;
run;
%end; /* end numero 45 */

/*************************************************************/
/* iii.	On crée le vecteur q à l'aide de la fonction extreme */
/* appliquée sur le vecteur temp et avec le paramètre k1.    */
/*************************************************************/
proc transpose data=temp out=contenttempextrem; run;

data contenttempextrem (keep=_name_ lower upper);
set contenttempextrem;
Q1 = pctl(25,of COL:);
Q3 = pctl(75,of COL:);
lower = Q1 - &k1. * (Q3 - Q1);
upper = Q1 + &k1. * (Q3 - Q1);
run;

data Q (keep=NAME lower upper);
set contenttempextrem;
attrib NAME length=$32.;
NAME = put(_NAME_,32.);
run;

/********************************************************************************/
/* iv. On ajoute à la matrice Q3 une dernière ligne reprenant les valeurs de q. */
/********************************************************************************/
data Q3;
set Q3 Q;
run;

/***********************************************************************************/
/* v. Si le paramètre side est égal à "upper", le paramètre idX prend comme valeur */ 
/* les indices des lignes de la table d2 dont la variable comprise dans InInc est  */ 
/* plus grande que le palier supérieur contenu dans q.                             */
/***********************************************************************************/
%if &side. = upper %then %do; /* do numero 46 = Si le paramètre side est égal à "upper", le paramètre idX prend comme valeur les indices des lignes de la table d2 dont la variable comprise dans InInc est plus grande que le palier supérieur contenu dans q.*/

data d2_1;
set d2;
numero_ligne = _N_ ;
run;

proc sql;
select upper into:palsupq from Q3 where NAME = "&Ininc.";
run;

data d2_1;
set d2_1;
where &InInc. > &palsupq.;
run;

data idX (keep= numero_ligne rename=(numero_ligne = idx));
set d2_1;
run;

proc sql;
select distinct idx into:idx separated by " " from idX;
quit;

%end; /* end numero 46 = Si le paramètre side est égal à "upper", le paramètre idX prend comme valeur les indices des lignes de la table d2 dont la variable comprise dans InInc est plus grande que le palier supérieur contenu dans q.*/

/**************************************************************************************************/
/* vi. Si le paramètre side est égal à "lower", le paramètre idX prend comme valeur               */
/* les indices des lignes de la table d2 dont la variable comprise dans InInc est plus petite que */
/* le palier inférieur contenu dans q 															  */ 
/**************************************************************************************************/
%if &side. = lower %then %do; /* do numero 47 = Si le paramètre side est égal à "lower", le paramètre idX prend comme valeur les indices des lignes e la table d2 dont la variable comprise dans InInc est plus petite que le palier inférieur contenu dans q */

data d2_1;
set d2;
numero_ligne = _N_ ;
run;

proc sql;
select lower into:palinfq from Q3 where NAME = "&Ininc.";
run;

data d2_1;
set d2;
where &InInc. < &palinfq.;
run;

data idX (keep= numero_ligne rename=(numero_ligne = idx));
set d2_1;
run;

proc sql;
select distinct idx into:idx separated by " " from idX;
quit;

%end; /* end numero 47 = Si le paramètre side est égal à "lower", le paramètre idX prend comme valeur les indices des lignes e la table d2 dont la variable comprise dans InInc est plus petite que le palier inférieur contenu dans q */

/************************************************************************************/
/* vii.	Si le paramètre side est égal à "both", le paramètre idX prend comme valeur */ 
/* les indices des lignes de la table d2 dont la variable comprise dans InInc est   */ 
/* plus petite que le palier inférieur contenu dans q ou plus grande que le palier  */ 
/* supérieur contenu dans q.                                                        */
/************************************************************************************/
%if &side. = both %then %do; /* do numero 48 = Si le paramètre side est égal à "both", le paramètre idX prend comme valeur les indices des lignes de la table d2 dont la variable comprise dans InInc est plus petite que le palier inférieur contenu dans q ou plus grande que le palier supérieur contenu dans q.*/
data d2_1;
set d2;
numero_ligne = _N_ ;
run;

proc sql;
select upper into:palsupq from Q3 where NAME = "&Ininc.";
select lower into:palinfq from Q3 where NAME = "&Ininc.";
run;

data d2_1;
set d2_1;
where &InInc. > &palsupq. or &InInc. < &palinfq.;
run;

data idX (keep= numero_ligne rename=(numero_ligne = idx));
set d2_1;
run;

proc sql;
select distinct idx into:idx separated by " " from idX;
quit;

%end; /* end numero 48 = Si le paramètre side est égal à "both", le paramètre idX prend comme valeur les indices des lignes de la table d2 dont la variable comprise dans InInc est plus petite que le palier inférieur contenu dans q ou plus grande que le palier supérieur contenu dans q.*/

/***********************************************************************************/
/* viii. idX est donc un vecteur, reprenant les indices des valeurs extrêmes de la */ 
/* variable comprise dans le paramètre InInc de la table d2.                       */
/***********************************************************************************/

/******************************************************************************************/
/* ix. Si idX comprend au moins une valeur et que la table d2 comprend au moins une ligne */
/* alors : 																				  */
/******************************************************************************************/
proc contents data=idx out=idxcontents; run;

proc sql;
select nobs into:nobsidx from idxcontents;
quit;

proc contents data=d2 out=d2contents; run;

proc sql;
select nobs into:nobsd2 from d2contents;
quit;

%if &nobsidx. ne 0 and &nobsd2. ne 0 %then %do; /* do numero 49 = Si idX comprend au moins une valeur et que la table d2 comprend au moins une ligne alors : */

/*************************************************************************/
/* 1. On crée temp une sous-table de d2 conservant uniquement les lignes */
/* correspondant aux indices idX. 										 */
/*************************************************************************/
data temp;
set d2;
numero_ligne = _N_;
run;

data temp (drop= numero_ligne);
set temp;
where numero_ligne in (&idx.);
run;

/********************************************/
/* 2.	Si temp compte au-moins une ligne : */
/********************************************/
proc contents data=temp out=tempcontents; run;

proc sql;
select nobs into:nobstemp from tempcontents;
quit;

%if &nobstemp. ne 0 %then %do; /* do numero 50 = Si temp compte au-moins une ligne */

/*****************************************************************************************************/
/* a. On crée allrec3, un vecteur composé de allrec3 et des valeurs de la variable comprise dans HID */
/* de la table temp 																				 */
/*****************************************************************************************************/
/*data allrec3;
set temp (keep=&HID.);
run;*/

data allrec3;
set temp(keep=&HID. rename=(&HID. = allrec3)) allrec3;
run;

/**********************************************************************************/
/* b. On complète stat3 en lui ajoutant une ligne calculée comme le rapport entre */
/* le nombre de ligne de temp et le nombre de ligne de dd.                        */
/**********************************************************************************/
proc contents data=&Country_imported._AfterRecodings
              out= ddcontents;
run;

proc sql;
select nobs into:nobsdd from ddcontents;
quit;

data var1;
var1 = &nobstemp./&nobsdd.;
run;

data stat3;
set stat3 var1;
run;

%end; /* end numero 50 = Si temp compte au-moins une ligne */

%end; /* end numero 49 = Si idX comprend au moins une valeur et que la table d2 comprend au moins une ligne alors : */

%end; /* end numero 42 = Si une variable "individual income" est enregistrée dans le paramètre InInc (créé dans le script manage_progs à la ligne 192) */



/*************************************************************************************/
/* s. Si allrec3 n'est pas vide, on crée allhh3 en ordonnant les valeurs uniques de  */
/* allrec3. Pas valeur unique, j'entend les différentes valeurs possibles prises par */
/* allrec3 sans duplicata.                                                           */
/*************************************************************************************/
data allrec3test;
set allrec3;
if allrec3 = " " then flag = "yes"; else flag = "no";
run;

proc sql;
select flag into:flagallrec3 from allrec3test;
quit;

%if &flagallrec3. eq "no" %then %do; /* do numero 51 = Si allrec3 n'est pas vide, on crée allhh3 en ordonnant les valeurs uniques de allrec3. Pas valeur unique, j'entend les différentes valeurs possibles prises par allrec3 sans duplicata.*/
proc sort data=allrec3 out=allhh3 nodupkey; 
by allrec3; 
run;

data allhh3 (rename=(allrec3 = allhh3));
set allhh3;
run;

%end; /* end numero 51 = Si allrec3 n'est pas vide, on crée allhh3 en ordonnant les valeurs uniques de allrec3. Pas valeur unique, j'entend les différentes valeurs possibles prises par allrec3 sans duplicata */

/*********************************/
/* t.	Si ctr_s est égal à deux */
/*********************************/
%if &ctr_s. = 2 %then %do; /* do numero 52 = Si ctr_s est égal à deux */

/***********************************************************************************/
/* i.	On défini le nom du fichier et des folders :                               */
/* "ContVarsOutput/codepays/_spont_tvaleurdesize_s1_hh_at_risk.txt"                */
/* ii.	On essaie d'ouvrir ce fichier. S'il existe, on le nomme hh.at.risk         */
/* iii.	S'il existe et ne renvoie donc pas de message d'erreur, alors on           */ 
/* crée allhh3 qui reprend les valeurs qui sont à la fois dans allhh3 et la        */
/* colonne V1 de la table hh.at.risk. On classe ces valeurs dans l'ordre croissant */
/***********************************************************************************/
%if %sysfunc(fileexist("&path_contvarsoutput./&Country_imported._spont_t&ctr_t._s1_hh_at_risk.txt")) %then %do; /* do numero 53 = On essaie d'ouvrir ce fichier. S'il existe, on le nomme hh.at.risk*/

proc import datafile = "&path_contvarsoutput./&Country_imported._spont_t&ctr_t._s1_hh_at_risk.txt"
            out= HH_at_risk
			dbms=dlm replace;
			delimiter = ',';
			
            getnames = no;
run;

/*data HH_at_risk;
infile "&path_contvarsoutput.\&Country_imported._spont_t&ctr_t._s1_hh_at_risk.txt";
run;*/

proc sql;
create table testallhh3 as
select a.allhh3 , b.var1
from allhh3 as a
left join HH_at_risk as b
on a.allhh3 = b.var1
;
quit;

data allhh3(keep=allhh3);
set testallhh3;
if allhh3 ne var1 or var1 = " " then delete;
run;

proc sort data=allhh3 out=allhh3; by allhh3; run;

%end; /* end numero 53 = On essaie d'ouvrir ce fichier. S'il existe, on le nomme hh.at.risk */

%end; /* end numero 52 = Si ctr_s est égal à deux */

/*************************************************/
/* u. Si la allhh3 contient au-moins une valeur, */
/*************************************************/
proc contents data=allhh3 out=contentsallhh3; run;

proc sql;
select nobs into:nobsallhh3 from contentsallhh3;
quit;

%if &nobsallhh3. ne 0 %then %do; /* do numero 54 = Si la allhh3 contient au-moins une valeur */

/*********************************************************************************/
/* i. on crée le paramètre all.fractions.rec3 calculé comme le rapport           */
/* entre le nombre d'éléments dans allrec3 et le nombre de ligne de la table dd. */
/*********************************************************************************/
proc contents data=&Country_imported._AfterRecodings out=ddcontents; run;

proc sql;
select nobs into:nobsdd from ddcontents;
quit;

%LET all_fractions_rec3 = &nobsallhh3./&nobsdd.;

/**************************************************************************************/
/* ii.	Si la variable comprise dans le paramètre InInc est comprise dans la table dd */
/**************************************************************************************/
proc contents data=&Country_imported._AfterRecodings out=contentsdd; run;

proc sql;
select (NAME) from contentsdd where NAME = upcase("&Ininc."); 
quit;

%PUT &sqlobs.;

%if &sqlobs. > 0 %then %do; /* do numero 55 = Si la variable comprise dans le paramètre InInc est comprise dans la table dd */

/********************************************************************************/
/* 1. On crée la table tab, comprenant les variables variable  et Frac.of.risk. */
/********************************************************************************/

/******************************************************************************************/
/* 2. La variable "variable" liste: la chaine de caractère "All var.", toutes les valeurs */ 
/* de sps sauf la première et les valeurs de InInc.                                       */
/******************************************************************************************/
data tab;
length variable $50.;
/*input variable $;
datalines;
All_var*/
variable = "All var";
;
run;

data testsps;
set sps;
numero_ligne = _N_;
run;

data testsps (rename=(sps = variable));
set testsps;
where numero_ligne ne 1;
run;

data tab;
set tab testsps;
run;

data incvalues;
variable = "&Ininc.";
run;

data tab;
set tab incvalues;
run;


/*************************************************************************************/
/* 3. La variable Frac.of.risk liste: les valeurs de all.fractions.rec3 et les       */
/* valeurs de stat3. (derniere ligne 1ere colonne) Toutes ces valeurs sont arrondies */ 
/* à 6 décimales.                                                                    */
/*************************************************************************************/
proc contents data=sps out=contentsps; run;

proc sql;
select nobs into:nobssps from contentsps;
quit;

%LET nobssps = %eval(&nobssps);

data droite;

%do i=1 %to &nobssps.; /* do numero 56 */
   all_fractions_rec3 = round(&all_fractions_rec3.,0.0000001);
   output;
%end; /* end numero 56 */
set stat3(rename=(var1 = all_fractions_rec3));
output;
run;

data tab;
set tab;
set droite;
run;

%end; /* end numero 55 = Si la variable comprise dans le paramètre InInc est comprise dans la table dd */


/******************************************************************/
/* iii.	Si la variable comprise dans le paramètre InInc n'est pas */
/* comprise dans la table dd,                                     */
/******************************************************************/
proc contents data=&Country_imported._AfterRecodings out=contentsdd; run;

proc sql;
select (NAME) from contentsdd where NAME = upcase("&Ininc."); 
quit;

%if &sqlobs. = 0 %then %do; /* do numero 57 = Si la variable comprise dans le paramètre InInc n'est pas comprise dans la table dd */
data tab;
length variable $50.;
input variable $;
datalines;
All_var
;
run;

data testsps;
set sps;
numero_ligne = _N_;
run;

data testsps (rename=(sps = variable));
set testsps;
where numero_ligne ne 1;
run;

data tab;
set tab testsps;
run;

proc contents data=sps out=contentsps; run;

proc sql;
select nobs into:nobssps from contentsps;
quit;

%LET nobssps = %eval(&nobssps);

data droite;

%do i=1 %to &nobssps.; /* do numero 56 */
   all_fractions_rec3 = round(&all_fractions_rec3.,0.0000001);
   output;
%end; /* end numero 56 */
set stat3(rename=(var1 = all_fractions_rec3));
output;
run;

data tab;
set tab;
set droite;
run;
%end; /* end numero 57 = Si la variable comprise dans le paramètre InInc n'est pas comprise dans la table dd */

/********************************************************************************************/
/* iv.	On enregistre la table tab sous le nom :                                            */
/* ContVarsOutput/(codepays)/_spont_t(valeurdesize)_s(valeurdectr_s).txt                    */
/*(les chaine de caractère entre parenthèse sont à remplacer par les valeurs en questions). */
/********************************************************************************************/
proc export data=tab
            outfile="&path_contvarsoutput2./&Country_imported._spont_t&ctr_t._s&ctr_s..txt"
			dbms = tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */

			delimiter = "," ; /* the separator will be ","*/

			putnames = no; /* we do not want the name of the variables to appear in the final outputs */

run;


/************************************************************************************/
/* v.	On enregistre la table allhh3 sous le nom :									*/
/* ContVarsOutput/(codepays)/_spont_t(valeurdesize)_s(valeurdectr_s)_hh_at_risk.txt */
/************************************************************************************/
proc export data=allhh3
    outfile= "&path_contvarsoutput2./&Country_imported._spont_t&ctr_t._s&ctr_s._hh_at_risk.txt"
dbms = tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */

			delimiter = "," ; /* the separator will be ","*/

			putnames = no; /* we do not want the name of the variables to appear in the final outputs */

run;
%end; /* end numero 54 = Si la allhh3 contient au-moins une valeur */

/***********************************************************************************/
/* v.	Si allhh3 ne contient pas de valeur, s'il est vide, alors on enregistre la */
/* chaine de caractère "Zero observation are at risk" sous le nom :                */ 
/* ContVarsOutput/(codepays)/_spont_t(valeurdesize)_s(valeurdectr_s).txt           */
/***********************************************************************************/
%if &nobsallhh3. eq 0 %then %do; /* do numero 55 */

data allhh3zero;
var = "Zero observation are at risk";
run;

proc export data=allhh3zero
/*outfile*/ file = "&path_contvarsoutput2./&Country_imported._spont_t&ctr_t._&ctr_s..txt";
/*dbms = tab*/ /*replace;*/ /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */

			/*delimiter = "," ;*/ /* the separator will be ","*/

			/*putnames = no; */
run;

%end; /* end numero 55 */

/******************************************************************************/
/* w.	Si ctr_t et ctr_s sont égaux à 1 alors :                              */
/* i.	Les colonnes de la matrice Q3 sont nommées "lower" et "upper".        */
/* ii.	La matrice Q3 est sauvée sous le nom: ContVarsOutput/(codepays)_Q.txt */
/**************************************************************************** */
%if &ctr_t. = 1 and &ctr_s. = 1 %then %do; /* do numero 56 = Si ctr_t et ctr_s sont égaux à 1 alors : */
data Q3 (keep= lower upper);
set Q3;
run;

proc export data=Q3
            outfile = "&path_contvarsoutput2./&Country_imported._Q.txt"
			dbms = tab replace; /* dbms=tab We wish to write out our dataset as a tab-separated file, dbms specifies the type of data to export.....the option "replace" overwrites an existing file.if you do not specify replace, proc export does not overwrite an existing file */

			delimiter = "," ; /* the separator will be ","*/

			putnames = yes;
run;


%end; /* end numero 56 = Si ctr_t et ctr_s sont égaux à 1 alors : */






%end; /* end numero 22 = boucle ouverte pour couvrir deux scenarios */

%end; /* end numero 21 = boucle ouverte pour les valeurs comprises dans le vecteur size, je les ai defini dans les paramètres de la macro */

%mend ContVars;

%Contvars (size1 = 1000, size2 = 2500);




