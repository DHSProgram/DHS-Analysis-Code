/*****************************************************************************************************
Program: 			mergeHW.do
Purpose: 			example shown to merge HW to PR file. Notes given on how to merge with other files.  
Author:				Shireen Assaf
Date last modified: July 31, 2023 by Shireen Assaf 

Notes:				Older datasets may not contain the anthropometry variables according to the WHO reference. 
					HW files are created with the WHO reference nutrition indicators that can be merged to datasets.
					Will use two Bangladesh surveys as examples since model datasets do not have an HW file.
*****************************************************************************************************/

*For HW files that have hwhhid

*Open HW file
use BDHW4JFL.dta, clear

*Rename ID variables
rename hwhhid hhid
rename hwline hvidx

*Save temp files
save HWtemp.dta, replace

*Open PR file
use BDPR4JFL.dta, clear

*Perform the merge
merge 1:1 hhid hvidx using "HWtemp.dta"

*Erase temporary file
erase HWtemp.dta

******************************************************************************

* Some HW files have hwcaseid instead of hwhhid. The following code can be used in this case. 

*Open HW file
use BDHW41FL.dta, clear

*creating unique identifier variables from hwcaseid

gen hhid =substr(hwcaseid,1,12)
gen hvidx=substr(hwcaseid,13,3)
destring hvidx, replace

gen cluster_id=substr(hhid,6,3)
gen household_id=substr(hhid,9,4)

destring cluster_id, replace
destring household_id, replace

sort cluster_id household_id hvidx
save HWtemp.dta, replace


*Open PR file
use BDPR41FL.dta, clear

gen cluster_id=substr(hhid,6,3)
gen household_id=substr(hhid,9,4)

destring cluster_id, replace
destring household_id, replace

sort cluster_id household_id hvidx

*Perform the merge
merge cluster_id household_id hvidx using "HWtemp.dta"

*Erase temporary file
erase HWtemp.dta



