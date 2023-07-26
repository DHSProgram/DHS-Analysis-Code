/*****************************************************************************************************
Program: 			mergeHHhead_toIR.do
Purpose: 			Construct a file that attaches the characteristics of the household head to each eligible woman in the household.
Author:				Tom Pullum
Date last modified: June 16, 2023 by Tom Pullum
*****************************************************************************************************/

use "ZZPR62FL.DTA", clear 

* reduce to just household heads
keep if hv101==1

* select variables you need, not necessarily as illustrated here
keep hvidx hv0* hv1*

* rename to avoid possible confusion
rename hv* head_hv*

* specify variables for the merge
rename head_hv001 cluster 
rename head_hv002 hh
sort cluster hh
save temp.dta, replace

* open IR file
use "ZZIR62FL.DTA", clear 
rename v001 cluster
rename v002 hh
sort cluster hh

* merge is m:1 because there may be more than 1 eligible woman per household
merge m:1 cluster hh using temp.dta
tab _merge

* _merge=2 for households that do not include any eligible women
drop if _merege==2

drop _merge
