/******************************************************************************
	Purpose: Setting the survey design for DHS data
	Data input: The model dataset women's file (IR file)
	Author: Shireen Assaf
	Date Last Modified: Jan 30, 2023 by Shireen Assaf

Notes/Instructions:

* Please have the model dataset downloaded and ready to use. We will use the IR file.
* You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
* For the code below to work, you must save the dataset in the same folder as the Stata do file. 
* For any analysis of DHS data that involves calculating the standard error, the survey design should be set. 
* This allows for using the svy commands in Stata that can be used for tabulations, regressions, etc. 
******************************************************************************/

clear all
use ZZIR62FL.dta, clear

numlabel, add

* To set the survey design you need three components: the sampling weight, the primary sampling unit, and the strata
* the primary sampling unit is v021
* the strata is v022 for most surveys but for older surveys you may need to compute the strata. Check the strata do file or the final report for this. 
* the sampling weight is v005 for the this file and must be dividing by 1000,000

* generate a weight variable 
gen wt=v005/1000000

*** Setting the survey design ***
svyset [pw=wt], psu(v021) strata(v022) singleunit(centered)

* the option singleunit(centered) is used to adjust for the case if there is single PSU within a stratum 

* now that we have set the survey design, we can use the "svy" commands. See below for some examples.

* Modern contraceptive use as an indicator
recode v313 (0/2=0 no) (3=1 yes), gen(modfp)
label var modfp "currently use a modern method"

*** Tabulations ***
* tabulations with confidence intervals
svy: tab modfp , ci

* tabulations with sampling error
svy: tab modfp , se

* two-way tabulation

svy: tab v106 modfp, row per ci se
* the "per" options gives us percentages instead of proportions. 
* this crosstabulation also gives the results of a Chi-square test of association

* to see how the svy command is used for regressions, please check the regression do file. 
