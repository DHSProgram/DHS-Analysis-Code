/*****************************************************************************************************
Program: 			mergeIR_toSR.do
Purpose: 			This is an example of how to produce an IRSR file, using separate IR and SR files. 
Author:				Tom Pullum
Date last modified: May 26, 2023 by Tom Pullum
*****************************************************************************************************/

* This is an example of how to produce an IRSR file, using separate IR and SR files. 

* This is useful for calculating adult and maternal mortality rates with a program 
* designed for surveys in which the sibling histories are in the IR file.

* Other modifications may be needed.
* Illustrated with preliminary IR and SR files from Cote d'Ivoire 2022 
* The new file is saved with "IRSR" in the filename

* path to your workding directory where your data files should also be stored. 
cd "C:\.."

use CIIR80FL.dta, clear
sort v001 v002 v003
save temp.dta, replace

use CISR80FL.dta, clear

keep v001 v002 v003  mm*
rename mm* mm*_
rename mmidx_ index
quietly summarize index
local lmax_index=r(max)
reshape wide mm*_ , i(v001 v002 v003) j(index)
merge v001 v002 v003 using temp.dta

tab _merge
drop _merge
* _merge=2 for women who did not report any siblings; they must be kept in the data.
* mmidx_* is still in the data.

save CIIRSR80FL.dta, replace