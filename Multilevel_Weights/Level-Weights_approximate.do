/*******************************************************************************************************************************
Program: 				Level-Weights_approximate.do
Purpose: 				Approximate the level-weights using DHS data
						The same code can be used to approximate level-weights based on other survey weights, such as v005 or mv005.
Author: 				Mahmoud Elkasabi
Date last modified:		January 24, 2022 by Mahmoud Elkasabi
*******************************************************************************************************************************/
set more off

cd "C:/....."

global datapath "C:/....."

* select your survey
* HR Files
global hrdata "ZWHR72FL"

* open dataset
use "$datapath//$hrdata.dta", clear

** Stage 1: Compile inputs for level-weights calculations ********************************************
*** 1.1: Calculate the total number of completed clusters a_h^c in stratum h for all strata. ***************************
gen a_c_h=.
quietly levelsof hv022, local(lstrata)
quietly foreach ls of local lstrata {
tab hv021 if hv022==`ls', matrow(T)
scalar stemp=rowsof(T)
replace a_c_h=stemp if hv022==`ls'
}

*** 1.2: Add the total number of census clusters A_h^ in stratum h for all strata. 
** Usually the numbers can be found in Table A.3 in the survey final report ***************************
gen A_h = 0
replace A_h = 673  if hv022 == 1
...
replace A_h = 1682 if hv022 == 19

*** 1.3: Add the average number of households per cluster by sampling strata according to the census data M ̅_h. 
** usualy the numbers can be found in Table A.3 in the survey final report. ***************************
gen M_h = 0
replace M_h = 108  if hv022 == 1
...
replace M_h = 98 if hv022 == 19

*** 1.4: Calculate the total number of completed households mc. ***************************
quietly summarize hv001
gen m_c=r(N)

*** 1.5: Add the total number of households according to the census frame. ***************************
** This number can be found in Table A.2 in the final report. ***************************
gen M = 2976119

*** 1.6: Add the number of households selected per cluster. ***************************
** This number can be found in the in the text of Appendix A of the final report. ***************************
gen S_h = 28

*** 1.7: Prepare the DHS household weight. ***************************
gen DHSwt = hv005 / 1000000


** Stage 2: Approximate level-1 and level-2 weights ********************************************

*** 2.1: De-normalize the final weight, using approximated normalization factor. ***************************
gen d_HH = DHSwt * (M/m_c)
*** 2.2: Approximate the level-2 weight based on equal split method (α=0.5). ***************************
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h))
scalar alpha = 0.5
gen wt2 = (A_h/a_c_h)*(f^alpha)
*** 2.3: Approximate the level-1 weight. ***************************
gen wt1 = d_HH/wt2


** Stage 3: Sensitivity analysis ********************************************
** Calculate level-weights based on the following 7 scenarios of α: 0, 0.1, .25, .50, .75, 0.90 and 1.  
local alphas 0 0.1 .25 .50 .75 0.90 1
local i = 1
foreach dom of local alphas{	
gen w2_`i' = (A_h/a_c_h)*(f^`dom')
gen w1_`i' = d_HH/w2_`i'
local ++i
}

