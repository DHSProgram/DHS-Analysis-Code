/*******************************************************************************************************************************
Program: 				PregOutcomes.do
Purpose: 				Calculate pregnancy outcomes (Births, Miscarriages, Abortions, Stillbirths)
Author: 				Tom Pullum
Date last modified:		Feb 9, 2023 by Tom Pullum 
						July 18, 2023 by Shireen Assaf to adapat code and add more notes for this project 

Description:
* Pregancy outcomes referred to generically as BMAS, for Births, Miscarriages, Abortions, Stillbirths
* Stata program to calculate the months pregnant (P) preceding BMAS codes.
* Illustrate with PKIR71FL.dta (Pakistan 2017-18 DHS) and all pregnancies in vcal_6.  
* Sequence them as in the table in the final report (Births, Stillbirths, Miscarriages, Abortions)
* An interval is censored if it is so close to the beginning of the calendar (the early months) that
* it is impossible to be sure of the number of preceding months of P's
If the data are perfect, the month of conception will be the first month with a "P". However, the woman may not know when she actually became pregnant.  It can happen that an abortion or miscarriage in the data is not preceded by ANY months with P.  DHS would usually say that the duration of the pregnancy is one plus the number of preceding months of "P".

The pregnancy outcome variable produced is "type" and can be tabulate by covariates. 
This program is different from the perinatal mortality code, CM_PMR.do, found in the DHS Program Code Share Library.
https://github.com/DHSProgram/DHS-Indicators-Stata/tree/master/Chap08_CM
The CM_PMR.do will calculate stillbirths and live births as well as perinatal mortality but excludes miscarriage and abortions. 

***************************************************************************/

* drops any saved programs. 
program drop _all

program calc_interval_length

* Construct a file with a separate record for each BMAS
* We look for strings that end in B, C, A, or S and are preceded (chronologically) by P's
* Allow for possible codes C, A that are not preceded by P

* mbi: months as months before interview. mbi=col-v018
* cmc: months in century month codes.     cmc=v017+80-col

* Because there is a reshape of the data, the data should be reduced to only the variables needed.
* For the program the following variables are needed: v001 v002 v003 v005 v017 v018 vcal_6 

* However, if there is interest to tabulate the pregnancy outcome by specific background variables, then they should be included as well. For instance, v024, v025, v106, and v190 are included below. 
keep v001 v002 v003 v005 v017 v018 v024 v025 v106 v190 vcal_6 

* Calculate the number of P's that immediately precede the BMAS, allowing for 0 to 11 
* Index the event by col, not cmc or mbi, and allow col to go from 1 to 79

* To reduce to events and intervals that are entirely included in the 60 months before the interview,
* in the loop below replace "80" with "60+v018"

quietly forvalues lcol=1/80 {
gen type_`lcol'=.
replace type_`lcol'=1 if substr(vcal_6,`lcol',1)=="B"
replace type_`lcol'=2 if substr(vcal_6,`lcol',1)=="S"
replace type_`lcol'=3 if substr(vcal_6,`lcol',1)=="C"
replace type_`lcol'=4 if substr(vcal_6,`lcol',1)=="A"
gen     interval_`lcol'= .
replace interval_`lcol'= 0 if                                  substr(vcal_6,`lcol'+1,1)~="P"  & `lcol'+1<=80
replace interval_`lcol'= 1 if substr(vcal_6,`lcol'+1,1) =="P" & substr(vcal_6,`lcol'+2,1)~="P"  & `lcol'+2<=80
replace interval_`lcol'= 2 if substr(vcal_6,`lcol'+1,2) =="PP" & substr(vcal_6,`lcol'+3,1)~="P"  & `lcol'+3<=80
replace interval_`lcol'= 3 if substr(vcal_6,`lcol'+1,3) =="PPP" & substr(vcal_6,`lcol'+4,1)~="P"  & `lcol'+4<=80
replace interval_`lcol'= 4 if substr(vcal_6,`lcol'+1,4) =="PPPP" & substr(vcal_6,`lcol'+5,1)~="P"  & `lcol'+5<=80
replace interval_`lcol'= 5 if substr(vcal_6,`lcol'+1,5) =="PPPPP" & substr(vcal_6,`lcol'+6,1)~="P"  & `lcol'+6<=80
replace interval_`lcol'= 6 if substr(vcal_6,`lcol'+1,6) =="PPPPPP" & substr(vcal_6,`lcol'+7,1)~="P"  & `lcol'+7<=80
replace interval_`lcol'= 7 if substr(vcal_6,`lcol'+1,7) =="PPPPPPP" & substr(vcal_6,`lcol'+8,1)~="P"  & `lcol'+8<=80
replace interval_`lcol'= 8 if substr(vcal_6,`lcol'+1,8) =="PPPPPPPP" & substr(vcal_6,`lcol'+9,1)~="P"  & `lcol'+9<=80
replace interval_`lcol'= 9 if substr(vcal_6,`lcol'+1,9) =="PPPPPPPPP" & substr(vcal_6,`lcol'+10,1)~="P" & `lcol'+10<=80
replace interval_`lcol'=10 if substr(vcal_6,`lcol'+1,10)=="PPPPPPPPPP" & substr(vcal_6,`lcol'+11,1)~="P" & `lcol'+11<=80
replace interval_`lcol'=11 if substr(vcal_6,`lcol'+1,11)=="PPPPPPPPPPP" & substr(vcal_6,`lcol'+12,1)~="P" & `lcol'+12<=80
}

reshape long type_ interval_, i(v001 v002 v003) j(col)
rename *_ *

drop if type==.
label variable type "Type of pregnancy outcome"
label define type 1 "Live birth" 2 "Stillbirth" 3 "Miscarriage" 4 "Abortion"
label values type type

label variable interval "Preceding months of P"
replace interval=99 if interval==.
label define interval 99 "Censored"
label values interval interval

*tab interval type
*tab interval type [iweight=v005/1000000]

tab type [iweight=v005/1000000]

save months_pregnant.dta, replace

end

***************************************************************************
***************************************************************************
***************************************************************************
***************************************************************************
* Execution begins here

* Specify your workspace, the data should be saved here as well unless you specify a different path for the data.
* cd ...

********************************
use "PKIR71FL.DTA" , clear
* In this survey the BMAS are in vcal_6; C is the symbol for Miscarriage 
********************************

* run the program
calc_interval_length
