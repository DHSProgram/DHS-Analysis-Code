/****************************************************************************
Program:				NR_stillbirth.do
Purpose:				Stillbirth model analysis - determinants of stillbirth using the NR datafile
Author:					Sara Riese
Date last modified:		Aug 09, 2023 by Shireen Assaf
****************************************************************************/

/******************************************************************************************************
Some health related variables of interest are only available in the NR file (all pregnancies in last 3 years)
*********************************************************************************************************/

* list your NR datafiles
global nrdata "KHNR81FL PHNR81FL NPNR81FL KENR8AFL" 

foreach c in $nrdata {
	
*open the data file from the folder with DHS data
cd "C:/Users/$user/ICF/Analysis - Shared Resources/Data/DHSdata"  //modify this to your working directory
use "`c'.DTA", clear

gen cn=substr("`c'",1,2)
local cn=cn[1]

*Drop pregnancies that ended before 7 months, and miscarriages/abortions. We are interested in stillbirth vs live births
keep if p20>=7 & (p32==1 | p32==2)

*******************************************
**** Coding Variables ****
*******************************************

*** Outcome ***

*Pregnancy ended in a stillbirth
gen stillbirth=0
replace stillbirth=1 if p32==2
label define YN 0 "No" 1 "Yes"
label values stillbirth YN

*** Covariates ***

*Urban/rural v025
recode v025 (1=0 "Urban") (2=1 "Rural"), gen(resid)
label var resid "Residence"

*Education level v106
recode v106 (0/1=0 "No/primary education") (2/3=1 "Secondary or Higher Education"), gen(edu)
 
*Marital status v501
recode v501 (0=0 "Never in Union") (1/5=1 "Ever Married"), gen(maritalstat)
 
*Employment status v731
//Employment status
recode v731 (0=0 "Not employed in last 12 months") (1/3=1 "Employed or employed at some point in the last 12 months") (8=9 "Don't know/missing"), gen(rc_empl)
label var rc_empl "Employment status"

*Wealth index v190

*Smoker v463a* BE SURE TO LOOK AT THE DISTRIBUTION OF THIS QUESTION, THERE MAY BE LARGE % OF MISSING DATA DUE TO SKIP PATTERN

*** The variables below use the pregnancy variables that start with p, this are similar to the birth history variables that start with b 

*Age at birth p3-v011
gen age_b=p3-v011
fre age_b
gen age_b_yr=int(age_b/12)
fre age_b_yr
recode age_b_yr (min/25=1 "12-25") (26/35=2 "26-35") (36/50=3 "36-50"), gen(age_b_yr_cat)

*Primipara (stillbirth) pord==1
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
*/

*Multiple pregnancy
gen multpreg=0
replace multpreg=1 if p0>=1 & p0!=.

* Gestational age at birth p20

*** health related variables ***

* ANC by type of provider
** Note: Please check the final report for this indicator to determine the categories and adjust the code and label accordingly. 
	gen rh_anc_pv = 6 if m2a! = .
	replace rh_anc_pv 	= 4 	if  m2g == 1 | m2h == 1 | m2k == 1 
	replace rh_anc_pv 	= 3 	if m2c == 1 
	replace rh_anc_pv 	= 2 	if m2b == 1
	replace rh_anc_pv 	= 1 	if m2a == 1
	replace rh_anc_pv 	= 9 	if m2a == 9
	
	label define rh_anc_pv ///
	1 "Doctor" 		///
	2 "Nurse/midwife"	///
	3 "Auxiliary midwife" ///
	4 "TBA/CHW/other/relative"		///
	9 "Missing" ///
	6 "No ANC" 
	label val rh_anc_pv rh_anc_pv
	label var rh_anc_pv "Person providing assistance during ANC"
	
* ANC by skilled provider
** Note: For Cambodia 2022 FR, doctor, nurse, auxiliary midwife is considered skilled. 
	recode rh_anc_pv (1/3 = 1 "Skilled provider") (4/6 = 2 "Other/No one") (9=3 "Don't know/missing"), gen(rh_anc_pvskill)
	*recode rh_anc_pv (1/3 = 1 "Skilled provider") (4/9 = 0 "Unskilled/no one") , gen(rh_anc_pvskill)
	label var rh_anc_pvskill "Skilled assistance during ANC"	
		
//4+ ANC visits  
	recode rh_anc_numvs (1 2 9=0 "no") (3=1 "yes"), gen(rh_anc_4vs)
	lab var rh_anc_4vs "Attended 4+ ANC visits"
	
* Place of delivery
recode m15 (20/39 = 1 "Health facility") (10/19 40/98 = 0 "Home/other") (99=9 "Missing"), gen(rh_del_place)
label var rh_del_place "Live births by place of delivery"
	
* Assistance during delivery
**Note: Assistance during delivery and skilled provider indicators are both country specific indicators. 
**For Cambodia 2022 FR, doctor, nurse, auxiliary midwife is considered skilled. 
	gen rh_del_pv = 9 
	replace rh_del_pv 	= 6 	if m3n == 1
	replace rh_del_pv 	= 5 	if m3h == 1 | m3k == 1 
	replace rh_del_pv 	= 4 	if m3g == 1 
	replace rh_del_pv 	= 3 	if m3c == 1 
	replace rh_del_pv 	= 2 	if m3b == 1
	replace rh_del_pv 	= 1 	if m3a == 1
	replace rh_del_pv 	= 9 	if m3a == 8 | m3a == 9
	
	label define pv 			///
	1 "Doctor" 					///
	2 "Nurse/midwife"			///
	3 "Auxiliary midwife" ///
	4 "Traditional birth attendant"	///
	5 "Relative/other"			///
	6 "No one"					///
	9 "Don't know/missing"
	label val rh_del_pv pv
	label var rh_del_pv "Person providing assistance during delivery"

* Skilled provider during delivery
** Note: For Cambodia 2022 FR, doctor, nurse, auxiliary midwife is considered skilled. 
	recode rh_del_pv (1/3 = 1 "Skilled provider") (4/6 = 2 "Other/No one") (9=3 "Don't know/missing"), gen(rh_del_pvskill)
	label var rh_del_pvskill "Skilled assistance during delivery"
	

*******************************************	
*** Preparing for analysis ***
*******************************************

* checking variables
foreach var of varlist resid edu maritalstat rc_empl v190 v463a age_b_yr_cat primi-rh_del_pvskill {
	tab `var', m
}

pwcorr resid edu maritalstat rc_empl v190 v463a v481 age_b_yr_cat primi-rh_del_pvskill

*v463a dropped due to high level of missing data
*ANC variables also highly correlated. Kept ANC by a skilled provider for analysis.
*Delivery place, provider assistance, and skilled provider all highly correlated. Kept delivery place for analysis

global stillbirthNRcovs "resid edu maritalstat rc_empl v190 age_b_yr_cat primi histsb hist_chdeath multpreg rh_anc_pvskill rh_del_place p20"

global istillbirthNRcovs "i.resid i.edu i.maritalstat i.rc_empl i.v190  i.age_b_yr_cat i.primi i.histsb i.hist_chdeath i.multpreg i.rh_anc_pvskill i.rh_del_place i.p20"

*** Set the complex survey design ***
gen wt=v005/1000000

svyset [pw=wt], psu(v021) strata(v022)

**************************************************	
*** Model analysis using logistic regressions ***
**************************************************
*set working directory to save results in results folder
cd "C:/Users/$user/ICF/Stillbirth analysis/Results"  //modify this to your working directory

*** Bivariate associations ***
foreach x in $istillbirthNRcovs {
		svy:logistic stillbirth `x'  
		outreg2 using "NR_biregs_`c'.xls", eform stats(coef ci) alpha(0.001, 0.01, 0.05) sideway dec(2) label(insert) noparen nocons append
}

*** Multivariate logistic model ***
svy: logistic stillbirth i.resid i.edu i.maritalstat i.rc_empl i.v190 i.age_b_yr_cat i.primi i.hist_chdeath i.multpreg i.rh_anc_pvskill i.rh_del_place i.p20

outreg2 using "NR_multiregs_`c'.xls", eform stats(coef ci) alpha(0.001, 0.01, 0.05) sideway dec(2) label(insert) noparen nocons append

* save coded file
*set working director to save results in coded data folder
cd "C:/Users/$user/ICF/Stillbirth analysis/coded_data"  //modify this to your working directory
save "`cn'NR_coded.DTA", replace
}