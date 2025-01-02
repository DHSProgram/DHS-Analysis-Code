/*****************************************************************************************************
Program: 			EC_equity_calcs_github

Purpose: 			"stack" coefficients to take advantage of nlcom's use of the delta method to 	
					calculate variance estimates for EC estimates
Author:				Tom Pullum			

The labels for the saved B and V matrices have the following fields:

reg or region2: this can be "National" or "1", "2", etc., for region2 (recode of v024 into consecutive values)
  or other codes for v025 and v190. The regions themselves are renumbered consecutively with 1, 2, etc.

hftype or fac: "." or codes for hftype

adj: codes for type of adjustment, such adjregion, adjfac

All runs are limited to version 2.  Versions 1 and 3 are dropped. Models: 1, 2, 3, 4, 12, 123, 1234 

For the subnational runs (v025 and v190); These variables are only defined for level 1. Levels 2, 3, 4 
  (and the products) are not restricted in the products.

For the facility-adjusted estimates, the terms for source 2, 3, 4 are a summation across hftypes and can be
  greater than 1. IGNORE THE OUTPUT FOR THOSE LINES. For the cascades 12, 123, 1234 there is an hftype-specific
  multiplication, and those products are then added. The products are in the range (0,1).

For each model, crucial scalars are constructed. The first, sRHS, consists of the terms on the RHS of the glm model.
Second, a set of seven scalars sy1, sy2, sy3, sy4, sy12, sy123, sy1234 are constructed for the nlcom command that follows the glm model.

Some modifications will have to be made if the number of facility types is different from 4
The procedure is not automated with respect to changing the number of facility types.
 
SEVEN TYPES OF CASCADES:

THESE FIVE CAN BE DONE FOR BOTH ANC AND SC:
national,  unadjusted
national,  by 7 subpopulations, urban/rural and wealth quintile
by region, unadjusted
by hftype, unadjusted
national,  adjusted for region

THESE THREE CAN ONLY BE DONE FOR SC:
by region, adjusted for hftype
national,  adjusted for hftype
national,  adjusted for hftype and region

*****************************************************************************************************/

set more off

* For a run using more than one country, some routines need to be dropped from memory for each country; must review 
clear all

cap program drop specify_wt_cl_strata_R prepare_R_files SC_recode prepare_U_files make_ANC_composite_file make_SC_composite_file prepare_for_nlcom run_nlcom cascade_national cascade_region2 cascade_hftype prepare_for_nlcom_for_adj cascade_national_adj_for_hftype cascade_region2_hftype ANC_cascade SC_cascade save_results modify_results main 

/*


This program calculates effective coverage coefficients, and confidence intervals,
 for the ANC (antenatal care) and SC (sick child) cascades. 

It stacks the data files and uses a logit regression framework within glm.  
All components are in a range from 0 to 1 but can take values other than 0 and 1. 
Components that were originally in a range from 0 to 100 are divided by 100.

glm with family(binomial) link(logit) can handle Y values between >0 and <1. logit cannot.

Original version prepared by Tom Pullum in March/April 2021, tom.pullum@icf.com

"R" refers to SPA data (FC or AN or SC files) and "U" refers to DHS data (IR or KR files)
"R" for "readiness" and "U" for "users"

"cid" for country id, "pv" for phase+version

Confirmed that glm with family(binomial) link(logit) handles values >0 and <1 and logit does not

Executable lines begin after multiple rows of asterisks

*/

*******************************************************************

program define specify_wt_cl_strata_R

* weights, clusters, strata are the same in all three R files from the same country
* SPA sample as a single cluster, "9999"
* The SPA stratum codes must be in a different range than the DHS stratum codes;
*   to ensure that, add 1000 to spastrata 

* The Haiti and Malawi SPAs were censuses, so cluster_R and stratum_R are replaced with 9999. 

gen weight_R=fwt
capture gen weight_Q=clwt
gen cluster_Q=facil
gen cluster_R=facil
gen stratum_Q=spastrata+1000
gen stratum_R=spastrata+1000

if scid=="MW" | scid=="HT" {
*replace cluster_Q=facil
replace cluster_R=9999
replace stratum_Q=9999
replace stratum_R=9999

}

end


*******************************************************************

program define prepare_R_files

* This routine prepares the AN and FC and SC files with a standard format

local ldatapath=sdatapath
local lreaddatapath=sreaddatapath
local lcode=scode
local lcid=scid
local lpv=spv_R

use "`lreaddatapath'\\`lcid'\\`lcid'AN`lpv'FLSPcoded.dta", clear
keep facil hftype ftype spastrata clwt fwt region2 anc_q_2
rename ftype v025
specify_wt_cl_strata_R
save "`ldatapath'\\`lcid'\\`lcid'_AN.dta", replace

use "`lreaddatapath'\\`lcid'\\`lcid'FC`lpv'FLSPready.dta", clear
keep facil hftype ftype spastrata fwt region2 anc_r_2 sc_r_2
rename ftype v025
specify_wt_cl_strata_R
save "`ldatapath'\\`lcid'\\`lcid'_FC.dta", replace

use "`lreaddatapath'\\`lcid'\\`lcid'SC`lpv'FLSPcoded.dta", clear
keep facil hftype ftype spastrata clwt fwt region2 sc_i_23 sc_q_2 
rename ftype v025
specify_wt_cl_strata_R
save "`ldatapath'\\`lcid'\\`lcid'_SC.dta", replace

end

*******************************************************************

program define SC_recode

* This routine uses the KR file and revises the SC outcome variable to incorporate hftype. 

rename sc_c_123     sc_c_123_original
rename hftype       hftype_original
rename ch_diar_care ch_diar_care_original
rename ch_ari_care  ch_ari_care_original

gen     ch_diar_care=0 if ch_diar==1
replace ch_diar_care=1 if ch_diar_care_govhosp==1 | ch_diar_care_govhc==1 | ch_diar_care_privhosp==1  | ch_diar_care_privhc==1

gen     ch_ari_care=0 if ch_ari==1
replace ch_ari_care=1 if ch_ari_care_govhosp==1 | ch_ari_care_govhc==1 | ch_ari_care_privhosp==1  | ch_ari_care_privhc==1

gen     sc_rev_123=0 if ch_diar==1      | ch_ari==1
replace sc_rev_123=1 if ch_diar_care==1 | ch_ari_care==1 

gen sc_rev_123_1=0 if sc_rev_123==1
gen sc_rev_123_2=0 if sc_rev_123==1
gen sc_rev_123_3=0 if sc_rev_123==1
gen sc_rev_123_4=0 if sc_rev_123==1

replace sc_rev_123_1=1 if sc_rev_123==1 & (ch_diar_care_govhosp==1  | ch_ari_care_govhosp==1) 
replace sc_rev_123_2=1 if sc_rev_123==1 & (ch_diar_care_govhc==1    | ch_ari_care_govhc==1)
replace sc_rev_123_3=1 if sc_rev_123==1 & (ch_diar_care_privhosp==1 | ch_ari_care_privhosp==1)
replace sc_rev_123_4=1 if sc_rev_123==1 & (ch_diar_care_privhc==1   | ch_ari_care_privhc==1)

* Revise so that these sum to 1 and the priority sequence is govhosp, privhosp, privhc, govhc
* Necessary because a small number of cases (children) are taken to more than one type of facility
*   but we want the options to be mutually exclusive. Code in the sequence 2,4,3,1

gen hftype=0 if sc_rev_123==1
replace hftype=1 if sc_rev_123_1==1 & hftype==0
replace hftype=3 if sc_rev_123_3==1 & hftype==0
replace hftype=4 if sc_rev_123_4==1 & hftype==0
replace hftype=2 if sc_rev_123_2==1 & hftype==0

* Important: use code 0 for hftype if the child had symptoms but was not taken for care.
replace hftype=0 if sc_rev_123==0

* For some purposes you may be interested only in values 1, 2, 3, 4
* In the SPA files, only values 1, 2, 3, 4 appear

label variable hftype "Health Facility Type"
label define hftype 0 "Not taken" 1 "Gov hosp" 2 "Gov HC" 3 "Priv Hosp" 4 "Priv HC", modify
label values hftype hftype
tab hftype sc_rev_123, m

/*
[From Sara Riese:] For the issue about multiple places, I think the prioritization should be 
1.	Gov hospital
2.	Private hospital
3.	Private health center
4.	Gov health center
*/

* Replace sc_c_123 with this version
rename sc_rev_123 sc_c_123


end

*******************************************************************

program define v025_v190

* Construct the codes for the subnational runs by v025 and by v190

* Note the v025 and v190 are defined only in the IR and KR files (U files), not in the R files

* It is tricky to apply a restriction to only the U files and not the R files

gen subnat0=1
gen subnat1=1 if v025==. | v025==1
gen subnat2=1 if v025==. | v025==2
gen subnat3=1 if v190==. | v190==1
gen subnat4=1 if v190==. | v190==2
gen subnat5=1 if v190==. | v190==3
gen subnat6=1 if v190==. | v190==4
gen subnat7=1 if v190==. | v190==5

label variable subnat0 "National"
label variable subnat1 "Nat, v025=1"
label variable subnat2 "Nat, v025=2"
label variable subnat3 "Nat, v190=1"
label variable subnat4 "Nat, v190=2"
label variable subnat5 "Nat, v190=3"
label variable subnat6 "Nat, v190=4"
label variable subnat7 "Nat, v190=5"

end

*******************************************************************

program define prepare_U_files

* This routine prepares the IR and KR files with a standard format

local ldatapath=sdatapath
local lreaddatapath=sreaddatapath
local lcid=scid
local lpv=spv_U

* weights, clusters, strata are the same in both the U files

use "`lreaddatapath'\\`lcid'\\`lcid'IR`lpv'FLcoded.dta", clear
keep v001 v002 v003 v005 strata region2 anc_c_123 anc_i_123 anc_q_1 v025 v190

* DROP CASES THAT ARE MISSING ON THE OUTCOME
************************************************
drop if anc_c_123==. & anc_i_123==. & anc_q_1==.
************************************************

gen cluster_U=v001
gen stratum_U=strata
gen  weight_U=v005

save "`ldatapath'\\`lcid'\\`lcid'_IR.dta", replace

use "`lreaddatapath'\\`lcid'\\`lcid'KR`lpv'FLcoded.dta", clear
keep v001 v002 v003 v005 strata region2 hftype ch_diar* ch_ari* sc_c_123 sc_i_1 v025 v190

* DROP CASES THAT ARE MISSING ON THE OUTCOME
************************************************
drop if sc_c_123==. & sc_i_1==.
************************************************

* INSERT RECODE FOR SC HFTYPE
SC_recode

keep v001 v002 v003 v005 strata region2 hftype sc_c_123 sc_i_1 v025 v190
gen cluster_U=v001
gen stratum_U=strata
gen  weight_U=v005

save "`ldatapath'\\`lcid'\\`lcid'_KR.dta", replace

end

*******************************************************************

program define make_ANC_composite_file

* This file is a composite of the IR, FC, IR, and AN files, in that sequence,
*   numbered with source=1, 2, 3, 4.  The IR file appears as both source=1 and source=3.

local ldatapath=sdatapath
local lcid=scid

use "`ldatapath'\\`lcid'\\`lcid'_IR.dta", clear
gen source=1

append using "`ldatapath'\\`lcid'\\`lcid'_FC.dta"
replace source=2 if source==.

append using "`ldatapath'\\`lcid'\\`lcid'_IR.dta"
replace source=3 if source==.

append using "`ldatapath'\\`lcid'\\`lcid'_AN.dta"
replace source=4 if source==.

local lnames cluster stratum weight
foreach lname of local lnames {
gen `lname'=`lname'_U
replace `lname'=`lname'_R if source==2 
replace `lname'=`lname'_Q if source==4
}

tab source, summarize(cluster)
tab source, summarize(weight)
tab source, summarize(stratum)

xi, noomit i.source
rename _I* *
rename source_* s*

label variable s1 "IR"
label variable s2 "FC"
label variable s3 "IR"
label variable s4 "AN"

v025_v190

* Setup for models: define svyset, "s" variables, "model" variables for subpop
if scid=="MW" | scid=="HT" {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

if scid=="NP" | scid=="SN" | scid=="TZ"  {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

save "`ldatapath'\\`lcid'\\`lcid'_ANCcombo.dta", replace

end

******************************************************************

program define make_SC_composite_file

* This file is a composite of the KR, FC, SC, and SC files, in that sequence,
*   numbered with source=1, 2, 3, 4.  The SC file appears as both source=3 and source=4

local ldatapath=sdatapath
local lcid=scid

use "`ldatapath'\\`lcid'\\`lcid'_KR.dta", clear
gen source=1

append using "`ldatapath'\\`lcid'\\`lcid'_FC.dta"
replace source=2 if source==.

append using "`ldatapath'\\`lcid'\\`lcid'_SC.dta"
replace source=3 if source==.

append using "`ldatapath'\\`lcid'\\`lcid'_SC.dta"
replace source=4 if source==.

local lnames cluster stratum weight
foreach lname of local lnames {
gen `lname'=`lname'_U
replace `lname'=`lname'_R if source==2
replace `lname'=`lname'_Q if source==3 | source==4
}

xi, noomit i.source
rename _I* *
rename source_* s*

label variable s1 "KR"
label variable s2 "FC"
label variable s3 "SC"
label variable s4 "SC"

v025_v190

* Setup for models: define svyset, "s" variables, "model" variables for subpop
if scid=="MW" | scid=="HT" {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

if scid=="NP" | scid=="SN" | scid=="TZ"  {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

save "`ldatapath'\\`lcid'\\`lcid'_SCcombo.dta", replace

end

*******************************************************************
*******************************************************************
*******************************************************************
*******************************************************************
* LINES ABOVE THIS POINT ARE FOR FILE CONSTRUCTION
*******************************************************************
*******************************************************************
*******************************************************************
*******************************************************************
 
program define calculate_proportions

* National estimates adjusted for region require the proportions in each region

local  lcid=scid
local  ldatapath=sdatapath
scalar snregions=snregions_`lcid'
local  lnregions=snregions

* Calculate scalars for the proportions of women and children in each region (region2)
* The proportions are needed for the national estimates adjusted by region, which ar
*   just a weighted average of the estimates for the regions.

* NOTE: the proportions are treated as fixed. They are not treated as random variables.

use "`ldatapath'\\`lcid'\\`lcid'_IR.dta", clear
proportion region2 [pweight=v005]
matrix B=e(b)
forvalues lr=1/`lnregions' {
scalar sprop_women_`lr'=B[1,`lr']
scalar sprop_women_`lr'=round(sprop_women_`lr',.0001)
}

use "`ldatapath'\\`lcid'\\`lcid'_KR.dta", clear
proportion region2 [pweight=v005]
matrix B=e(b)
forvalues lr=1/`lnregions' {
scalar sprop_children_`lr'=B[1,`lr']
scalar sprop_children_`lr'=round(sprop_children_`lr',.0001)
}

*scalar list

end

*******************************************************************

program define prepare_RHS

* This routine first prepares a scalar for the right hand side (RHS) of each glm model
* It then constructs the variables that will go on the RHS

* The first part does not use the data files
* The routine prepares for models that may not be used

local lnregions=snregions
local lfactypes 1 2 3 4
scalar sRHS_sf=" "
scalar sRHS_sr=" "
scalar sRHS_sfr=" "

scalar sRHS_s=" s1 s2 s3 s4 "

* loop over the 4 values of hftype
foreach lf of local lfactypes {
scalar sf`lf'=" s1f`lf' s2f`lf' s3f`lf' s4f`lf' " 
scalar sRHS_sf=sRHS_sf+sf`lf'
}

* loop over the regions and hftype
forvalues lr=1/`lnregions' {
scalar sr`lr'= " s1r`lr' s2r`lr' s3r`lr' s4r`lr' "
scalar sRHS_sr=sRHS_sr+sr`lr'
  foreach lf of local lfactypes {
  scalar sf`lf'r`lr'=" s1f`lf'r`lr' s2f`lf'r`lr' s3f`lf'r`lr' s4f`lf'r`lr' " 
  scalar sRHS_sfr=sRHS_sfr+sf`lf'r`lr' 
  }
}

scalar list sRHS_s sRHS_sf sRHS_sr sRHS_sfr


/*
forvalues ls=1/4 {
gen s`ls'=0
replace s`ls'=1 if source==`ls'
}
*/

forvalues lf=1/4 {
gen f`lf'=0
replace f`lf'=1 if hftype==`lf'
}

forvalues lr=1/`lnregions' {
gen r`lr'=0
replace r`lr'=1 if region==`lr'
}

forvalues ls=1/4 {
  forvalues lf=1/4 {
  gen s`ls'f`lf'=s`ls'*f`lf'
  }
  forvalues lr=1/`lnregions' {
  gen s`ls'r`lr'=s`ls'*r`lr'
  }
}

forvalues ls=1/4 {
  forvalues lf=1/4 {
    forvalues lr=1/`lnregions' {
    gen s`ls'f`lf'r`lr'=s`ls'*f`lf'*r`lr'
    }
  }
}

end

*******************************************************************

program define prepare_file_for_hftype

* PREPARE A STACKED DATA FILE FOR HFTYPE ANALYSES
* Stack four copies of the source=1 part of he SCcombo file, one for each value of hftype

local lcid=scid
local ldatapath=sdatapath
local lC=s_ANC_SC
local lnregions=snregions_`lcid'

scalar snhftypes=4
local  lnhftypes=snhftypes

* Stack four copies of the source=1 part of he SCcombo file, one for each value of hftype

save tempdata1234.dta, replace

keep if source==1
save tempdata1.dta, replace 
gen hft=1
append using tempdata1.dta
replace hft=2 if hft==.
append using tempdata1.dta
replace hft=3 if hft==.
append using tempdata1.dta
replace hft=4 if hft==.
save tempdata1.dta, replace

use tempdata1234.dta, clear
drop if source==1
append using tempdata1.dta
sort source hft

tab source hft,m

* Define Yf
gen Yf=0
replace Yf=Y if source>1

replace Yf=1 if source==1 & hft==1 & hftype==1
replace Yf=1 if source==1 & hft==2 & hftype==2
replace Yf=1 if source==1 & hft==3 & hftype==3
replace Yf=1 if source==1 & hft==4 & hftype==4

tab Yf source
tab Yf hft if source==1

* Now must recode the s1* terms so they are specific for hft, the separated layers within source 1
* This is an important step

forvalues lf=1/4 {
replace s1f`lf'=0
replace s1f`lf'=1        if source==1 & hft==`lf'
  forvalues lr=1/`lnregions' {
  replace s1f`lf'r`lr'=0
  replace s1f`lf'r`lr'=1 if source==1 & hft==`lf' & region2==`lr'
  }
}

* must drop s1 s2 s3 s4 and not use them in the analysis of factype
drop s1 s2 s3 s4

end

*******************************************************************

program define prepare_nlcom_s

/* 

Prepare scalars for nlcom when when the model is "s", national or within regions

Construct scalars that give means as functions of e(b) following logit.
These scalars are essentially formulas for means as antilogits, expressed
  as functions of the terms in e(b) following a logit regression. 
The formulas can be prepared BEFORE the model is run.
The four terms prepared here are the core of all the formulas
*/

local ln1234 1 2 3 4

foreach ln of local ln1234 {
local lterm="_b[s`ln']"
scalar sy`ln'="(exp(`lterm')/(1+exp(`lterm')))"
}

scalar sy12=  sy1    +"*"+ sy2
scalar sy123= sy12   +"*"+ sy3
scalar sy1234=sy123  +"*"+ sy4

scalar list sy1 sy2 sy3 sy4 sy12 sy123 sy1234

end

*******************************************************************

program define prepare_nlcom_sr

/* 

Prepare scalars for nlcom when when the model is "sr"

This is for the national estimate adjusted for region

*/

local lnregions=snregions
local ln1234 1 2 3 4

forvalues lr=1/`lnregions' {
  foreach ln of local ln1234 {
  local lterm="_b[s`ln'r`lr']"
  scalar sy`ln'r`lr'="(exp(`lterm')/(1+exp(`lterm')))"
  }

scalar  sy12r`lr'=    sy1r`lr'   +"*"+  sy2r`lr'
scalar  sy123r`lr'=   sy12r`lr'  +"*"+  sy3r`lr'
scalar  sy1234r`lr'=  sy123r`lr' +"*"+  sy4r`lr'

}

* Then add across regions, with weights

scalar    sy1=" ( "
scalar    sy2=" ( "
scalar    sy3=" ( "
scalar    sy4=" ( "
scalar   sy12=" ( "
scalar  sy123=" ( "
scalar sy1234=" ( "

forvalues lr=1/`lnregions' {

  if s_ANC_SC=="ANC" {
  local lp=sprop_women_`lr'
  }

  if s_ANC_SC=="SC" {
  local lp=sprop_children_`lr'
  }

  scalar sadd="+"
  if `lr'==`lnregions' {
  scalar sadd=" ) "
  }

scalar    sy1=   sy1+ "`lp'" + "*" +    sy1r`lr' +sadd
scalar    sy2=   sy2+ "`lp'" + "*" +    sy2r`lr' +sadd
scalar    sy3=   sy3+ "`lp'" + "*" +    sy3r`lr' +sadd
scalar    sy4=   sy4+ "`lp'" + "*" +    sy4r`lr' +sadd
scalar   sy12=  sy12+ "`lp'" + "*" +   sy12r`lr' +sadd
scalar  sy123= sy123+ "`lp'" + "*" +  sy123r`lr' +sadd
scalar sy1234=sy1234+ "`lp'" + "*" + sy1234r`lr' +sadd
}

scalar list sy1 sy2 sy3 sy4 sy12 sy123 sy1234

end

*******************************************************************

program define prepare_nlcom_sf


* prepare the scalars for nlcom when the model is sf, facility type nationally or within regions

local lnregions=snregions
local lsource 1 2 3 4
local    lfac 1 2 3 4

foreach ls of local lsource {
  foreach lf of local lfac {
  local lt="exp(_b[s`ls'f`lf'])"
  scalar s_s`ls'f`lf'="(`lt'/(1+`lt'))"
  }
}


foreach lf of local lfac {
  forvalues lr=1/`lnregions' {
  scalar    sy1f`lf' =  s_s1f`lf'
  scalar    sy2f`lf' =  s_s2f`lf'
  scalar    sy3f`lf' =  s_s3f`lf'
  scalar    sy4f`lf' =  s_s4f`lf'
  scalar   sy12f`lf' =  s_s1f`lf' +"*"+ s_s2f`lf'
  scalar  sy123f`lf' =  sy12f`lf' +"*"+ s_s3f`lf'
  scalar sy1234f`lf' = sy123f`lf' +"*"+ s_s4f`lf'
  }
}


if sadjusted==0 {
local lf=shftype 
scalar    sy1 =  s_s1f`lf'
scalar    sy2 =  s_s2f`lf'
scalar    sy3 =  s_s3f`lf'
scalar    sy4 =  s_s4f`lf'
scalar   sy12 =  sy1 +"*"+ s_s2f`lf'
scalar  sy123 =  sy12 +"*"+ s_s3f`lf'
scalar sy1234 = sy123 +"*"+ s_s4f`lf'
}

if sadjusted==1 {
scalar sy1   = sy1f1    + "+" + sy1f2    + "+" + sy1f3    + "+" + sy1f4
scalar sy2   = sy2f1    + "+" + sy2f2    + "+" + sy2f3    + "+" + sy2f4
scalar sy3   = sy3f1    + "+" + sy3f2    + "+" + sy3f3    + "+" + sy3f4
scalar sy4   = sy4f1    + "+" + sy4f2    + "+" + sy4f3    + "+" + sy4f4
scalar sy12  = sy12f1   + "+" + sy12f2   + "+" + sy12f3   + "+" + sy12f4 
scalar sy123 = sy123f1  + "+" + sy123f2  + "+" + sy123f3  + "+" + sy123f4 
scalar sy1234= sy1234f1 + "+" + sy1234f2 + "+" + sy1234f3 + "+" + sy1234f4 
}


end

*******************************************************************

program define prepare_nlcom_sfr


* prepare the scalars for nlcom when the model is sfr, national adjusted for facility type and regions
* get the separate region estimates ajusted for hftype and then combine

local lnregions=snregions


* prepare the scalars for nlcom

local lsource 1 2 3 4
local    lfac 1 2 3 4

foreach ls of local lsource {
  foreach lf of local lfac {
    forvalues lr=1/`lnregions' {
    local lt="exp(_b[s`ls'f`lf'r`lr'])"
    scalar s_s`ls'f`lf'r`lr'="(`lt'/(1+`lt'))"
    }
  }
}


foreach lf of local lfac {
  forvalues lr=1/`lnregions' {
  scalar    sy1f`lf'r`lr' =  s_s1f`lf'r`lr'
  scalar    sy2f`lf'r`lr' =  s_s2f`lf'r`lr'
  scalar    sy3f`lf'r`lr' =  s_s3f`lf'r`lr'
  scalar    sy4f`lf'r`lr' =  s_s4f`lf'r`lr'
  scalar   sy12f`lf'r`lr' =  s_s1f`lf'r`lr' +"*"+ s_s2f`lf'r`lr'
  scalar  sy123f`lf'r`lr' =  sy12f`lf'r`lr' +"*"+ s_s3f`lf'r`lr'
  scalar sy1234f`lf'r`lr' = sy123f`lf'r`lr' +"*"+ s_s4f`lf'r`lr'
  }
}


* Next add terms, unweighted, across facility types to get region-specific terms

* Instead of using lfac, use the number of facility types, namely 4

forvalues lr=1/`lnregions' {
scalar    sy1r`lr'=" ("
scalar    sy2r`lr'=" ("
scalar    sy3r`lr'=" ("
scalar    sy4r`lr'=" ("
scalar   sy12r`lr'=" ("
scalar  sy123r`lr'=" ("
scalar sy1234r`lr'=" ("

forvalues lf=1/4 {

  scalar sadd="+"
  if `lf'==4 {
  scalar sadd=" ) "
  }

  scalar    sy1r`lr'=   sy1r`lr'+    sy1f`lf'r`lr' + sadd
  scalar    sy2r`lr'=   sy2r`lr'+    sy2f`lf'r`lr' + sadd
  scalar    sy3r`lr'=   sy3r`lr'+    sy3f`lf'r`lr' + sadd
  scalar    sy4r`lr'=   sy4r`lr'+    sy4f`lf'r`lr' + sadd
  scalar   sy12r`lr'=  sy12r`lr'+   sy12f`lf'r`lr' + sadd
  scalar  sy123r`lr'= sy123r`lr'+  sy123f`lf'r`lr' + sadd
  scalar sy1234r`lr'=sy1234r`lr'+ sy1234f`lf'r`lr' + sadd
  }
}

* Then add across regions, with weights

scalar    sy1=" ( "
scalar    sy2=" ( "
scalar    sy3=" ( "
scalar    sy4=" ( "
scalar   sy12=" ( "
scalar  sy123=" ( "
scalar sy1234=" ( "

forvalues lr=1/`lnregions' {

  if s_ANC_SC=="ANC" {
  local lp=sprop_women_`lr'
  }

  if s_ANC_SC=="SC" {
  local lp=sprop_children_`lr'
  }

  scalar sadd="+"
  if `lr'==`lnregions' {
  scalar sadd=" ) "
  }

scalar    sy1=   sy1+ "`lp'" + "*" +    sy1r`lr' +sadd
scalar    sy2=   sy2+ "`lp'" + "*" +    sy2r`lr' +sadd
scalar    sy3=   sy3+ "`lp'" + "*" +    sy3r`lr' +sadd
scalar    sy4=   sy4+ "`lp'" + "*" +    sy4r`lr' +sadd
scalar   sy12=  sy12+ "`lp'" + "*" +   sy12r`lr' +sadd
scalar  sy123= sy123+ "`lp'" + "*" +  sy123r`lr' +sadd
scalar sy1234=sy1234+ "`lp'" + "*" + sy1234r`lr' +sadd
}

end

*******************************************************************

program define run_glm_nlcom

* All models follow the same framework with a glm command followed by nlcom
* The scalars sRHS, sy1, sy2, sy3, sy4, sy12, sy123, sy1234 are constructed in advance
* The variable for the subpop option must be specified; can just use all cases 
* sYvar is Y or Yf
* smodel is s, sf, sr, or sfr

local  lYvar=sYvar
local  lsubpop=ssubpop
local  lmodel=smodel
scalar sRHS=sRHS_`lmodel'
local  lRHS=sRHS
scalar list sYvar ssubpop smodel sRHS

* Yvar is Y  if factype IN NOT in the model
* Yvar is Yf if factype IS in the model
svy, subpop(`lsubpop'): glm `lYvar' `lRHS', family(binomial) link(logit) nocons asis iterate(30)

* BETWEEN glm and nlcom, the output from glm must be prepared for nlcom
prepare_nlcom_`lmodel'

local ly1   =sy1 
local ly2   =sy2
local ly3   =sy3
local ly4   =sy4
local ly12  =sy12 
local ly123 =sy123 
local ly1234=sy1234 

nlcom (`ly1') (`ly2') (`ly3') (`ly4') (`ly12') (`ly123') (`ly1234'), post

* delete the scalars that specify the model to reduce the risk of errors
scalar drop sYvar ssubpop smodel 

matrix B=e(b)
matrix V=e(V)

end

******************************************************************

/*
program define nat_fac_reg_adj

/*
The most complicated nlcom setup; the national estimate adjusted for both factype and region

the coefficients from the logit regression have the structure _b[sifjrk], where i is the source, 
 j is the facility type, k is the region

Calculate for each facility type within each region, then add across facility types within each region,
  and then add the terms for regions with proportions for the regions

This can only be run for SC because it involves hftype

These scalars are the formulas for the cascade 

*/

local lnregions=snregions        
local lC=s_ANC_SC


* prepare the scalars for nlcom
* construct the equivalent to the scalars in nat_fac_adj WITHIN EACH REGION

local lsource 1 2 3 4
local    lfac 1 2 3 4

foreach ls of local lsource {
  foreach lf of local lfac {
    forvalues lr=1/`lnregions' {
    local lt="exp(_b[s`ls'f`lf'r`lr'])"
    scalar s_s`ls'f`lf'r`lr'="(`lt'/(1+`lt'))"
    }
  }
}


foreach lf of local lfac {
  forvalues lr=1/`lnregions' {
  scalar    sy1f`lf'r`lr' =  s_s1f`lf'r`lr'
  scalar    sy2f`lf'r`lr' =  s_s2f`lf'r`lr'
  scalar    sy3f`lf'r`lr' =  s_s3f`lf'r`lr'
  scalar    sy4f`lf'r`lr' =  s_s4f`lf'r`lr'
  scalar   sy12f`lf'r`lr' =  s_s1f`lf'r`lr' +"*"+ s_s2f`lf'r`lr'
  scalar  sy123f`lf'r`lr' =  sy12f`lf'r`lr' +"*"+ s_s3f`lf'r`lr'
  scalar sy1234f`lf'r`lr' = sy123f`lf'r`lr' +"*"+ s_s4f`lf'r`lr'
  }
}


* Next add terms, unweighted, across facility types to get region-specific terms

* Instead of using lfac, use the number of facility types, namely 4

forvalues lr=1/`lnregions' {
scalar    sy1r`lr'=" ("
scalar    sy2r`lr'=" ("
scalar    sy3r`lr'=" ("
scalar    sy4r`lr'=" ("
scalar   sy12r`lr'=" ("
scalar  sy123r`lr'=" ("
scalar sy1234r`lr'=" ("

forvalues lf=1/4 {

  scalar sadd="+"
  if `lf'==4 {
  scalar sadd=" ) "
  }

  scalar    sy1r`lr'=   sy1r`lr'+    sy1f`lf'r`lr' + sadd
  scalar    sy2r`lr'=   sy2r`lr'+    sy2f`lf'r`lr' + sadd
  scalar    sy3r`lr'=   sy3r`lr'+    sy3f`lf'r`lr' + sadd
  scalar    sy4r`lr'=   sy4r`lr'+    sy4f`lf'r`lr' + sadd
  scalar   sy12r`lr'=  sy12r`lr'+   sy12f`lf'r`lr' + sadd
  scalar  sy123r`lr'= sy123r`lr'+  sy123f`lf'r`lr' + sadd
  scalar sy1234r`lr'=sy1234r`lr'+ sy1234f`lf'r`lr' + sadd
  }
}

* Then add across regions, with weights

scalar    sy1=" ( "
scalar    sy2=" ( "
scalar    sy3=" ( "
scalar    sy4=" ( "
scalar   sy12=" ( "
scalar  sy123=" ( "
scalar sy1234=" ( "

forvalues lr=1/`lnregions' {

  if s_ANC_SC=="ANC" {
  local lp=sprop_women_`lr'
  }

  if s_ANC_SC=="SC" {
  local lp=sprop_children_`lr'
  }

  scalar sadd="+"
  if `lr'==`lnregions' {
  scalar sadd=" ) "
  }

scalar    sy1=   sy1+ "`lp'" + "*" +    sy1r`lr' +sadd
scalar    sy2=   sy2+ "`lp'" + "*" +    sy2r`lr' +sadd
scalar    sy3=   sy3+ "`lp'" + "*" +    sy3r`lr' +sadd
scalar    sy4=   sy4+ "`lp'" + "*" +    sy4r`lr' +sadd
scalar   sy12=  sy12+ "`lp'" + "*" +   sy12r`lr' +sadd
scalar  sy123= sy123+ "`lp'" + "*" +  sy123r`lr' +sadd
scalar sy1234=sy1234+ "`lp'" + "*" + sy1234r`lr' +sadd
}

scalar sYvar="Y"
gen national=1
scalar ssubpop="national"
scalar smodel="sfr"
run_glm_nlcom

matrix B_Natadjbyhftypereg_`lC'=B
matrix V_Natadjbyhftypereg_`lC'=V

end
*/
******************************************************************
/*
program define nat_reg_adj

* The nlcom setup is more complex for the region-adjusted model

local lnregions=snregions        
local lC=s_ANC_SC
local ln1234 1 2 3 4


* Construct the terms for nlcom. Each y is a mean

* These scalars are the formulas for the cascade within each region


forvalues lr=1/`lnregions' {
  foreach ln of local ln1234 {
  local lt="exp(_b[s`ln'_`lr'])"
  scalar sy`ln'_`lr'="(`lt'/(1+`lt'))"
  }
scalar sy12_`lr'  =sy1_`lr'  +"*"+sy2_`lr'
scalar sy123_`lr' =sy12_`lr' +"*"+sy3_`lr'
scalar sy1234_`lr'=sy123_`lr'+"*"+sy4_`lr'
}

* Combine to construct the formula for a weighted mean of 1, 2, 3, 4, 12, 123, 1234 where
*   the weights are the proportions of women in each region

* Initialize the string
scalar sy1   =" ( "
scalar sy2   =" ( "
scalar sy3   =" ( "
scalar sy4   =" ( "
scalar sy12  =" ( "
scalar sy123 =" ( "
scalar sy1234=" ( "

* Add terms for all the regions, ending with + except the last one ends with a blank
forvalues lr=1/`lnregions' {

if s_ANC_SC=="ANC" {
local lp=sprop_women_`lr'
}

if s_ANC_SC=="SC" {
local lp=sprop_children_`lr'
}

scalar sadd="+"
if `lr'==`lnregions' {
scalar sadd=" ) "
}

* calculate the cascade within each region; then add the regional terms with appropriate weights

scalar sy1   =sy1+   "`lp'" + "*" + sy1_`lr'    + sadd
scalar sy2   =sy2+   "`lp'" + "*" + sy2_`lr'    + sadd
scalar sy3   =sy3+   "`lp'" + "*" + sy3_`lr'    + sadd
scalar sy4   =sy4+   "`lp'" + "*" + sy4_`lr'    + sadd
scalar sy12  =sy12+  "`lp'" + "*" + sy12_`lr'   + sadd
scalar sy123 =sy123+ "`lp'" + "*" + sy123_`lr'  + sadd
scalar sy1234=sy1234+"`lp'" + "*" + sy1234_`lr' + sadd

}

end
*/
******************************************************************
/*
program define nat_fac_adj

/*

The nlcom setup for facility-adjusted is similar to the one for region-adjusted 
  but the proportions are not used; the separate types are just added up

The models are estimated WITHIN this routine

Construct the terms for nlcom. Each y is a mean
These scalars are the formulas for the cascade within each region

Use ls for source and lf for facility type

Construct 16 component terms for the antilogit of coefficients s1f1 through s4f4. 
The antilogits are means or proportions in the range 0 to 1
*/

local lC=s_ANC_SC
local lsource 1 2 3 4
local    lfac 1 2 3 4

/*
foreach ls of local lsource {
  foreach lf of local lfac {
  local lt="exp(_b[s`ls'f`lf'])"
  scalar s_s`ls'f`lf'="(`lt'/(1+`lt'))"
  }
}
*/

* These scalars have a structure like s2f4 where 2 is the source and 4 is the factype

* There are variables with the same name so some scalars have a prefix "s_"

* Calculate terms for the cascade with each facility type
* These will be products spefically for factype 1, 2, 3, 4

/*

*runs 1-4:

forvalues lf=1/4 {

scalar    sy1f`lf' =  s_s1f`lf'
scalar    sy2f`lf' =  s_s2f`lf'
scalar    sy3f`lf' =  s_s3f`lf'
scalar    sy4f`lf' =  s_s4f`lf'
scalar   sy12f`lf' =  s_s1f`lf' +"*"+ s_s2f`lf'
scalar  sy123f`lf' =  sy12f`lf' +"*"+ s_s3f`lf'
scalar sy1234f`lf' = sy123f`lf' +"*"+ s_s4f`lf'

scalar sy1   =sy1f`lf' 
scalar sy2   =sy2f`lf'
scalar sy3   =sy3f`lf'
scalar sy4   =sy4f`lf' 
scalar sy12  =sy12f`lf' 
scalar sy123 =sy123f`lf' 
scalar sy1234=sy1234f`lf' 
*/

*local lr=sreg

scalar sYvar="Yf"
scalar smodel="sf"
scalar ssubpop="modelr"
run_glm_nlcom

matrix B_fac`lf'reg`lr'_`lC'=B
matrix V_fac`lf'reg`lr'_`lC'=V
}

*run 5

scalar sy1   = sy1f1    + "+" + sy1f2    + "+" + sy1f3    + "+" + sy1f4
scalar sy2   = sy2f1    + "+" + sy2f2    + "+" + sy2f3    + "+" + sy2f4
scalar sy3   = sy3f1    + "+" + sy3f2    + "+" + sy3f3    + "+" + sy3f4
scalar sy4   = sy4f1    + "+" + sy4f2    + "+" + sy4f3    + "+" + sy4f4
scalar sy12  = sy12f1   + "+" + sy12f2   + "+" + sy12f3   + "+" + sy12f4 
scalar sy123 = sy123f1  + "+" + sy123f2  + "+" + sy123f3  + "+" + sy123f4 
scalar sy1234= sy1234f1 + "+" + sy1234f2 + "+" + sy1234f3 + "+" + sy1234f4 


* In order to have 7 terms, as for all the other applications of nlcom, put placeholders in the first four positions 
*  and then drop them later

scalar sYvar="Yf"
scalar smodel="sf"
scalar ssubpop="modelr"
run_glm_nlcom

matrix B_adjfacallreg`lr'_`lC'=B
matrix V_adjfacallreg`lr'_`lC'=V

end
*/
******************************************************************
/*
program define run_nlcom

local ly1   =sy1 
local ly2   =sy2
local ly3   =sy3 
local ly4   =sy4 
local ly12  =sy12 
local ly123 =sy123 
local ly1234=sy1234 

nlcom (`ly1') (`ly2') (`ly3') (`ly4') (`ly12') (`ly123') (`ly1234'), post

end
*/
*******************************************************************

program define cascade_national

* National-level estimates
* "post" is included in the nlcom line to produce e(b) and e(V)
* "asis" is included so coefficients will not be aliased
* The saved 1x1 matrices are converted to better output later

local lC=s_ANC_SC

local lsubs 0 1 2 3 4 5 6 7

foreach lsub of local lsubs {
*scalar ssubnat="subnat`lsub'"
*local  lsubnat=ssubnat

scalar sYvar="Y"
scalar ssubpop="subnat`lsub'"
scalar smodel="s"
run_glm_nlcom

matrix B_nat`lsub'_`lC'=B
matrix V_nat`lsub'_`lC'=V

}

end

******************************************************************

program define cascade_nat_reg_adj

* This version of cascade gives national estimates for ANC and SC adjusted for regions
* The adjusted national estimate is the weighted meane of the regional estimates

*scalar list

local lnregions=snregions        
local lC=s_ANC_SC
local ln1234 1 2 3 4

*nat_reg_adj

scalar sYvar="Y"
gen national=1
scalar ssubpop="national"
scalar smodel="sr"

run_glm_nlcom
drop national

matrix B_Natadjbyregion_`lC'=B
matrix V_Natadjbyregion_`lC'=V

end

*******************************************************************

program define cascade_reg

* This version of cascade gives estimates for subnational regions
* It should be identical to the national routine except for the labeling of saved results

local lC=s_ANC_SC
local ln1234 1 2 3 4
levelsof region2, local(lregion2)

foreach lr of local lregion2 {
gen region_`lr'=1 if region2==`lr'

scalar sYvar="Y"
scalar ssubpop="region_`lr'"
scalar smodel="s"
run_glm_nlcom

matrix B_reg`lr'_`lC'=B
matrix V_reg`lr'_`lC'=V
}

end

*******************************************************************

program define cascade_national_hftype

/* 

This national-level version of cascade gives estimates by facility type
It uses hftype 1 through 4
hftype is only available for the SC outcome. A local `lC' is used to identify the outcome

For source=1, there are FIVE outcome categories, one of which is 0 (none);
this is incorporated in the definition of Yf

*/

drop if hftype==.

local lC=s_ANC_SC
local lhftype 1 2 3 4

* for the hftype models, Y is restricted in turn to each of the four hftypes

gen national=1
foreach lf of local lhftype {
scalar shftype=`lf'
scalar list shftype
scalar sYvar="Yf"
scalar ssubpop="national"
scalar smodel="sf"

run_glm_nlcom

matrix B_natfac`lf'_`lC'=B
matrix V_natfac`lf'_`lC'=V
}

drop national

end

*******************************************************************

program define cascade_nat_hftype_reg_adj

/* 

This national-level version of cascade gives national estimates adjusted by facility type

*/

drop if hftype==.

local lC=s_ANC_SC
local lhftype 1 2 3 4

* for the hftype models, Y is restricted in turn to each of the four hftypes

scalar sadjusted=1

gen national=1
scalar sYvar="Yf"
scalar ssubpop="national"
scalar smodel="sfr"

run_glm_nlcom

matrix B_natadjreghftype_`lC'=B
matrix V_natadjreghftype_`lC'=V

drop national

* must reset sadjusted to the default
scalar sadjusted=0

end

*******************************************************************

program define cascade_nat_hftype_adj

/* 

similar to cascade_national_hftype but with sadjusted=1

This national-level version of cascade gives estimates by facility type
It uses hftype 1 through 4
hftype is only available for the SC outcome. A local `lC' is used to identify the outcome

For source=1, there are FIVE outcome categories, one of which is 0 (none);
this is incorporated in the definition of Yf

NOTE:
Some modifications will have to be made if the number of facility types is different from 4
The procedure is not automated with respect to changing the number of facility types.

*/

drop if hftype==.

local lC=s_ANC_SC
local lhftype 1 2 3 4

* for the hftype models, Y is restricted in turn to each of the four hftypes

scalar sadjusted=1

gen national=1
scalar sYvar="Yf"
scalar ssubpop="national"
scalar smodel="sf"

run_glm_nlcom

matrix B_natadjhftype_`lC'=B
matrix V_natadjhftype_`lC'=V

drop national

* must reset sadjusted to the default
scalar sadjusted=0

end

*******************************************************************

program define cascade_reg_hftype

* This version of cascade gives estimates by region and facility type
* It is basically a repeat of the national-level routine "cascade_national_hftype"
*   with a loop through all the regions

* THIS CAN ONLY BE DONE FOR SC

local lnregions=snregions
local lhftype 1 2 3 4

local lC=s_ANC_SC

forvalues lr=1/`lnregions' {
gen regionr=1 if region2==`lr'
  foreach lf of local lhftype {
  scalar shftype=`lf'
  scalar list shftype
  scalar sYvar="Yf"
  scalar ssubpop="regionr"
  scalar smodel="sf"

  run_glm_nlcom

  matrix B_reg`lr'fac`lf'_`lC'=B
  matrix V_reg`lr'fac`lf'_`lC'=V
  }
drop regionr
}

end

*********************************************************************************
*********************************************************************************
* The next two routines are related to formatting the output and adjusting the CI
*********************************************************************************
*********************************************************************************

program define save_results

* New way to put the B and V matrices into a data file
* The matrices always come in B & V pairs; construct one line using both of them
* The matrices are saved during the running of the program
* The names are listed in a log file with "matrix dir" 

local lcid=scid
local lcode=scode
local ldatapath=sdatapath

set logtype text
log using "C:\Users\\`lcode'\ICF\Analysis - Equity in effective coverage\Coded Data\matlist.txt", replace
matrix dir
log close


clear
infix str matname 1-40 using "C:\Users\\`lcode'\ICF\Analysis - Equity in effective coverage\Coded Data\matlist.txt"
replace matname=strltrim(matname)

* parse the matrix name
keep if regexm(matname,"B_")==1
replace matname=strltrim(matname)

gen ANC_SC=.
replace ANC_SC=1 if regexm(matname,"ANC")==1
replace ANC_SC=2 if regexm(matname,"SC")==1
drop if ANC_SC==.
label define ANC_SC 1 "ANC" 2 "SC"
label values ANC_SC ANC_SC

* All the B matrices are 1x7 and all the V matrices are 7x7

* find the first and second underscore
gen first=strpos(matname,"_")
gen second=strrpos(matname,"_")
gen ncols=second-first-1
gen type=substr(matname, first+1,ncols)
drop first second ncols
*list, table clean

gen line=_n
summarize line
scalar nlines=r(max)

forvalues li=1/7 {
gen P_`li'=.
gen se_of_P_`li'=.
}

scalar sline=1
quietly while sline<=nlines {
local ltype=type[sline]
scalar soption=ANC_SC[sline]
  if soption==1 {
  local lANC_SC="ANC"
  }

  if soption==2 {
  local lANC_SC= "SC"
  }
scalar sBmatrix="B_" + "`ltype'_" + +"`lANC_SC'"
local lBmatrix=sBmatrix

scalar sVmatrix="V_" + "`ltype'_" + +"`lANC_SC'"
local lVmatrix=sVmatrix

forvalues li=1/7 {
replace       P_`li'=     `lBmatrix'[1,`li']     if line==sline
replace se_of_P_`li'=sqrt(`lVmatrix'[`li',`li']) if line==sline
}

scalar sline=sline+1
}

drop matname 
reshape long P_ se_of_P_, j(model) i(line)
drop line
label define model 1 "source 1" 2 "source 2" 3 "source 3" 4 "source 4" 5 "1x2" 6 "1x2x3" 7 "1x2x3x4"
label values model model

rename *P_ *P
gen L=P-1.96*se_of_P
gen U=P+1.96*se_of_P
gen str20 country=scountry

*list, table clean compress

save "`ldatapath'/`lcid'/`lcid'_results.dta", replace


end

*******************************************************************

program define modify_intervals_and_labels

* This routine can be used by itself after the "results" file has been prepared.
* It allows you to manipulate the output without running the whole program.


local ldatapath=sdatapath
local lcid=scid
local lnregions=snregions

use "`ldatapath'/`lcid'/`lcid'_results.dta", clear

* PART 1. ADJUST THE LABELS AND UNPACK "type"
replace type=strlower(type)

* There is already a numerical variable ANC_SC (with codes 1,2)

* National or regional
gen region=0
label variable region "Region"
label define region 0 "National"
label values region region
forvalues lr=1/`lnregions' {
replace region=`lr' if regexm(type,"reg`lr'")==1
}

* Facility type
gen factype=0
label variable factype "Facility Type"
forvalues lr=1/4 {
replace factype=`lr' if regexm(type,"fac`lr'")==1
}
label define factype 0 "All" 1 "Type 1" 2 "Type 2" 3 "Type 3" 4 "Type 4"
label values factype factype

* Residence_wealth
gen res_wealth=0
label variable res_wealth "Residence/Wealth"
forvalues lr=1/7 {
replace res_wealth=`lr' if regexm(type,"nat`lr'")==1
}
label define res_wealth 0 "All" 1 "v025=1" 2 "v025=2" 3 "v190=1" 4 "v190=2" 5 "v190=3" 6 "v190=4" 7 "v190=5"
label values res_wealth res_wealth

* Adjusted: No, or by Region, or by Factype
gen adjusted=0
label variable adjusted "Adjusted"
replace adjusted=1 if regexm(type,"adj")==1 & regexm(type,"hftype")==0 & regexm(type,"reg")==1 & regexm(type,"nat")==1
replace adjusted=2 if regexm(type,"adj")==1 & regexm(type,"hftype")==0 & regexm(type,"reg")==1 & regexm(type,"nat")==0
replace adjusted=2 if regexm(type,"adj")==1 & regexm(type,"hftype")==1 & regexm(type,"reg")==0 & regexm(type,"nat")==1
replace adjusted=3 if regexm(type,"adj")==1 & regexm(type,"hftype")==1 & regexm(type,"reg")==1 & regexm(type,"nat")==1
label define adjusted 0 "No" 1 "By region" 2 "By hftype" 3 "By hftype & region"
label values adjusted adjusted

* model is already numerical and does not need revision


* PART 2. REVISE THE CONFIDENCE INTERVALS
/* 
This part of the modification is used to construct asymmetric confidence intervals.
The work with Sara Sauer and Hannah Leslie showed that this assymetry is important
If the modified interval has the same width as the original interval but is displaced,
  which is the goal, then delta will be 0.
*/

/*
Procedure used in 2021 and up to 4 April 2022. Approach is to estimate the se of b=logit(P),
 construct a ci for b, then apply antilogit to that ci. THIS PROCEDURE HAS BEEN REPLACED.
* s is the estimated se of b, using the delta method

gen b= log(P/(1-P))
gen se_of_b=se_of_P/(P*(1-P))
gen L_adj=exp(b-1.96*se_of_b)/(1+exp(b-1.96*se_of_b))
gen U_adj=exp(b+1.96*se_of_b)/(1+exp(b+1.96*se_of_b))
gen width=U-L
gen width_adj=U_adj-L_adj
gen delta=width_adj-width
*/

/* 
NEW APPROACH that always gives the modified ci exactly the same width as the nlcomm ci
The nlcom ci is symmetric on the probability scale, that is, L+U=2P

The modified ci is symmetric on the logit scale, that is, logit(L) + logit(U) = 2*logit(P) 

Use A for L_adj, B for U_adj. Require B-A = U-L = W
That is, B=A+W

Define f(A)=logit(A+W) + logit(A) - 2*(logit(P)) ; here P and W are known

Solve for A such that f(A)=0.  Then B=A+W.

Do this with 10 iterations, more than enough. Start with A=L

A1=A0-f(A0)/(df/dA) 

A and L are the low end of the ci, B and U are the upper end

*/

* s is the estimated se of b, using the delta method; not really used
gen se_of_b=se_of_P/(P*(1-P))

* P, L, U, W, A* are all on the probability (0 to 1) scale

* Force L and U to be in the range (0,1), not including 0 or 1
replace L=.00001 if L<0
replace U=.99999 if U>1


* Initialize
gen width=U-L
gen W=width
gen logitP=log(P/(1-P))
gen Aold=L
gen Bold=U
gen fofA=0
gen fofAplus=0
gen dfdA=0
gen Anew=L
gen Bnew=U
gen delta=0

* Iterate; no more than 8 iterations are needed to reach convergence

* "old" for the starting values of A and B for the current iteration
* "new" for the updated  values of A and B

forvalues li=1/8 {

replace Aold=.000001 if Aold<.000001
replace Bold=.999999 if Bold>.999999

* Need the slope of the criterion function  
replace fofA    =log((Aold)/(1-Aold))             + log((Bold)/(1-Bold)) -2*logitP

replace fofAplus=log((Aold+.0001)/(1-Aold-.0001)) +  log((Bold+.0001)/(1-Bold-.0001))  -2*logitP  if Bold+.0001<1

* Need defaults if the original ci is right up against 0 or 1
replace fofAplus=log((Aold+.0001)/(1-Aold-.0001)) +  log((.999999)/(.000001))  -2*logitP  if Bold+.0001>=1
replace fofAplus=log((.000001)/(.999999)) +  log((Bold+.0001)/(1-Bold-.0001))  -2*logitP  if 1-Aold-.0001<=0

replace dfdA=(fofAplus-fofA)/.0001

* delta measures the change in the estimate of A from one iteration to the next; as it goes to 0 we have convergence
replace delta=fofA/dfdA
replace Anew=Aold-delta

* Force the spacing of A and B to match the spacing of L and U
replace Bnew=Anew+W
*summarize fofA fofAplus dfdA delta Anew Bnew

* switch out the current values for the next iteration
replace Aold=Anew
replace Bold=Bnew
}

* Finalize
gen L_adj=Anew
gen U_adj=Anew+W
drop fofA* Aold dfdA Anew W delta


* PART 3. IMPROVE THE APPEARANCE OF THE OUTPUT
* This part of the modification improves the labels and saves the modified file
order country ANC_SC type model P L_adj U_adj width logitP se_of_b L U se_of_P
sort country ANC_SC type model
label variable P "EC estimate"
label variable L_adj "Lower end of asymmetric 95% ci"
label variable U_adj "Upper end of asymmetric 95% ci"
label variable width "Width of 95% ci"

label variable L "Lower end of symmetric 95% ci"
label variable U "Upper end of symmetric 95% ci"

label variable logitP "logit of P"
label variable se_of_b "se of b"

format P se* U* L* width %8.4f

* Drop the first four lines of the "facall" matrix
drop if regexm(type,"facall")==1 & model<5

gen keep=1
replace keep=0 if U==0 | L==1 | width==0

* Order the variables and sort
order country ANC_SC region factype res_wealth adjusted model
sort  country ANC_SC region factype model res_wealth adjusted 

list, table clean
* Save a version in the country folder
save "`ldatapath'\\`lcid'\\`lcid'_results_modified.dta", replace

* Save a version in the main folder
save "`ldatapath'\\`lcid'_results_modified.dta", replace

end

**********************************************************************************
**********************************************************************************
* The two routines above are related to formatting the output and adjusting the CI
**********************************************************************************
**********************************************************************************

program define ANC_cascade

* Note that all indicators should be in a range from 0 to 1 

local ldatapath=sdatapath
local lcid=scid
scalar s_ANC_SC="ANC"

use "`ldatapath'\\`lcid'\\`lcid'_ANCcombo.dta", clear
gen     Y=anc_c_123   if source==1
replace Y=anc_r_2/100 if source==2
replace Y=anc_i_123   if source==3
replace Y=anc_q_2/100 if source==4

* calculate terms for the right hand side of glm commands
prepare_RHS

* The following routines are used for both ANC and SC

* national cascade
cascade_national

* within the nation, region-specific cascades
cascade_reg

* national estimate adjusted for variation across regions
cascade_nat_reg_adj

end

*******************************************************************

program define SC_cascade

* Similar to ANC_cascade

local ldatapath=sdatapath
local lcid=scid
scalar s_ANC_SC="SC"

use "`ldatapath'\\`lcid'\\`lcid'_SCcombo.dta", clear
gen     Y=sc_c_123   if source==1
replace Y=sc_r_2/100 if source==2
replace Y=sc_i_23    if source==3
replace Y=sc_q_2/100 if source==4

* calculate terms for the right hand side of glm commands
prepare_RHS

* The following routines are used for both ANC and SC

* National cascade
cascade_national

* Within the nation, region-specific cascades
cascade_reg

* National cascade adjusted for variation across regions
cascade_nat_reg_adj


*************************************
* The following routines include hftype and can only be done for SC
* Run "prepare_file_for_hftype" if and only if you are doing runs with hftype 
*************************************
*prepare_file_for_hftype

*cascade_national_hftype
*cascade_reg_hftype
*cascade_nat_hftype_adj
*cascade_nat_hftype_reg_adj

end

*******************************************************************

program define main

* Construct working data files and run "ANC_cascade" and/or "SC_cascade"

scalar scid =substr(sruncode,1,2)
scalar spv_R=substr(sruncode,3,2)
scalar spv_U=substr(sruncode,5,2)
scalar sadjusted=0

local lcode=scode
local lcid=scid

* The number of regions varies across countries
* If possible, find a way to save the region labels 
* Specify the number regions in each survey
scalar snregions_HT=11
scalar snregions_MW=3
scalar snregions_NP=5
scalar snregions_SN=6
scalar snregions_TZ=9
scalar snregions=snregions_`lcid'

* This line anticipates that you will have a separate folder for each country
*scalar sdatapath="C:/Users/`lcode'/ICF/Analysis - Report Archive/DHS8 FY3 MR31 Riese Effective coverage methods/Coded data"
scalar sreaddatapath="C:\Users\\`lcode'\ICF\Analysis - Equity in effective coverage\Coded Data"
scalar sdatapath="C:\Users\\`lcode'\ICF\Analysis - Equity in effective coverage\Coded Data"
scalar scratchdatapath="C:\Desktop\ECscratch"

* Construct and save the country-specific data files. The next two lines do not have to be repeated every time the program is run.
prepare_R_files
prepare_U_files

* proportions of women and children in each region are needed for region-adjusted national estimates
calculate_proportions



* ANC
* The next line constructs a file that is saved and does not have to be repeated
make_ANC_composite_file
ANC_cascade

*
* SC
* The next line constructs a file that is saved and does not have to be repeated
make_SC_composite_file
SC_cascade

* Save the coefficients
save_results



* Construct asymmetric confidence intervals
modify_intervals_and_labels




end

*******************************************************************

program define select_countries_and_main

* SPECIFY THE COUNTRIES 

*
scalar sruncode="HT7A71"
scalar scountry="Haiti"
main
*/
scalar sruncode="MW6K7A"
scalar scountry="Malawi"
main


scalar sruncode="NP717H"
scalar scountry="Nepal"
main


scalar sruncode="SN8181"
scalar scountry="Senegal"
main

scalar sruncode="TZ717B"
scalar scountry="Tanzania"
main


end

*******************************************************************
*******************************************************************
*******************************************************************
*******************************************************************
*******************************************************************
* Execution begins here

* sruncode is a six-character string that includes cid + spv_R + spv_U

* Specify the country code and the phase/version (pv)
* spv_R refers to the SPA files and spv_U to the DHS (IR/KR) files
* To run for other countries, just change these 3 scalars
* Be sure you have a folder ready and check the path in "main"


scalar scode_Sara="53348"
scalar scode_Tom ="26216"
scalar scode=scode_Sara

select_countries_and_main






/* 
DESCRIPTIONS OF CASCADES FROM SARA RIESE. Revised for 2022 with restriction to version 2

R files: SPA files, FC, AN, and SC
U files: DHS files, IR and KR

Combinations of R and U
ANC
Step 1: anc_c_123 in IR  X  anc_r_2 in FC 
Step 2:  Step 1 product  X  anc_i_123 in IR
Step 3:  Step 2 product  X  anc_q_2 in AN

Sick child
Step 1:  sc_c_123 in KR  X  sc_r_2 in FC 
Step 2:  Step 1 product  X  sc_i_23 in SC
Step 3:  Step 2 product  X  sc_q_2 in SC


ANC
Step 1: anc_c_123 in IR  X  anc_r_2 in FC 
Step 2: anc_c_123 in IR  X  anc_r_2 in FC  X  anc_i_123 in IR
Step 3: anc_c_123 in IR  X  anc_r_2 in FC  X  anc_i_123 in IR  X  anc_q_2 in AN

Construct IR + FC + IR + AN file. The components will be called source= 1, 2, 3, 4 in that sequence


Sick child
Step 1:  sc_c_123 in KR  X  sc_r_2 in FC 
Step 2:  sc_c_123 in KR  X  sc_r_2 in FC  X  sc_i_23 in SC
Step 3:  sc_c_123 in KR  X  sc_r_2 in FC  X  sc_i_23 in SC  X  sc_q_2 in SC

Construct KR + FC + SC + SC file. The components will be called source= 1, 2, 3, 4 in that sequence

Estimates for subpopulations such as regions are done within subpop

means for 1, 2, 3, 4, 1x2, 1x2x3, 1x2x3x4.  These are models 1, 2, 3, 4, 5, 6, 7

Approach 1 is very simple compared to the others. There are only two products for ANC, and one for sick child, and both only use the DHS files (IR and KR). See below for the files and variable names. 27Apr2021

ANC
Step 1: anc_c_123 in IR  X  anc_i_123 in IR
Step 2:  Step 2 product  X  anc_q_1 in IR

Sick child
Step 1:  sc_c_123 in KR  X  sc_i_1 in KR


