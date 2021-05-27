/*****************************************************************************************************
Program: 			mergeHW.do
Purpose: 			example shown to merge HW to PR file. Notes given on how to merge with other files.  
Author:				Shireen Assaf
Date last modified: May 27, 2021 by Shireen Assaf 

Notes:				Older datasets may not contian the anthropometry variables according to the WHO reference. 
					HW files are created with the WHO reference nutrition indicators that can be merged to datasets.
					Will use two Bangladesh survey as examples since model datasets do not have an HW file.
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

gen hhid =substr(hwcaseid,1,12)
gen hvidx=substr(hwcaseid,13,3)
destring hvidx, replace
gen hwidx=hvidx

gen hwcol_1to3=substr(hhid,1,3)
gen hwcol_4to5=substr(hhid,4,2)
gen hwcol_6to8=substr(hhid,6,3)
gen hwcol_9to12=substr(hhid,9,4)

destring hwcol*to*, replace
gen state_id=hwcol_4to5
gen cluster_id=hwcol_6to8
gen household_id=hwcol_9to12

sort state_id cluster_id household_id hvidx
save HWtemp.dta, replace


*Open PR file
use BDPR41FL.dta, clear

gen hvcol_1to3=substr(hhid,1,3)
gen hvcol_4to5=substr(hhid,4,2)
gen hvcol_6to8=substr(hhid,6,3)
gen hvcol_9to12=substr(hhid,9,4)

destring hvcol*to*, replace
gen state_id=hvcol_4to5
gen cluster_id=hvcol_6to8
gen household_id=hvcol_9to12
sort state_id cluster_id household_id hvidx

*Perform the merge
merge state_id cluster_id household_id hvidx using "HWtemp.dta"

*Erase temporary file
erase HWtemp.dta

