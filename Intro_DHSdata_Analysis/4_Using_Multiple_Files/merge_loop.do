/*****************************************************************************************************
Program: 			merge_loop.do
Purpose: 			Merge coded KR files to HR files in a loop for several countries
Author:				Shireen Assaf			
Date last modified: July 26, 2023 by Shireen Assaf 
Notes:				This assumes that you have HR and KR coded files from several countries saved for example as CDHRcoded.dta and CDKRcoded.dta. The master file in the case is the KR file. The same logic can be used for other merges. 
*****************************************************************************************************/

* list of HR surveys from 6 countries
*CDHR61FL ETHR71FL KEHR72FL NGHR7BFL TZHR7BFL UGHR7BFL

* list of KR surveys from the same 6 countries
global krdata "CDKR61FL ETKR71FL KEKR72FL NGKR7BFL TZKR7BFL UGKR7BFL"

*list your HR files in this format 
tokenize "CDHR ETHR KEHR NGHR TZHR UGHR"

*being loop
foreach c in $krdata {

*getting country two letter acronym. See notes, the assumption here is that you have KR and HR coded files. 	
local cn=substr("`c'",1,2)

use "`cn'KRcoded.dta", clear

*perform a many to one merge since you are merging household data to KR data (many children in one household).
*this merge would be 1:1 if it was PR to KR merge for instance. See code for other merges in this section.
* the local `1' here refers to the first survey in the tokenize list. 

merge m:1 v001 v002 using "`1'coded.dta"

*renaming the _merge created by the merge in case you want to perform other merges. 
rename _merge KRmerge

* keep only matched cases
keep if KRmerge==3

*save merged file	
save "`cn'HRKRmerged.dta", replace

* this shifts to the next survey in the tokensize list and the loop continues until the list is completed. 
mac shift

  }
  
  