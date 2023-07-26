/*****************************************************************************************************
Program: 			pool_trends.do
Purpose: 			This is an example of how to append two surveys from different years for the same country for a trend analysis. We use DHS data from Nigeria 2013 and 2018 as an example and also show how to append in a loop for several countries. See notes below. 
Author:				Shireen Assaf
Date last modified: July 26, 2023 by Shireen Assaf
*****************************************************************************************************/

* Append two surveys from the same country
	
use NGIR6AFL.dta, clear  // open first survey
gen yr=1 // create a year variable
	
append using NGIR7BFL.dta // append using second survey
replace yr=2 if yr==. // replace values for second survey
	
label var yr "year of survey"
label define yr 1 2013 2 2018
label  values yr yr
tab yr
	
* can also just check v007
tab v007

gen wt=v005/1000000

*run programs to code country-specific strata
* Use the Survey_strata.do file from section 2
quietly do "Survey_strata.do"
	
* svy set for combined data
egen strata2=group(yr strata)
egen v021r = group(yr v021)
svyset v021r [pw=wt], strata(strata2) singleunit(centered)
	
save NGappend.dta, replace // save appended file

	
*********************************************

* how to run a loop for appending files for trend analysis.
* the code will append each two sets of surveys for each country.

* create two globals for each survey list. The irdata1 global is the most recent survey that will be appending to irdata2 which is an earlier survey for each country. The list of countries should be in the same order for both globals. 

global irdata1 "BDIR7RFL BJIR71FL CMIR71FL KEIR72FL LBIR7AFL RWIR81FL SLIR7AFL UGIR7BFL ZMIR71FL ZWIR72FL"
global irdata2 "BDIR51FL BJIR51FL CMIR44FL KEIR42FL LBIR51FL RWIR53FL SLIR51FL UGIR52FL ZMIR51FL ZWIR52FL"


tokenize $irdata1

foreach c in $irdata2 {
use "`1'coded.dta", clear
gen yr=1

append using "`c'coded.dta"
replace yr=2 if yr==.   

local cn = substr(v000,1,2)
save "`cn'append.dta", replace

mac shift 1
}

*/

	
