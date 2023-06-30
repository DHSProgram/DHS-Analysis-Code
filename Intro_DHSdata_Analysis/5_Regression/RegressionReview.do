/******************************************************************************
	Purpose: Fitting a logistic regression using a binary outcome from DHS data
	Data input: The model dataset women's file (IR file)
	Author: Shireen Assaf
	Date Last Modified: May 3, 2023 by Shireen Assaf

Notes/Instructions:

* Please have the model dataset downloaded and ready to use. We will use the IR file.
* You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
* For the code below to work, you must save the dataset in the same folder as the Stata do file. 
* In this example, we will use the indicator of modern contraceptive use among women currently in a union.
* This indicator was also coded in the section on svy commands but among all women. 
* We will also apply the svyset and svy commands we have seen in the previous section. 
* This example only shows a simple logistic model for a binary outcome. 
* svy also supports other types of regressions including: 	Linear regression (using regress command), 
															Poisson (poisson command), 
															Negative binomial (using nbreg command)
******************************************************************************/


clear all
use ZZIR62FL.dta, clear

* svyset
gen wt= v005/1000000
svyset [pw=wt], psu(v021) strata(v023) singleunit(centered)

**** logistic regression ****

* outcome is modern contraceptive use among women currently in a union
recode v313 (3=1 Yes) (else=0 Yes) if v502==1, gen(modfp)
label variable modfp "modern contraceptive use"


*unadjusted with place of residence 
svy: logistic modfp i.v025 

**** change reference category (2 ways)
* 1 way - recode v025
recode v025 (2=0 rural) (1=1 urban), gen(resid)
svy: logistic modfp i.resid

* 2nd way, using ib
svy: logistic modfp ib2.v025

* put 2 after the ib because that is the label value I want to be the reference, in this case rural

*************************************

* multivariate models
svy: logistic modfp i.v025 i.v106 i.v013

* to check for corrlations
pwcorr v025 v106 v013 v190
* v025 and v190 are highly correlated so you may not want to not include them in the same model

* exporting results
svy: logistic modfp i.v025 i.v106 i.v013

*run the next line  to install outreg2 which is needed to output regression results 
*ssc install outreg2

outreg2 using regs.xls, eform stats(coef ci) sideway dec(1) label(insert) alpha(0.001, 0.01, 0.05) replace

* If you want to run another model and have the results appear in the
* same excel file as above, run your model below and use outreg2 with append

svy: logistic modfp i.v190 i.v106 i.v013
outreg2 using regs.xls, eform stats(coef ci) sideway dec(1) label(insert) alpha(0.001, 0.01, 0.05) append

*************************************
