/*****************************************************************************************************
Program: 			mergePR_toKRorIR.do
Purpose: 			merge PR to a KR or IR file. Each example is shown seperately. 
Author:				Shireen Assaf
Date last modified: May 27, 2021 by Shireen Assaf 
Note:				The master file is the KR or the IR file (each example shown seperately)
					The using file is the PR file.
					The same steps used to merge IR and PR can be used for MR and PR but with mv variables. 
*****************************************************************************************************/
* Merging KR and PR file

clear all

* Step 1. Open your using data file
use ZZPR62FL.dta, clear
		
*Step 2. Rename IDs (uniquely identify a case)
rename (hv001 hv002 hvidx) (v001 v002 b16)

*Step 3. Save temporary dataset
save temp.dta, replace		
	
*Step 4. Open master dataset
use ZZKR62FL.dta, clear	
	
*Step 5. Merge two datasets
    * drop children who died or are not listed in the household 
	ta b16, m
	ta b5 //if the child is alive
	drop if b16==0 | b16==.
	
	*merging	
	merge 1:1 v001 v002 b16 using temp.dta
	
		
*Step 6. Handle cases that did not match
	tab _merge	
	keep if _merge==3
	
*Step 7. Save new dataset (optional: erase 'using' dataset). 
	*We use the name ZZPRKR but you can change to another name you prefer
	save ZZPRKR.dta, replace
	erase temp.dta

*****************************************************************************************************
*****************************************************************************************************
* Merging IR and PR file

clear all

* Step 1. Open your using data file
use ZZPR62FL.dta, clear
		
*Step 2. Rename IDs (uniquely identify a case)
rename (hv001 hv002 hvidx) (v001 v002 v003)

*Step 3. Save temporary dataset
save temp.dta, replace		
	
*Step 4. Open master dataset
use ZZIR62FL.dta, clear	
	
*Step 5. Merge two datasets
	merge 1:1 v001 v002 v003 using temp.dta
			
*Step 6. Handle cases that did not match
	tab _merge	
	keep if _merge==3
	
*Step 7. Save new dataset (optional: erase 'using' dataset). 
	*We use the name ZZPRIR but you can change to another name you prefer
	save ZZPRIR.dta, replace
	erase temp.dta

