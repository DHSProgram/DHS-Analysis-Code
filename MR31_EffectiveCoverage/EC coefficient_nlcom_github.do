/*****************************************************************************************************
Program: 			      EC coefficient_nlcom_github.do
Purpose: 			      "stack" coefficients to take advantage of nlcom's use of the delta method
							to calculate variance estimates for EC estimates
Author:					  Tom Pullum and Sara Riese			
Date last modified: 	  August 11 2021 

*****************************************************************************************************/


/*

This program calculates effective coverage coefficients, and confidence intervals,
 for the ANC (antenatal care) and SC (sick child) cascades. 

It stacks the data files and uses a logit regression framework within glm.  
All components are in a range from 0 to 1 but can take values other than 0 and 1. 
Components that were originally in a range from 0 to 100 are divided by 100.

glm with family(binomial) link(logit) can handle Y values between >0 and <1. logit cannot.

Original version prepared by Tom Pullum in March/April 2021, tom.pullum@icf.com 
modified in summer 2021 by Sara Riese, sara.riese@icf.com

"R" refers to SPA data (FC or AN or SC files) and "U" refers to DHS data (IR or KR files)
"R" for "readiness" and "U" for "users"

"cid" for country id, "pv" for phase+version

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
replace cluster_R=9999
replace stratum_R=9999
replace cluster_Q=facil
replace stratum_Q=9999

}

end


*******************************************************************

program define prepare_R_files

* This routine prepares the AN and FC and SC files with a standard format

local ldatapath=sdatapath
local lcid=scid
local lpv=spv_R

use "`ldatapath'\\`lcid'\\`lcid'AN`lpv'FLSPcoded.dta", clear
keep facil hftype spastrata clwt fwt region2 anc_q_2 anc_q_3 
specify_wt_cl_strata_R
save "`ldatapath'\\`lcid'\\`lcid'_AN.dta", replace

use "`ldatapath'\\`lcid'\\`lcid'FC`lpv'FLSPready.dta", clear
keep facil hftype spastrata fwt region2 anc_r_2 anc_r_3 sc_r_2 sc_r_3
specify_wt_cl_strata_R
save "`ldatapath'\\`lcid'\\`lcid'_FC.dta", replace

use "`ldatapath'\\`lcid'\\`lcid'SC`lpv'FLSPcoded.dta", clear
keep facil hftype spastrata clwt fwt region2 sc_i_23 sc_q_2 sc_q_3 
specify_wt_cl_strata_R
save "`ldatapath'\\`lcid'\\`lcid'_SC.dta", replace

end

*******************************************************************

program define prepare_U_files

* This routine prepares the IR and KR files with a standard format

local ldatapath=sdatapath
local lcid=scid
local lpv=spv_U

* weights, clusters, strata are the same in both the U files

use "`ldatapath'\\`lcid'\\`lcid'IR`lpv'FLcoded.dta", clear
keep v001 v002 v003 v005 strata region2 anc_c_123 anc_i_123 anc_q_1
gen cluster_U=v001
gen stratum_U=strata
gen  weight_U=v005
save "`ldatapath'\\`lcid'\\`lcid'_IR.dta", replace

use "`ldatapath'\\`lcid'\\`lcid'KR`lpv'FLcoded.dta", clear
keep v001 v002 v003 v005 strata region2 hftype sc_c_123 ch_diar* ch_ari* sc_i_1


keep v001 v002 v003 v005 strata region2 hftype sc_c_123 sc_i_1
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

* Setup for models: define svyset, "s" variables, "model" variables for subpop
if scid=="MW" | scid=="HT" {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

if scid=="NP" | scid=="SN" | scid=="TZ"  {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

save "`ldatapath'\\`lcid'\\`lcid'_ANCcombo.dta", replace

end

*******************************************************************
program define make_ANC_approach1_file

* In order to be calculated in the same way as the other approaches, the IR files for Approach 1 also need to be "stacked".  Coverage is source=1, intervention is source=3, and quality is source=4.

local ldatapath=sdatapath
local lcid=scid

use "`ldatapath'\\`lcid'\\`lcid'_IR.dta", clear
gen source=1
append using "`ldatapath'\\`lcid'\\`lcid'_IR.dta"
replace source=3 if source==.
append using "`ldatapath'\\`lcid'\\`lcid'_IR.dta"
replace source=4 if source==.

local lnames cluster stratum weight
foreach lname of local lnames {
gen `lname'=`lname'_U
}

tab source, summarize(cluster)
tab source, summarize(weight)
tab source, summarize(stratum)

xi, noomit i.source
rename _I* *
rename source_* s*

label variable s1 "cov"
label variable s3 "int"
label variable s4 "qual"

* Setup for models: define svyset, since these are only DHS vars, use the same svyset for all datasets
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)

save "`ldatapath'\\`lcid'\\`lcid'_ANCA1.dta", replace

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

* Setup for models: define svyset, "s" variables, "model" variables for subpop
if scid=="MW" | scid=="HT" {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

if scid=="NP" | scid=="SN" | scid=="TZ"  {
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)
}

save "`ldatapath'\\`lcid'\\`lcid'_SCcombo.dta", replace

end


******************************************************************


program define make_SC_approach1_file

* In order to be calculated in the same way as the other approaches, the KR files for Approach 1 also need to be "stacked".
*  Coverage is source=1, intervention is source=3, 

local ldatapath=sdatapath
local lcid=scid

use "`ldatapath'\\`lcid'\\`lcid'_KR.dta", clear
gen source=1

append using "`ldatapath'\\`lcid'\\`lcid'_KR.dta"
replace source=3 if source==.

local lnames cluster stratum weight
foreach lname of local lnames {
gen `lname'=`lname'_U
}

xi, noomit i.source
rename _I* *
rename source_* s*

label variable s1 "cov"
label variable s3 "int"

* Setup for models: define svyset, since these are only DHS vars, use the same svyset for all datasets
svyset cluster [pweight=weight], strata(stratum) singleunit(centered)

save "`ldatapath'\\`lcid'\\`lcid'_SCA1.dta", replace

end


******************************************************************

program define prepare_for_nlcom_ANCA1

* Construct scalars that give means as functions of e(b) following logit
* These scalars are essentially formulas for means as antilogits, expressed
*   as functions of the terms in e(b) following a logit regression ONLY FOR ANC APPROACH 1

local ln1234 1 3 4

foreach ln of local ln1234 {
  local lterm="_b[s`ln']"
  scalar smean_s`ln'="(exp(`lterm')/(1+exp(`lterm')))"
}

scalar list smean_s1 smean_s3 smean_s4

end



******************************************************************


program define prepare_for_nlcom_SCA1

* Construct scalars that give means as functions of e(b) following logit
* These scalars are essentially formulas for means as antilogits, expressed
*   as functions of the terms in e(b) following a logit regression ONLY FOR SC APPROACH 1

local ln1234 1 3

foreach ln of local ln1234 {
  local lterm="_b[s`ln']"
  scalar smean_s`ln'="(exp(`lterm')/(1+exp(`lterm')))"
}

scalar list smean_s1 smean_s3

end

*******************************************************************

program define prepare_for_nlcom

* Construct scalars that give means as functions of e(b) following logit
* These scalars are essentially formulas for means as antilogits, expressed
*   as functions of the terms in e(b) following a logit regression FOR APPROACHES 2 AND 3

local ln1234 1 2 3 4

foreach ln of local ln1234 {
  local lterm="_b[s`ln']"
  scalar smean_s`ln'="(exp(`lterm')/(1+exp(`lterm')))"
}

scalar list smean_s1 smean_s2 smean_s3 smean_s4

end

*******************************************************************
program define run_nlcom_ANCA1

scalar sy1   =smean_s1
scalar sy3   =smean_s3
scalar sy4   =smean_s4
scalar sy13 =sy1 +"*"+sy3
scalar sy134=sy13+"*"+sy4

local ly1   =sy1 
local ly3   =sy3 
local ly4   =sy4 
local ly13 =sy13 
local ly134=sy134 

nlcom (`ly1') (`ly3') (`ly4') (`ly13') (`ly134'), post
matlist e(b)
matlist e(V)

end


******************************************************************

program define run_nlcom_SCA1

scalar sy1   =smean_s1
scalar sy3   =smean_s3
scalar sy13 =sy1 +"*"+sy3

local ly1   =sy1 
local ly3   =sy3  
local ly13 =sy13 

nlcom (`ly1') (`ly3') (`ly13'), post
matlist e(b)
matlist e(V)

end


******************************************************************
program define run_nlcom

scalar sy1   =smean_s1
scalar sy2   =smean_s2
scalar sy3   =smean_s3
scalar sy4   =smean_s4
scalar sy12  =sy1  +"*"+sy2
scalar sy123 =sy12 +"*"+sy3
scalar sy1234=sy123+"*"+sy4

local ly1   =sy1 
local ly2   =sy2
local ly3   =sy3 
local ly4   =sy4 
local ly12  =sy12 
local ly123 =sy123 
local ly1234=sy1234 

nlcom (`ly1') (`ly2') (`ly3') (`ly4') (`ly12') (`ly123') (`ly1234'), post
matlist e(b)
matlist e(V)

end

******************************************************************


program define cascade_national_ANCA1

* National-level estimates
* "post" is included in the nlcom line to produce e(b) and e(V)
* "asis" is included so coefficients will not be aliased
* The saved 1x1 matrices are converted to better output later

prepare_for_nlcom_ANCA1

local lC=s_ANC_SC
local lalt23=salt23
local ln1234 1 3 4

svy: glm Y s1 s3 s4, family(binomial) link(logit) nocons asis iterate(30)
matlist e(b)
matlist e(V)
run_nlcom_ANCA1
matrix B_nat_`lC'_alt`lalt23'=r(b) 
matrix V_nat_`lC'_alt`lalt23'=r(V)

end


*******************************************************************


program define cascade_national_SCA1

* National-level estimates
* "post" is included in the nlcom line to produce e(b) and e(V)
* "asis" is included so coefficients will not be aliased
* The saved 1x1 matrices are converted to better output later

prepare_for_nlcom_SCA1

local lC=s_ANC_SC
local lalt23=salt23
local ln1234 1 3

svy: glm Y s1 s3, family(binomial) link(logit) nocons asis iterate(30)
matlist e(b)
matlist e(V)
run_nlcom_SCA1
matrix B_nat_`lC'_alt`lalt23'=r(b) 
matrix V_nat_`lC'_alt`lalt23'=r(V)

end

******************************************************************

program define cascade_national

* National-level estimates
* "post" is included in the nlcom line to produce e(b) and e(V)
* "asis" is included so coefficients will not be aliased
* The saved 1x1 matrices are converted to better output later

prepare_for_nlcom

local lC=s_ANC_SC
local lalt23=salt23
local ln1234 1 2 3 4

svy: glm Y s1 s2 s3 s4, family(binomial) link(logit) nocons asis iterate(30)
matlist e(b)
matlist e(V)
run_nlcom
matrix B_nat_`lC'_alt`lalt23'=r(b)
matrix V_nat_`lC'_alt`lalt23'=r(V)

end




*******************************************************************

program define ANC_cascade

* Different versions for alternatives 2 and 3

* Note that all indicators must be in a range from 0 to 1 

local ldatapath=sdatapath
local lcid=scid

*ANC_1
use "`ldatapath'\\`lcid'\\`lcid'_ANCA1.dta", clear
gen     Y=anc_c_123   if source==1
replace Y=anc_i_123   if source==3
replace Y=anc_q_1/100 if source==4

scalar s_ANC_SC="ANC"
scalar salt23="1"
cascade_national_ANCA1

* ANC_2
use "`ldatapath'\\`lcid'\\`lcid'_ANCcombo.dta", clear
gen     Y=anc_c_123   if source==1
replace Y=anc_r_2/100 if source==2
replace Y=anc_i_123   if source==3
replace Y=anc_q_2/100 if source==4

scalar s_ANC_SC="ANC"
scalar salt23="2"
cascade_national

* ANC_3
use "`ldatapath'\\`lcid'\\`lcid'_ANCcombo.dta", clear
gen     Y=anc_c_123   if source==1
replace Y=anc_r_3/100 if source==2
replace Y=anc_i_123   if source==3
replace Y=anc_q_3/100 if source==4

scalar s_ANC_SC="ANC"
scalar salt23="3"
cascade_national

end


*********************************

program define SC_cascade

* Different versions for alternatives 2 and 3

local ldatapath=sdatapath
local lcid=scid

* SC_1
use "`ldatapath'\\`lcid'\\`lcid'_SCA1.dta", clear
gen     Y=sc_c_123   if source==1
replace Y=sc_i_1    if source==3

scalar s_ANC_SC="SC"
scalar salt23="1"
cascade_national_SCA1

* SC_2
use "`ldatapath'\\`lcid'\\`lcid'_SCcombo.dta", clear
gen     Y=sc_c_123   if source==1
replace Y=sc_r_2/100 if source==2
replace Y=sc_i_23    if source==3
replace Y=sc_q_2/100 if source==4

/*
* Important recode for hftype
* For source=1, there is no Y, there are just different values of hftype.  We must construct Y
local lf=1
while `lf'<=4 {
gen     Y`lf'=0 if source==1 
replace Y`lf'=1 if source==1 & hftype==`lf' & Y==1
replace Y`lf'=Y if source>1  & hftype==`lf'
local lf=`lf'+1
}
*/

scalar s_ANC_SC="SC"
scalar salt23="2"
cascade_national


* SC_3
use "`ldatapath'\\`lcid'\\`lcid'_SCcombo.dta", clear
gen     Y=sc_c_123   if source==1
replace Y=sc_r_3/100 if source==2
replace Y=sc_i_23    if source==3
replace Y=sc_q_3/100 if source==4

* Important recode for hftype
* For source=1, there is no Y, there are just different values of hftype.  We must construct Y
local lf=1
while `lf'<=4 {
gen     Y`lf'=0 if source==1 
replace Y`lf'=1 if source==1 & hftype==`lf' & Y==1
replace Y`lf'=Y if source>1  & hftype==`lf'
local lf=`lf'+1
}

scalar s_ANC_SC="SC"
scalar salt23="3"
cascade_national

end


*******************************************************************

program define save_results

/*

This is a lengthy routine to save the results in a dta file.

Loop through the saved matrices; extract elements from matrices; save point estimate and se 
Structure for B (1x7); similar for V (7x7)

National:                    matrix B_nat_`lout'_alt`lv'

lC is outcome ANC or SC
lv is version 1 or 2 or 3
If there is no distinction between 2 and 3, the same line of data will be produced for both 2 and 3

Example: matrix list B_nat_ANC_alt2; the elements refer to 1, 2, 3, 4, 12, 123, 1234
  for outcome ANC and version 2

Notation is different for alt1 since there are different number of models for ANC and SC in alt1

*/

local ldatapath=sdatapath
local lcid=scid
clear
set obs 2000

gen line=_n
gen str2 vcountry="`lcid'"
gen str3 voutcome="."
gen str2 vversion="."
gen vmodel=.
gen vEC_estimate=.
gen vse=.

local loutcomes ANC SC

scalar sline=1

* Save national and regional results from alt1; these are indexed
*  differently because there are a different number of models in each


local lversions 1
local lmodels 1 2 3 4 5   //These are not correctly aligned with the model labels, will be corrected later


* SAVE NATIONAL RESULTS for ANC Alt1 
  foreach lv of local lversions   {
* Extract the coefficient and se from saved matrices
****************************************
matrix B=J(1,5,.)
matrix V=J(5,5,.)
capture confirm matrix B_nat_ANC_alt`lv'
display _rc
  if _rc==0 {
  matrix             B=B_nat_ANC_alt`lv'
  matrix             V=V_nat_ANC_alt`lv'
  }
****************************************

quietly foreach lm of local lmodels {
replace voutcome="ANC"      if line==sline
replace vversion="`lv'"        if line==sline
replace vmodel=`lm'            if line==sline
replace vEC_estimate=B[1,`lm'] if line==sline
replace vse=sqrt(V[`lm',`lm']) if line==sline

scalar sline=sline+1
    
  }
}


if voutcome=="ANC" & vversion=="1" {
cap recode vmodel (2=3) (3=4) (4=6) (5=7)   //aligning labels correctly
}


local lversions 1
local lmodels 1 2 3  //These are not correctly aligned with the model labels, will be corrected later



* SAVE NATIONAL RESULTS for SC Alt1 
  foreach lv of local lversions   {

* Extract the coefficient and se from saved matrices
****************************************
matrix B=J(1,3,.)
matrix V=J(3,3,.)
capture confirm matrix B_nat_SC_alt`lv'
display _rc
  if _rc==0 {
  matrix             B=B_nat_SC_alt`lv'
  matrix             V=V_nat_SC_alt`lv'
  }
****************************************

quietly foreach lm of local lmodels {
replace voutcome="SC"      if line==sline
replace vversion="`lv'"        if line==sline
replace vmodel=`lm'            if line==sline
replace vEC_estimate=B[1,`lm'] if line==sline
replace vse=sqrt(V[`lm',`lm']) if line==sline

scalar sline=sline+1
    }
  }


**APPROACHES 2 and 3 FROM HERE



local lversions 2 3
local lmodels 1 2 3 4 5 6 7


* SAVE NATIONAL RESULTS for alt2 and alt3
foreach lC of local loutcomes {
  foreach lv of local lversions   {

* Extract the coefficient and se from saved matrices
****************************************
matrix B=J(1,7,.)
matrix V=J(7,7,.)
capture confirm matrix B_nat_`lC'_alt`lv'
display _rc
  if _rc==0 {
  matrix             B=B_nat_`lC'_alt`lv'
  matrix             V=V_nat_`lC'_alt`lv'
  }
****************************************

quietly foreach lm of local lmodels {
replace voutcome="`lC'"      if line==sline
replace vversion="`lv'"        if line==sline
replace vmodel=`lm'            if line==sline
replace vEC_estimate=B[1,`lm'] if line==sline
replace vse=sqrt(V[`lm',`lm']) if line==sline
scalar sline=sline+1
    }
  }
}


drop if voutcome=="."
keep v*
rename v* *
rename EC_estimate P
drop if P==.
rename se se_of_P
label variable se_of_P "se of P"


recode model (3=6) (2=3) if outcome== "SC" & version== "1"   //aligning labels correctly

* Construct symmetric 95% ci
gen L=P-1.96*se_of_P
gen U=P+1.96*se_of_P

save "`ldatapath'\\`lcid'\\`lcid'_results_nat.dta", replace

end

*******************************************************************

program define modify_results

* This routine can be used by itself after the "results" file has been prepared.
* It allows you to manipulate the output without running the whole program.

* It is used to construct asymmetric confidence intervals.
* The work with Sara Sauer and Hannah Leslie showed that this assymetry is important
* Approach is to estimate the se of b=logit(P), construct a ci for b, then apply 
*   antilogit to that ci.
* delta is the difference in widths between adjusted and not-adjusted intervals

local ldatapath=sdatapath
local lcid=scid

use "`ldatapath'\\`lcid'\\`lcid'_results_nat.dta", clear

gen b= log(P/(1-P))

* s is the estimated se of b, using the delta method
gen se_of_b=se_of_P/(P*(1-P))

gen L_adj=exp(b-1.96*se_of_b)/(1+exp(b-1.96*se_of_b))
gen U_adj=exp(b+1.96*se_of_b)/(1+exp(b+1.96*se_of_b))
gen width=U-L
gen width_adj=U_adj-L_adj

gen delta=width_adj-width

format P se* U* L* width* delta %8.4f

order country outcome version model P L_adj U_adj width_adj b se_of_b L U width delta se_of_P

label variable P "EC estimate"
label variable L_adj "Lower end of asymmetric 95% ci"
label variable U_adj "Upper end of asymmetric 95% ci"
label variable width_adj "Width of asymmetric 95% ci"

label variable L "Lower end of symmetric 95% ci"
label variable U "Upper end of symmetric 95% ci"
label variable width "Width of symmetric 95% ci"

label variable b "logit of P"
label variable se_of_b "se of b"

label variable delta "Symmetric width minus asymmetric width"

label variable outcome "ANC or SC"
label variable version "Alternative 2 or 3"
label define lmodel 1 "source 1" 2 "source 2" 3 "source 3" 4 "source 4" 5 "1x2" 6 "1x2x3" 7 "1x2x3x4"
label values model lmodel 

list, table clean
* Save a version in the country folder
save "`ldatapath'\\`lcid'\\`lcid'_results_modified.dta", replace

* Save a version in the main folder
save "`ldatapath'\\`lcid'_results_modified.dta", replace

end

*******************************************************************

program define main

scalar scid =substr(sruncode,1,2)
scalar spv_R=substr(sruncode,3,2)
scalar spv_U=substr(sruncode,5,2)

local lcid=scid

* This line provides the file path to the umbrella folder that holds a folder for each country in your analysis
scalar sdatapath="C:/Users/53348/ICF/Analysis - Yr3 Effective Coverage documents/Coded data"

* Prepare the single files

prepare_R_files
prepare_U_files

* Prepare the combined files
make_ANC_approach1_file
make_ANC_composite_file
make_SC_approach1_file
make_SC_composite_file


* Produce the coefficients
ANC_cascade
SC_cascade

* Save the coefficients
save_results

* Construct asymmetric confidence intervals
modify_results

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

scalar sruncode="HT7A71"
main

scalar sruncode="MW6K7A"
main

scalar sruncode="NP717H"
main

scalar sruncode="SN8181"
main

scalar sruncode="TZ717B"
main

/* 

DESCRIPTIONS OF CASCADES FROM SARA RIESE

R files: SPA files, FC, AN, and SC
U files: DHS files, IR and KR

Combinations of R and U
ANC
Step 1: anc_c_123 in IR  X  anc_r_2 or anc_r_3 in FC 
Step 2:  Step 1 product  X  anc_i_123 in IR
Step 3:  Step 2 product  X  anc_q_2 or anc_q_3 in AN

Sick child
Step 1:  sc_c_123 in KR  X  sc_r_2 or sc_r_3 in FC 
Step 2:  Step 1 product  X  sc_i_23 in SC
Step 3:  Step 2 product  X  sc_q_2 or sc_q_3 in SC


ANC
Step 1: anc_c_123 in IR  X  anc_r_2 or anc_r_3 in FC 
Step 2: anc_c_123 in IR  X  anc_r_2 or anc_r_3 in FC  X  anc_i_123 in IR
Step 3: anc_c_123 in IR  X  anc_r_2 or anc_r_3 in FC  X  anc_i_123 in IR  X  anc_q_2 or anc_q_3 in AN

Construct IR + FC + IR + AN file. The components will be called source= 1, 2, 3, 4 in that sequence


Sick child
Step 1:  sc_c_123 in KR  X  sc_r_2 or sc_r_3 in FC 
Step 2:  sc_c_123 in KR  X  sc_r_2 or sc_r_3 in FC  X  sc_i_23 in SC
Step 3:  sc_c_123 in KR  X  sc_r_2 or sc_r_3 in FC  X  sc_i_23 in SC  X  sc_q_2 or sc_q_3 in SC

Construct KR + FC + SC + SC file. The components will be called source= 1, 2, 3, 4 in that sequence

Approach 1 is very simple compared to the others. There are only two products for ANC, and one for sick child, and both only use the DHS files (IR and KR). See below for the files and variable names. 27Apr2021

ANC
Step 1: anc_c_123 in IR  X  anc_i_123 in IR
Step 2:  Step 2 product  X  anc_q_1 in IR

Sick child
Step 1:  sc_c_123 in KR  X  sc_i_1 in KR


