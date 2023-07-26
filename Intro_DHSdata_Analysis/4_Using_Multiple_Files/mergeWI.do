/*****************************************************************************************************
Program: 			mergeWI.do
Purpose: 			example shown to merge WR to IR file. Notes given on how to merge with other files.  
Author:				Shireen Assaf
Date last modified: May 27, 2021 by Shireen Assaf 

Notes:				Older datasets sometimes do not contain the wealth index. To include the wealth index, a WI file was created for these surveys. Will use the Bangladesh 1999-2000 survey as an example since model datasets do not have an WI file.
					
					Notes are given at the end of the file on how to perform other merges of WI file with other file types. 
*****************************************************************************************************/

*open IR file
use BDIR41FL.dta, clear

*generate the ID variable with the same name as in the WI file
gen whhid=substr(caseid,1,12)

*perform the merge
merge m:1 whhid using "BDWI41FL.dta"

* keep only matched cases
keep if _merge==3
drop _merge
  
*gen the wealth variable name v190 as in other surveys
gen v190=wlthind5
label values v190 wlthind5

*save your file 
save BDWIIR41.dta, replace  

******************************************************************************

* Merging WI file to other file types


* Same code above can be used to merge to KR file

/* To merge to MR file you only need to change how the whhid and the v190 variables are generated as follows:
gen whhid=substr(mcaseid,1,12)
gen mv190=wlthind5
label values mv190 wlthind5
*/

/*To merge to PR or HR files you only need to change how the whhid and the v190 variables are generated as follows:
gen whhid=substr(hhid,1,12)
gen hv270=wlthind5
label values hv270 wlthind5
*/



