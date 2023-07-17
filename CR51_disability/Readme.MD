# Readme CR51: Disability Profiles

The disability.do file can be used to construct the disability indicators used in [DHS Comparative Report #51: Profile and Correlates of Persons Living with Disability](https://www.dhsprogram.com/publications/publication-cr51-comparative-reports.cfm?csSearch=1027381_1). 
The file also constructs several background variables available in the PR file and generates identifying variables needed for merging. 

The resulting PR coded file for each survey (`cn'PRcoded.dta where cn is the country code) can be merged with the IR or MR file to further describe disability status by women or men's characteristics that are not found in the PR file (for example religion, ethnicity, or experience of domestic violence). The domestic violence indicators can be found in [the DHS Program Code Share Library - Stata repository](https://github.com/DHSProgram/DHS-Indicators-Stata) in chapter 17.

The example code below shows how to merge the resulting PR coded file after running the disability.do file with the corresponding IR file for the survey.

```stata
* path to DHS data, change to your own
global Datafilepath "C:\DHSdata"

* IR files for the surveys used in the analysis. These surveys must be downloaded and saved in your Datafilepath
global irdata "HTIR71FL MLIR7AFL NGIR7BFL PKIR71FL RWIR81FL ZAIR71FL SNIR8BFL TLIR71FL UGIR7BFL"

foreach c in $irdata {
use "$Datafilepath/`c'.dta", clear

*to get the country code (ex: HT, ML, etc.)
local cn=substr("`c'",1,2)

*perform the merge.
merge 1:1 v001 v002 v003 using "$Codedfilepath\\`cn'PRcoded.dta"
keep if _merge==3

save "$Codedfilepath//`cn'PRIRcoded.dta", replace

}


```