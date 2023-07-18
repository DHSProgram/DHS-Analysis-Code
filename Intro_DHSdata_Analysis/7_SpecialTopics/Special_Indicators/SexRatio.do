/*******************************************************************************************************************************
Program: 				SexRatio.do
Purpose: 				Construct sex ratio
Author: 				Tom Pullum
Date last modified:		Feb 6, 2023 by Tom Pullum

Description:
The sex ratio can be defined in different ways. In biology it is the proportion of individuals who are female. In demography it is usually the number of males per 100 females. You say you want the number of females per 1000 males. The following Stata program calculates males per 100 females and females per 1000 males and saves the results as scalars. In the labels, P, L, and U are the point estimate, the lower end of the 95% confidence interval, and the upper end of the 95% confidence interval, respectively. 
*******************************************************************************************************************************/

*** Calculate the sex ratio at birth for births in the past 5 years using the KR file ***

* using the India 2019-2021 DHS survey as an example but any survey can be used. 
use "IAKR7EFL.DTA" , clear

egen cluster_ID=group(v024 v001)
svyset cluster_ID [pweight=v005], strata(v023) singleunit(centered)

tab b4 [iweight=v005/1000000]

* Sex ratio defined as males per 100 females
gen     m_per_100f=0
replace m_per_100f=1 if b4==1

svy: logit m_per_100f
matrix T=r(table)
matrix list T

scalar P_m_per_100f=100*exp(T[1,1])
scalar L_m_per_100f=100*exp(T[5,1])
scalar U_m_per_100f=100*exp(T[6,1])

* Sex ratio defined as females per 1000 males
gen     f_per_1000m=0
replace f_per_1000m=1 if b4==2

svy: logit f_per_1000m
matrix T=r(table)
matrix list T

scalar P_f_per_1000m=1000*exp(T[1,1])
scalar L_f_per_1000m=1000*exp(T[5,1])
scalar U_f_per_1000m=1000*exp(T[6,1])

scalar list

****************************************************************
*** Sex ratio by covariates *** 

* The code below was delveloped for India but can be used for other surveys. 
* India is a special case because it has districts and states. 

* Program to produce the sex ratio at birth for districts in the India NFHS-5 survey and will produce a Stata data file for each state.
* Can be adapted for subpopulations in any DHS survey.

* Two definitions of the sex ratio are used.

* The time interval is the past five years, all births in the KR file, except those
*  in the month of interview.

* The program provides the lower and upper ends of 95% confidence intervals.  
* The intervals are wide.
* The estimates use svy, including subpop (within the state).
* Bayesian procedures would reduce the confidence intervals and move the estimates toward the state value

* The results are saved into the workfile and then the workfile is reduced to just the saved results.
* A seperate data file will be produced for each state with the estimates. 

use "IAKR7EFL.DTA" 
* keep the variables of interest, below the India country-specific variable sdist for the districts is included
keep v001 v002 v003 v005 v008 v023 v024 v025 sdist b4

* Construct binary variable m_per_f
gen m_per_f=0
replace m_per_f=1 if b4==1

save IAKR7Etemp.dta, replace

levelsof v024, local(lstates)

foreach ls of local lstates {
use IAKR7Etemp.dta, clear
keep if v024==`ls'

* Trick: use this file to save the results
gen vstate=`ls'
gen vdist=.
gen vb=.
gen vL=.
gen vU=.
gen vcases=.

svyset v001 [pweight=v005], strata(v023) singleunit(centered)

* First do the state estimate
svy: logit m_per_f 
matrix T=r(table)
replace vb=T[1,1]  if _n==1
replace vL=T[5,1]  if _n==1
replace vU=T[6,1]  if _n==1
replace vcases=e(N) if _n==1

* Now loop through all the districts in this state
scalar sline=2
levelsof sdist, local(ldistricts)
  quietly foreach ld of local ldistricts {

  * Construct a variable for subpop to select the district
  gen select_dist=1 if sdist==`ld'

  svy, subpop(select_dist): logit m_per_f 
  matrix T=r(table)
  replace vdist=`ld' if _n==sline
  replace vb=T[1,1]  if _n==sline
  replace vL=T[5,1]  if _n==sline
  replace vU=T[6,1]  if _n==sline
  replace vcases=e(N) if _n==sline
  drop select_dist
  scalar sline=sline+1
  }

* Finished with a state; save the results for this state in a data file
drop if vb==.
keep vstate vdist vb vL vU vcases

rename v* *

* Re-attach the labels for state and district; must confirm the label names
label values state V024
label values dist SDIST

* Sex ratio defined as males per 100 females
gen P_m_per_100f=100*exp(b)
gen L_m_per_100f=100*exp(L)
gen U_m_per_100f=100*exp(U)

* Sex ratio defined as females per 1000 males
gen P_f_per_1000m=1000*exp(-b)
gen L_f_per_1000m=1000*exp(-L)
gen U_f_per_1000m=1000*exp(-U)

save results_`ls'.dta, replace
}

format P_* L_* U_* %6.1f
list, table clean noobs
