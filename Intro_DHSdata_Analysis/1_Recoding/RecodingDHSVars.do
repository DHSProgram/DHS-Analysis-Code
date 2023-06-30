/******************************************************************************
	Purpose: Recoding or creating new variables.
	Data input: The model dataset women's file (IR file)
	Author: Shireen Assaf
	Date Last Modified: Jan 26, 2023 by Shireen Assaf

Notes/Instructions:

* Please have the model dataset downloaded and ready to use. We will use the IR file.
* You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
* For the code below to work, you must save the dataset in the same folder as the Stata do file. 
* For this and other examples, you can check your work using the model dataset tables.
* This do file will show simple examples for creating new variables and how you can check them with the final report tables.
* For a more comprehensive code for creating DHS indicators, please visit the DHS Program code share library on Github: https://github.com/DHSProgram/DHS-Indicators-Stata
* You can download the repository or copy the code for the indicators you are interested in. 
******************************************************************************/


clear all
use ZZIR62FL.dta, clear

numlabel, add

**** Example 1
**** Recode current contraceptive use into a binary variable ****

lookfor contraceptive

tab v312, missing

* recode using gen and replace
gen contuse=0
replace contuse=1 if v312>=1
label variable contuse "current FP use"
label define contuse 0 No 1 Yes
label values contuse contuse

tab contuse

tab v312 contuse

*another way is
drop contuse
gen contuse=v312>=1
label variable contuse "current FP use"
label values contuse contuse

tab contuse

** Check your work
* check against the original variable
tab v312 contuse

* check against the final report Table 7.3
gen wt=v005/1000000
tab contuse [iw=wt]  //all women
tab contuse if v502==1 [iw=wt] // currently married women

* another way to recode using the recode command
recode v312 (0=0 No) (1/17=1 Yes), gen(contuse2)
label var contuse2 "current FP use"

tab contuse2
tab v312 contuse2

**Do NOT overwrite the original dataset, save as a different file
save ZZIR62coded.dta, replace 


******************************************************************************

* Example 2:
*** Number of ANC visits in 4 categories that match the table in the final report

*examine the original variable

lookfor antenatal
tab m14_1, m

* why are there missing values?  
tab v208, m

tab m14_1 v208, m 

* recode
recode m14_1 (0 = 0 "None") (1 = 1 "1") (2/3 = 2 "2-3") ///
(4/90 = 3 "4+")(98/99 = 9 "Don't know/missing"), gen(ancvisits)

*recode cases in v208 were coded as missing but should be DK
replace ancvisits=9 if v208!=0 & m14_1==. 

label var ancvisits "Number of ANC visits"

tab m14_1 ancvisits

* check against the final report Table 9.2
tab ancvisits [iw=wt]

**Do NOT overwrite the original dataset, save as a different file
save ZZIR62coded.dta, replace 


