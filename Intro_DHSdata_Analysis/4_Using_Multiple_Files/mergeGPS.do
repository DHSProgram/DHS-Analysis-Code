/*****************************************************************************************************
Program: 			mergeGPS.do
Purpose: 			Explain how to merge an IR file with the GC (points) file in STATA 
Author:				Tom Fish, Rose Donohue, and Shireen Assaf
Date last modified: Aug 1, 2023 by Shireen Assaf 
Note:				The Nigeria 2018 survey is used for this example.
					
					There are two sections to this code:  
					1. Merging the country GPS locations for each cluster to an IR file (use same logic for other file types)
					2. Merging the survey boundaries data at the region level, this code will also produce a map.
					
					For both sections you will need a shapefile. 
					The cluster GPS locations can be downloaded along with the datasets from the DHS Program website. 
					These files have 'GE' in the name, for example NGGE7BFL
					
					To download the survey boundary data for any survey go to: https://spatialdata.dhsprogram.com/boundaries/
					These shape files will have the name sdr_subnational_boundaries
					
*****************************************************************************************************/

clear all

* Load required program
ssc install shp2dta

**** Section one: Merging GPS locations at the cluster level ****

* Convert the shapefile into a dta file to merge in STATA
spshape2dta "NGGE7BFL", replace // We don't need the file extension for this command

* The commnad below will also work 
* shp2dta using "NGGE7BFL.shp", database(NGGE7BFL) coordinates(ngcoord) genid(id)

* A Stata data file will be created and saving in your working directory. Open the dataset to prepare for merging. 
use NGGE7BFL.dta, clear

* Rename and sort to allow for the merge to be successful
rename DHSCLUST v001
sort v001

* Resave the file
save NGGE7BFL.dta, replace

* Open the IR file
use "NGIR7BFL.DTA", clear

* Do a 1 to many merge/join by joining the GPS points (NGGE7BFL.dta) to the IR file
sort v001
merge v001 using NGGE7BFL.dta

* Show that the merge was successful
tab _merge
drop _merge 

* Save the merged file
save NG7B_merged.dta, replace

*****************************************************************************************************

**** Section two: Merging GPS locations at the region level for survey boundaries ****

* Convert the shapefile into a dta file to merge in STATA
spshape2dta "sdr_subnational_boundaries", replace 

* Open the Stata data file
use "sdr_subnational_boundaries.dta", clear

* Keep the variables you need
keep _ID _CX _CY REGCODE REGNAME

*rename variable you will merge by to match IR file
rename REGCODE v024
sort v024

save "sdr_subnational_boundaries.dta", replace


* Open the IR file
use "NGIR7BFL.DTA", clear

* We need to collapse the data to the region level before merging.
* Choose an indicator of interest that you would want to use in the merged data.

* For example, modern contraceptive use.

* Recode the target indicator
recode v313 (0/2 = 0 No) (3 = 1 Yes), gen(mcp)
label var mcp "currently using a modern contraceptive method among currently married women"
replace mcp = . if v502 != 1

*Generate weights
gen wt = v005/1000000

tab mcp [iw=wt]

tab v024 mcp  [iw=wt], row

* now you can collapse the data to the indicator of interest at the region level

collapse (mean) mcp  [iw = wt], by (v024) // We aren't calculating CIs so we don't use svyset 

*changing proportions to percentages
replace mcp = mcp*100

* save collapsed file
save NGIR7BFLcollapsed.dta, replace

* open the shapefile created earlier
use "sdr_subnational_boundaries.dta", clear

* perform the merge with the collapsed data
merge 1:1 v024 using "NGIR7BFLcollapsed.dta"

* Now this data can be used to create a map of modern contraceptive use or any other indicator of interest for each region

* creating a label for region
gen labeltxt = "{bf:" + proper(REGNAME) + "}"

*formate the indicator to have one decimal place
format mcp %9.1f

* Create choropleth map
grmap, activate
spset, modify shpfile("sdr_subnational_boundaries_shp.dta") // Sets the shapefile used by grmap

grmap mcp, ///
	clmethod(eqint) ///
	clnumber(5) ///
	title("{bf:Percent of married women currently}" "{bf:using a modern contraceptive method}", size(3.5)) ///
	subtitle("Nigeria 2018 DHS", size(3.5)) ///
	fcolor(YlGnBu) ///
	legend(size(small) position(5)) ///
	legtitle("{bf:Percentage}") ///
	legstyle(2) ///
	legorder(hilo) ///
	label(xcoord(_CX) ycoord(_CY) label(labeltxt) length (75) size(vsmall))

* please check the documentation for grmap for how to manipulate the options. 
* help grmap

*****************************************************************************************************
