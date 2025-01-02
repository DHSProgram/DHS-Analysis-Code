
* Program to produce neonatal mortality rates for districts in the India NFHS-5 survey.
* Can be adapted for subpopulations in any DHS survey.

* The time interval is the past five years, all births in the KR file except those
*  in the month of interview.

* DHS does not recommend district-level estimates of mortality.
* The program provides the lower and upper ends of 95% confidence intervals.  
* The intervals are very wide.
* The estimates use svy, including subpop (within the state).
* Bayesian procedures would reduce the confidence intervals and move the estimates
*  toward the state value

* Trick: the results are saved into the workfile and then the workfile is reduced
*  to just the saved results

* specify a workspace
cd e:\DHS\DHS_data\scratch

use "…IAKR7DFL.DTA" 
keep v001 v002 v003 v005 v008 v023 v024 v025 sdist bidx b3 b6 b7

* drop births in the month of interview
drop if v008==b3

* Construct a binary variable for neonatal death
gen neonatal_death=0

* To match DHS
replace neonatal_death=1 if b7==0

* To match WHO definition of neonatal
* replace neonatal_death=1 if b6<128

*************
* for testing; comment out the next line for a national run
keep if v024==24
*************

save IAKR7Dtemp.dta, replace

levelsof v024, local(lstates)
foreach ls of local lstates {
use IAKR7Dtemp.dta, clear
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
svy: logit neonatal_death 
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

  svy, subpop(select_dist): logit neonatal_death 
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

* Re-attach the labels for state and district; must confirm the names of these labels
label values state V024
label values dist SDIST

gen NMR=1000*exp(b/(1+exp(b)))
gen NMR_L=1000*exp(L/(1+exp(L)))
gen NMR_U=1000*exp(U/(1+exp(U)))
save results_`ls'.dta, replace
}

format NMR* %6.1f
list, table clean noobs
