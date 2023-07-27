/*****************************************************************************************************
Program: 			mergeAR_toIRorMR.do
Purpose: 			merge AR data containing HIV test results to a IR or MR file. 
					Each example is shown separately. 
Author:				Shireen Assaf
Date last modified: May 27, 2021 by Shireen Assaf 
Note:				The master file is the IR or the MR file (each example shown separately)
					The using file is the AR file.
					There is an option at the end of the do file to append the IR and MR merged files if needed for the analysis. 
*****************************************************************************************************/
* Merging AR and IR file

clear all

* Open your using data file
use ZZAR61FL.dta, clear
		
* Rename IDs (uniquely identify a case)
rename (hivclust hivnumb hivline) (v001 v002 v003) 

* Save temporary dataset
save ARtemp.dta, replace		
	
* Open master dataset
use ZZIR62FL.dta, clear	
	
*Merge two datasets
merge 1:1 v001 v002 v003 using ARtemp.dta
			
*Handle cases that did not match
tab _merge	
keep if _merge==3

*generate a sex variable that may be used later for a pooled dataset
gen sex=2

*Save new dataset (optional: erase 'using' dataset). 
save ZZIRAR.dta, replace
erase ARtemp.dta

*****************************************************************************************************
*****************************************************************************************************
* Merging AR and MR file

clear all

* Open your using data file
use ZZAR61FL.dta, clear
		
* Rename IDs (uniquely identify a case)
rename (hivclust hivnumb hivline) (mv001 mv002 mv003) 

* Save temporary dataset
save ARtemp.dta, replace		
	
* Open master dataset
use ZZMR61FL.dta, clear	
	
*Merge two datasets
merge 1:1 mv001 mv002 mv003 using ARtemp.dta
			
*Handle cases that did not match
tab _merge	
keep if _merge==3

*generate a sex variable that may be used later for a pooled dataset
gen sex=1

*Save new dataset (optional: erase 'using' dataset). 
save ZZMRAR.dta, replace
erase ARtemp.dta

*****************************************************************************************************
*****************************************************************************************************
* Optional if you want to append MR and IR files that contain the HIV results

use ZZMRAR.dta, clear

*rename mv variables to match the v variables, this is needed before appending files
rename mv* v*

* append the IR and MR files
append using ZZIRAR.dta

* label the sex variable
label define sex 1 "man" 2 "woman"
label values sex sex

*save appended dataset
save IRMRAR.dta, replace
