/*****************************************************************************************************
Program: 			urbpov_code.do
Purpose: 			Code urban poverty measure used in AS81
Data inputs: 		HR file 
Author:				Shireen Assaf			
Date last modified: July 28, 2022 by Shireen Assaf 

*****************************************************************************************************/
clear

*enter the list of surveys. Use the HR datafile
global hrdata "CDHR61FL ETHR71FL KEHR72FL NGHR7BFL TZHR7BFL UGHR7BFL"
	
foreach c in $hrdata {
use "`c'.dta", clear

gen filename= lower(substr("`c'",1,6)) 
local cn=substr("`c'",1,2)

*****************
*WASH code (wanter and sanitation) is found in the DHS Code Library: https://github.com/DHSProgram/DHS-Indicators-Stata/tree/master/Chap02_PH

*toilet
do "PH_SANI.do"
recode ph_sani_improve (1 = 1 "Yes") (2/3 = 0 "No") (99=.), gen(saniimprove)
label var saniimprove "Improved sanitation"

*water
do "PH_WATER.do"
recode ph_wtr_improve (1=1 "Yes") (0=0 "No") (99=.), gen(waterimprove)
label var waterimprove "Improved water source"

*****************
* floor material
recode hv213 (11/22 96/99=0 "No") (23/37=1 "Yes"), gen(floor)
label var floor "Household floor made of durable material"

* wall material
recode hv214 (11/28 96/99=0 "No") (31/36=1 "Yes"), gen(wall)
label var wall "Household wall made of durable material"

* roof materal
recode hv215 (11/26 96/99=0 "No") (31/39=1 "Yes"), gen(roof)
label var wall "Household roof made of durable material"

*house made of durable material
gen housedur=0
replace housedur=1 if floor==1 & wall==1 & roof==1
label define housedur 0 "No" 1"Yes"
label values housedur housedur
label var housedur "Household made of durable material"

*****************
* calculating crowding index 
gen hhusual =hv012
replace hhusual=hv013 if hhusual==0
gen crowd=.
replace crowd=trunc(hhusual/hv216) if hv216>0
replace crowd=hhusual if hv216==0
replace crowd=. if hv216>=99
label var crowd "crowding index"

recode crowd (0/2=0 "No") (3/max=1 "Yes"), gen(crowded)
label var crowded "Three or more people living in the same room"
******************

*Generate urban poverty variable

*first generate a variable to identify an urban poor household 
/*define as lacking at least 2 of the following:
-improved water
-improved toilet
-durable household material
-not crowded
*/
gen sumhh= (1-saniimprove) + (1-waterimprove) + (1-housedur) + (crowded)

gen urbanpovhh=1
replace urbanpovhh=3 if hv025==2
replace urbanpovhh=2 if hv025==1 & (sumhh>=2) 
label define urbanpovhh 1"non-urbanpoor" 2"urbanpoor" 3"rural"
label values urbanpovhh urbanpovhh
label var urbanpovhh "Urban poverty based on household characteristics"

*urbanpov cluster
recode urbanpovhh (2=1) (else=0), gen(urbanpoor)
bysort hv001: egen urbanpov_per=mean(urbanpoor)

*urban poverty cluster variable, defined as more than 50% of the cluster with urban poor households. 
gen urbanpov=urbanpov_per > 0.50
replace urbanpov=2 if hv025==2
replace urbanpov=1+urbanpov
label define urbanpov 1"Urban non-poor" 2"Urban poor" 3"Rural"
label values urbanpov urbanpov
label var urbanpov "Urban poverty cluster"

*for merging with IR, KR, or BR files
gen v001 =hv001
gen v002 =hv002

*optional, keep only variables you need
*keep v001 v002 hv000-hv027 hv012 hv013 ph* saniimprove waterimprove floor wall roof housedur crowd crowded sumhh urbanpo* filename

save "`cn'HRcoded.dta", replace
  }
  
  
* The next step is to merge the HRcoded file above with a KR or PR file
* This is performed by a many to one merge with a coded KR file as follows:

*use `cn'KRcoded.dta, clear
*merge m:1 v001 v002 using "`cn'HRcoded.dta"
*save "`cn'HRKRmerged.dta", replace


* You can check the merge_loop code in the Intro_DHSdata_Analysis\4_Using_Multiple_Files section of this repository for merge code that loops through several countries. 
  