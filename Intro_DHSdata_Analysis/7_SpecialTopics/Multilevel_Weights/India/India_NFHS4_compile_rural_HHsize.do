/*******************************************************************************************************************************
Program: 	India_NFHS4_compile_rural_HHsize.do
Purpose: 	Compile the average size in number of households of India's villages 
Data inputs:	Separate excel files by districts from the webpage pf the Census of India https://censusindia.gov.in/pca/cdb_pca_census/cd_block.html. 
		The user needs to download all the excel files and use this Stata code to compile the needed data for rural clusters. 
Author: 	Tom Pullum
Date last modified:  January 25, 2022 by Mahmoud Elkasabi
*******************************************************************************************************************************/
* do e:\DHS\India\India_Census_2011\State_HH_files_do_2June2021.txt

set more off
cd "e:\DHS\India\India_Census_2011"

scalar zero="0"

***********************************************************************

program define collapse_segment

keep if regexm(TRU,"Rural")==1
gen clusters=1
quietly collapse (sum) clusters No_HH TOT_P TOT_M TOT_F, by(State District)
quietly gen avg_size = No_HH / clusters
append using appended_file.dta
save appended_file.dta, replace

end


***********************************************************************

set obs 1
gen dummy=1
save appended_file.dta, replace

local li=101
while `li'<=3520 {
scalar si=`li'
  if `li'<1000 {
    quietly capture : import excel using "PCA CDB-0`li'-F-Census.xlsx", firstrow clear
    if _rc==0 {
    scalar list si
    quietly import excel using "PCA CDB-0`li'-F-Census.xlsx", firstrow clear
    collapse_segment
    }
  }

  if `li'>=1000 {
    quietly capture : import excel using "PCA CDB-`li'-F-Census.xlsx", firstrow clear
    if _rc==0 {
    scalar list si
    quietly import excel using "PCA CDB-`li'-F-Census.xlsx", firstrow clear
    collapse_segment
    }
  }

local li=`li'+1
}

drop if dummy==1
drop dummy
sort State District Level
save India_State_District_collapsed.dta, replace

