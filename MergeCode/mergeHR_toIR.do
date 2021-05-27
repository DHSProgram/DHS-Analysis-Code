/*****************************************************************************************************
Program: 			mergeHR_toIR.do
Purpose: 			merge HR to IR file. 
Author:				Shireen Assaf
Date last modified: May 27, 2021 by Shireen Assaf 
Note:				This is an example of a many to one merge (m:1)
*****************************************************************************************************/

clear

use ZZHR62FL.dta, clear

*Rename merging variables(identifiers)
	rename (hv001 hv002) (v001 v002)
	
*Save temporary dataset
	save HR_temp.dta, replace
	
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
	
	
	
