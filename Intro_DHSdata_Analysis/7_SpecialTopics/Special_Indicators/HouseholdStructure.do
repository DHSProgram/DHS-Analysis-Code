/*******************************************************************************************************************************
Program: 				HouseholdStucture.do
Purpose: 				Construct household structure variable
Author: 				Tom Pullum
Date last modified:		Jan 17, 2023 by Tom Pullum
*******************************************************************************************************************************/

* using Philippines 2022 DHS survey as an example
use "PHPR81FL.DTA", clear 

* Criteria for household typology
* household head is male (hv101=1, hv104=1)
* household head is female (hv101=1, hv104=2)
* no spouse present (no one in hh with hv101=2
* at least one unmarried child present (hv101=3,hv105<=17, hv115=0)

gen hhhead_male  =0
gen hhhead_female=0
gen spouse=0
gen child=0

replace hhhead_male  =1 if hv101==1 & hv104==1
replace hhhead_female=1 if hv101==1 & hv104==2
replace spouse=1        if hv101==2
replace child=1         if hv101==3 & hv105<=17 & hv115==0

egen nhhhead_male  =total(hhhead_male),   by(hv024 hv001 hv002) 
egen nhhhead_female=total(hhhead_female), by(hv024 hv001 hv002) 
egen nspouse       =total(spouse),        by(hv024 hv001 hv002) 
egen nchild        =total(child),         by(hv024 hv001 hv002) 

gen hhtype=.
replace hhtype=1 if nhhhead_male==1   & nspouse>=1 & nchild>0
replace hhtype=2 if nhhhead_male==1   & nspouse>=1 & nchild==0
replace hhtype=3 if nhhhead_male==1   & nspouse==0 & nchild>0
replace hhtype=4 if nhhhead_male==1   & nspouse==0 & nchild==0
replace hhtype=5 if nhhhead_female==1 & nspouse>=1 & nchild>0
replace hhtype=6 if nhhhead_female==1 & nspouse>=1 & nchild==0
replace hhtype=7 if nhhhead_female==1 & nspouse==0 & nchild>0
replace hhtype=8 if nhhhead_female==1 & nspouse==0 & nchild==0
replace hhtype=9 if hhtype==.

label define hhtype 1 "Male head with spouse and children" 2 "Male head with spouse, no children" 3 "Male head, no spouse, and children" 4 "Male head, no spouse, no children" 5 "Female head with spouse and children" 6 "Female head with spouse, no children" 7 "Female head, no spouse, and children" 8 "Female head, no spouse, no children" 9 "Other"
label values hhtype hhtype

tab hhtype if hv101==1 [iweight=hv005/1000000]
