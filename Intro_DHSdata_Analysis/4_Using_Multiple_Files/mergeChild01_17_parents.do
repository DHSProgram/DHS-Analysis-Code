/*****************************************************************************************************
Program: 			mergeChild01_17_parents.do
Purpose: 			Program to merge children 0-17 in the PR file with ALL the data about their
   mothers and fathers and ALL the data in the BR file
Author:				Tom Pullum
Date last modified: Feb 14, 2023 by Tom Pullum
*****************************************************************************************************/

/* Description: 
Here are the category labels for "Mother's status", with more explanation:
0 "Dead"                   hv111==0
1 "Not in HH"              (hv111>0 & hv112==0) | hv112==. 
2 "Not eligible for IR"    hv117=0, usually because age>49, sometimes not de facto  
3 "Not in IR"              Eligible for IR but not found in IR: nonresponse
4 "In IR"                  mother is found in the IR file

Here are the category labels for "Father's status", with more explanation:
0 "Dead"                   hv113==0
1 "Not in HH"              (hv113>0 & hv114==0) | hv114==. 
2 "Not eligible for MR"    hv118=0, because of subsampling, because age>limit, sometimes not de facto  
3 "Not in MR"              Eligible for MR but not found in MR: nonresponse
4 "In MR"                  father is found in the MR file

Here are the category labels for "Is child in BR file?", with more explanation:
0 "No"                     The child's mother is dead or living elsewhere
1 "Yes"                    The child's mother is in the IR file, the child is alive and with mother

The cases in the file are all children age 0-17 in the PR file.

Variables must be clearly labeled for who they refer to and what file they come from. Examples:
ch_hv...: refer to the child, PR data
mo_hv...: refer to the mother, PR data
fa_hv...: refer to the father, PR data
v...: refer to the mother, IR data
mv..: refer to the father, MR data
Other prefixes come from the BR data and may refer to the mother or the child.
The program drops some variables that can be added back in but with clear labeling.

This program depends crucially on hv111-hv114 in the PR file and b16 in the BR file.
It will not run and cannot be modified if those variables are absent.
The program can be modified if there is no MR file.

The age range 0-17 can be reduced to 0-4, say, most easily by not changing the program but
  selecting on ch_hv105 or hw1 in the output file.

*/

******************************************************************************

program define make_workfiles

* Save generic copies of the standard recode files

local lpath=spath

local lfn=sfn_PR
use "`lpath'\\`lfn'FL.DTA", clear 
save PR.dta, replace

local lfn=sfn_IR
use "`lpath'\\`lfn'FL.DTA", clear 
save IR.dta, replace

local lfn=sfn_MR
use "`lpath'\\`lfn'FL.DTA", clear 
save MR.dta, replace

local lfn=sfn_BR
use "`lpath'\\`lfn'FL.DTA", clear 
save BR.dta, replace

end

******************************************************************************

program define prepare_workfiles_for_merges

* Prepare IR file for merge
use IR.dta, clear 
* Reduce to the v variables
keep v*
* Drop women who have no children living with them
drop if v202+v203==0
gen in_IR=1
rename v001 cluster
rename v002 hh
rename v003 mo_line
sort cluster hh mo_line
save IRtemp.dta, replace

* Prepare MR file for merge
use MR.dta, clear 
* reduce to the mv variables
keep mv*
* Drop men who have no children living with them
drop if mv202+mv203==0
gen in_MR=1
rename mv001 cluster
rename mv002 hh
rename mv003 fa_line
sort cluster hh fa_line
save MRtemp.dta, replace

* Prepare BR file for merge
use BR.dta, clear 
* Drop children who are not living with their mother
drop if b9~=0
drop if b16==0 | b16==.
gen in_BR=1
rename v001 cluster
rename v002 hh
rename v003 mo_line
rename b16 ch_line

* Drop all the v variables in the BR file; they refer to the mother and are in the IR file
drop v*
sort cluster hh ch_line
save BRtemp.dta, replace

end

******************************************************************************

program define merges_within_PR

/* 

Prepare PR file for merge
Make 3 copies: ch for children, mo for potential mothers, fa for potential fathers
Possibilities for the mother, similarly for the father:

*/

* Copy of the PR file for children
use PR.dta, clear 
keep if hv105<=17
keep hv*
rename hv001 cluster
rename hv002 hh
rename hvidx ch_line
gen mo_line=hv112 if hv112>0 & hv112<.
replace mo_line=99 if mo_line==.
gen fa_line=hv114 if hv114>0 & hv114<.
replace fa_line=99 if fa_line==.

gen mo_status=.
replace mo_status=0 if hv111==0
replace mo_status=1 if (hv111>0 & hv112==0) | hv112==.
label variable mo_status "Status of mother"
label define mo_status 0 "Dead" 1 "Not in HH" 2 "Not eligible for IR" 3 "Not in IR" 4 "In IR"
label values mo_status mo_status

gen fa_status=.
replace fa_status=0 if hv113==0
replace fa_status=1 if (hv113>0 & hv114==0) | hv114==.
label variable fa_status "Status of father"
label define fa_status 0 "Dead" 1 "Not in HH" 2 "Not eligible for MR" 3 "Not in MR" 4 "In MR"
label values fa_status fa_status

rename hv* ch_hv*
save PRtemp_ch.dta, replace

* Copy of the PR file for potential mothers
use PR.dta, clear
keep hv* 
rename hv001 cluster
rename hv002 hh
rename hvidx mo_line
rename hv* mo_hv*
sort cluster hh mo_line
save PRtemp_mo.dta, replace

* Copy of the PR file for potential fathers
use PR.dta, clear
keep hv* 
rename hv001 cluster
rename hv002 hh
rename hvidx fa_line
rename hv* fa_hv*
sort cluster hh fa_line
save PRtemp_fa.dta, replace

use PRtemp_ch.dta
sort cluster hh mo_line
merge cluster hh mo_line using PRtemp_mo.dta
tab _merge

* drop women in the PR file who are not matched as mothers
drop if _merge==2
drop _merge

replace mo_status=2 if mo_hv117==0
tab mo_status fa_status,m
save PRtemp_ch_mo.dta, replace

* Attach the father's PR data to the child's PR data
use PRtemp_ch_mo.dta, clear
sort cluster hh fa_line
merge cluster hh fa_line using PRtemp_fa.dta
tab _merge

* drop men in the PR file who are not matched as fathers
drop if _merge==2
drop _merge

replace fa_status=2 if fa_hv118==0
tab mo_status fa_status,m
save PRtemp_ch_mo_fa.dta, replace

end

******************************************************************************

program define merge_with_IR

use PRtemp_ch_mo_fa.dta, clear
sort cluster hh mo_line
merge cluster hh mo_line using IRtemp.dta
tab _merge
drop if _merge==2
replace mo_status=3 if mo_status==. & _merge==1
replace mo_status=4 if mo_status==. & _merge==3
drop _merge
tab mo_status fa_status,m
save ch_mo_fa_IR.dta, replace

end

******************************************************************************

program define merge_with_MR

use ch_mo_fa_IR.dta, clear
sort cluster hh fa_line
merge cluster hh fa_line using MRtemp.dta
tab _merge
drop if _merge==2
replace fa_status=3 if fa_status==. & _merge==1
replace fa_status=4 if fa_status==. & _merge==3
drop _merge
tab mo_status fa_status,m
save ch_mo_fa_IR_MR.dta, replace

end

******************************************************************************

program define merge_with_BR

use ch_mo_fa_IR_MR.dta, clear
sort cluster hh ch_line
merge cluster hh ch_line using BRtemp.dta
tab _merge
drop if _merge==2
gen child_in_BR=0
replace child_in_BR=1 if _merge==3
drop _merge
label variable child_in_BR "Is child in BR file?"
label define noyes 0 "No" 1 "Yes"
label values child_in_BR noyes
tab mo_status fa_status if child_in_BR==0,m
tab mo_status fa_status if child_in_BR==1,m

tab mo_status fa_status
tab child_in_BR

save ch_mo_fa_IR_BR.dta, replace

end

******************************************************************************
******************************************************************************
******************************************************************************
******************************************************************************
******************************************************************************
* Execution begins here

* Specify your workspace, change to your own path
*cd "C:\.."

* Specify path to the data, change to your own
scalar spath="C:\Data"

* specify the first six characters of the PR, IR, MR, and BR file names.
* Note that characters 5-6 may not be the same in all four files.
scalar sfn_PR="ZZPR62"
scalar sfn_IR="ZZIR62"
scalar sfn_MR="ZZMR61"
scalar sfn_BR="ZZBR62"

make_workfiles
prepare_workfiles_for_merges
merges_within_PR
merge_with_IR
merge_with_MR
merge_with_BR

*erase all temporary files
erase BR.dta
erase BRtemp.dta
erase IR.dta
erase IRtemp.dta
erase MR.dta
erase MRtemp.dta
erase PR.dta
erase PRtemp_ch.dta
erase PRtemp_ch_mo.dta
erase PRtemp_ch_mo_fa.dta
erase PRtemp_fa.dta
erase PRtemp_mo.dta

