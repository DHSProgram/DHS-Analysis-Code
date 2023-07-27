/*****************************************************************************************************
Program: 			mergeHR_toIR.do
Purpose: 			merge HR to IR file. 
Author:				Shireen Assaf
Date last modified: July 27, 2021 by Shireen Assaf 
Note:				This is an example of a many to one merge (m:1)
*****************************************************************************************************/

clear

* Open HR dataset, this is your using dataset
use ZZHR62FL.dta, clear

*Rename merging variables(identifiers)
rename (hv001 hv002) (v001 v002)

*optional, keep relevant vars. 
*For instance, lets say you only need information on source of drinking water (hv201)
*keep v001 v002 hv201

*Save temporary dataset
save HRtemp.dta, replace
	
*Open master dataset
use ZZIR62FL.dta, clear

*Merge two datasets
merge m:1 v001 v002 using HRtemp.dta
	
*Handle cases that did not match
tab _merge
keep if _merge==3
	
*Save new dataset (optional: erase 'using' dataset)
save ZZHRIR.dta, replace
erase HRtemp.dta
	
	
	
