/****************************************************************************
Program:				GR_stillbirth.do
Purpose:				Stillbirth model analysis - determinants of stillbirth using the GR datafile
Author:					Sara Riese
Date last modified:		Aug 09, 2023 by Shireen Assaf
****************************************************************************/

* list your GR datafiles
global grdata "KHGR81FL PHGR81FL NPGR81FL KEGR8AFL"  



foreach c in $grdata {

*open the data file from the folder with DHS data
cd "C:/Users/$user/ICF/Analysis - Shared Resources/Data/DHSdata"  //modify this to your working directory
use "`c'.DTA", clear

gen cn=substr("`c'",1,2)
scalar cn=cn[1]
local cn=cn

label define YN 0 "No" 1 "Yes"

*Drop pregnancies that ended before 7 months, and miscarriages/abortions. We are interested in stillbirth vs live births
keep if p20>=7 & (p32==1 | p32==2)

*******************************************
**** Coding Variables ****
*******************************************

*** Outcome ***

*Pregnancy ended in a stillbirth
gen stillbirth=0
replace stillbirth=1 if p32==2
label values stillbirth YN

*** Calculating the Stillbirth Rate ***

preserve

* Set length of history to use
* Here we use the past 5 years (59 months)
gen i=v008-p3+v018
gen callen = v018 + 59
gen beg = v018
gen end = callen

* Include only the five year period preceding the survey, and keep only births and stillbirths
keep if i >= beg & i <= end & (p32 == 1 | p32 == 2)

* calculate the stillbirth rate using weights
tab stillbirth [iw=v005/1000000]

restore

*** Covariates ***

*Urban/rural v025
recode v025 (1=0 "Urban") (2=1 "Rural"), gen(resid)
label var resid "Residence"

*Education level v106
recode v106 (0/1=0 "No/primary education") (2/3=1 "Secondary or Higher Education"), gen(edu)

*Marital status v501
recode v501 (0=0 "Never in Union") (1/5=1 "Ever Married"), gen(maritalstat)
 
*Employment status v731
recode v731 (0=0 "Not employed in last 12 months") (1/3=1 "Employed or employed at some point in the last 12 months") (8=9 "Don't know/missing"), gen(rc_empl)
label var rc_empl "Employment status"

*Wealth index v190

*Smoker v463a* BE SURE TO LOOK AT THE DISTRIBUTION OF THIS QUESTION, THERE MAY BE LARGE % OF MISSING DATA DUE TO SKIP PATTERN

*** The variables below use the pregnancy variables that start with p, this are similar to the birth history variables that start with b 

*Age at birth 
gen age_b=p3-v011
gen age_b_yr=int(age_b/12)
recode age_b_yr (min/25=1 "15-25") (26/35=2 "26-35") (36/50=3 "36-49"), gen(age_b_yr_cat)

*Primipara 
gen primi=0
replace primi=1 if pord==1

*History of stillbirth
gen sbpreg=.
replace sbpreg=pord if stillbirth==1
bysort caseid (sbpreg): replace sbpreg = sbpreg[1] if missing(sbpreg)
gen histsb=0 if pord<=sbpreg
replace histsb=1 if pord>sbpreg & sbpreg!=. 

*History of child death
gen ch_death=0
replace ch_death=1 if p5==0 & p32==1
gen deathpreg=.
replace deathpreg=pord if ch_death==1
bysort caseid (deathpreg): replace deathpreg = deathpreg[1] if missing(deathpreg)
gen hist_chdeath=0 if pord<=deathpreg
replace hist_chdeath=1 if pord>deathpreg & deathpreg!=. 

*Multiple pregnancy
gen multpreg=0
replace multpreg=1 if p0>=1 & p0!=.

*Gestational age at birth p20

*******************************************	
*** Preparing for analysis ***
*******************************************

* checking variables
foreach var of varlist v025 edu maritalstat rc_empl v190 v463a age_b_yr_cat primi-multpreg p20 {
	tab `var', m
}

* checking for correlations
pwcorr resid edu maritalstat rc_empl v190 v463a age_b_yr_cat primi histsb hist_chdeath multpreg p20
*v463a dropped due to high level of missing data
*histsb dropped due to lack of cases

global stillbirthGRcovs "resid edu maritalstat rc_empl v190 age_b_yr_cat primi hist_chdeath multpreg p20"
global istillbirthGRcovs "i.resid i.edu i.maritalstat i.rc_empl i.v190 i.age_b_yr_cat i.primi i.hist_chdeath i.multpreg i.p20"

*** Set the complex survey design ***
gen wt=v005/1000000

svyset [pw=wt], psu(v021) strata(v022) singleunit(centered)

**************************************************	
*** Model analysis using logistic regressions ***
**************************************************
*set working directory to save results in results folder
cd "C:/Users/$user/ICF/Stillbirth analysis/Results"  //modify this to your working directory

*** Bivariate associations ***
foreach x in $istillbirthGRcovs {
	
	svy:logistic stillbirth `x'  
		
	outreg2 using "GR_biregs_`cn'.xls", eform stats(coef ci) alpha(0.001, 0.01, 0.05) sideway dec(2) label(insert) noparen nocons append
}

*** Multivariate logistic model ***
svy: logistic stillbirth i.resid i.edu i.maritalstat i.rc_empl i.v190 i.age_b_yr_cat i.primi i.hist_chdeath i.multpreg i.p20

outreg2 using "GR_multiregs_`cn'.xls", eform stats(coef ci) alpha(0.001, 0.01, 0.05) sideway dec(2) label(insert) noparen nocons append


* save coded file
*set working director to save results in coded data folder
cd "C:/Users/$user/ICF/Stillbirth analysis/coded_data"  //modify this to your working directory
save "`cn'GR_coded.DTA", replace
}
