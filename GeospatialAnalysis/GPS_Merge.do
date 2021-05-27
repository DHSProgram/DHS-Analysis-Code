/******************************************************************************************
* Title: GPS_Merge.do
* Created by: Tom Fish <gpsrequests@dhsprogram.com>
* Created: 30 October 2018
* Updated: 06 April 2021
* Purpose: Explan how to merge an IR file with the GC (points) file in STATA
* Notes: The Nigeria data is used for this example, but the code should work for any DHS survey
******************************************************************************************/
clear all
set more off

* Set folders that I am working on
local ptsDir "C:\Data\DHSdata\GPS\"
local dataDir "C:\Data\DHSdata\Recode\"
local working "C:\Working\"

* Make sure we are working in our working directory
cd "`working'"

* Convert the shapefile into a dta file to merge in STATA
shp2dta using "`ptsDir'NGGE71FL.shp", database(ngpts) coordinates(ngcoord) genid(id)

* Open up the table portion of the shapefile
use ngpts

* Rename and sort to allow for the merge to be successful
rename DHSCLUST v001
sort v001

* Resave the table
save ngpts, replace

* Open the IR file
use "`dataDir'NGIR71FL.DTA", clear

* Do a 1 to Many merge/join by joining the GPS points (ngpts.dta) to the IR file
sort v001
merge v001 using ngpts.dta

* Show that the merge was 100% successful and then drop the unneed column
tab _merge
drop _merge id

* Save the merged file
save NG_Merged, replace
