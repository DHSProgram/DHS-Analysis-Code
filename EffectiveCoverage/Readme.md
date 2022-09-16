
# Readme Effective Coverage

These files allow users to recreate the effective coverage cascades created for [Methodological Report 31 "Measurement Approaches for Effective Coverage Estimation"](https://www.dhsprogram.com/publications/publication-mr31-methodological-reports.cfm?csSearch=554290_1) 
and [Analytical Study 84 "Equity in Effective Coverage of Antenatal and Sick Child Care"](https://www.dhsprogram.com/publications/publication-as84-analytical-studies.cfm?csSearch=574585_1).

## There are five do files included here:

### 1. DHScodevars.do
This do file creates the coverage variables as well as the DHS quality variables used for calculating a DHS-only effective coverage measure. Coded data are saved in a new dataset ith suffix "coded.dta"

### 2. Readiness.do
This do file creates the service readiness variables using SPA facility inventory files and saves them in a new dataset with suffix “ready.dta”

### 3. SPAcodevars.do
This do file creates the process quality variables using SPA ANC and sick child observation files and saves them in a new dataset with suffix “coded.dta”.

************************************************************************************
***IMPORTANT***

In the two do files above, all variables created as a component of the effective coverage cascade are saved with the following naming convention:

service area code_effective coverage component code_approach code

#### Service area codes		
anc	= antenatal care <br/>		
sc	= sick child care		
				
#### Effective coverage component codes
c	= coverage  <br/>
r	= service readiness  <br/>
i	= intervention coverage  <br/>
q	= process quality

#### Approach codes
1	    = Used in approach 1  <br/>
2	    = Used in approach 2  <br/>
3	    = Used in approach 3  <br/>
23	= Used in approaches 2 and 3  <br/>
123 = Used in all approaches  <br/>

For example, the *anc_r_23* variable is the ANC readiness measure used in approaches 2 and 3 in MR31.
************************************************************************************


### 4. EC_coefficient_nlcom.do
This do file puts all the components of the effective coverage cascade together to calculate the effective coverage estimates 
along with confidence intervals using the delta method as described in MR31 and Sauer et al (2020).  

For this do file to run correctly the modified datasets created by the previous three do files should be saved in separate folders for each country, named using the two letter country code. For example, all Haiti datasets should be saved in a folder “HT”.

The output of this do file is one dataset per country ending in “_results_modified.dta” with the following columns:
|Name|Description|
|---|---|
|Country| Two letter country code| 
|Outcome |ANC or SC|
|Version |Equivalent to “approach”. Should be 1, 2, or 3|
|Model |Within each outcome/version combination, this variable will indicate that the estimates are either of one of the the effective coverage components (indicated by “source”) or a step in the effective coverage cascade (indicated by 1x2, 1x2x3, etc). For example, within ANC version 2, source 1 is the crude coverage estimate, source 2 is the service readiness estimate, source 3 is the intervention coverage estimate, source 4 is the process quality estimate. 1x2 is the input-adjusted coverage estimate, 1x2x3 is the intervention coverage estimate, and 1x2x3x4 is the quality-adjusted coverage estimate.|
|P |Estimate|
|L_adj |lower bound of the adjusted asymmetric 95% confidence interval|
|U_adj  |upper bound of the adjusted asymmetric 95% confidence interval|
|width_adj  |width of the adjusted asymmetric 95% confidence interval|
|b  |logit of P|
|se_of_b  |standard error of b|
|L  |lower bound of the symmetric 95% confidence interval|
|U |upper bound of the symmetric 95% confidence interval|
|Width | width of the symmetric 95% confidence interval|
|Delta | symmetric minus asymmetric 95% confidence interval width|
|se_of_P | standard error of P|

### 5. EC_equity_calcs.do
This do file is a slight modification of the previous do file, and runs on the same source datasets, but includes the sociodemographic variables to conduct the equity analysis as described in AS84.

For this do file to run correctly the modified datasets created by the previous three do files should be saved in separate folders for each country, named using the two letter country code. For example, all Haiti datasets should be saved in a folder “HT”.

The output of this do file is one dataset per country ending in “_results_modified.dta” with similar columns as described in the previous do file. Of particular interest are:
|Name|Description|
|---|---|
|Country| Two letter country code| 
|ANC_SC |ANC or SC|
|region | National or Regional, by region number|
|factype |facility type|
|res_wealth |All if overall population, v025=1 indicates urban population, v025=2 indicates rural population, v190=1 indicates population in wealth quintile 1, and so on.|
|adjusted | indicates if national estimate is adjusted by region
|model |within each outcome/version combination, this variable will indicate that the estimates are either of one of the the effective coverage components (indicated by “source”) or a step in the effective coverage cascade (indicated by 1x2, 1x2x3, etc). For example, within ANC version 2, source 1 is the crude coverage estimate, source 2 is the service readiness estimate, source 3 is the intervention coverage estimate, source 4 is the process quality estimate. 1x2 is the input-adjusted coverage estimate, 1x2x3 is the intervention coverage estimate, and 1x2x3x4 is the quality-adjusted coverage estimate.|
|type |string variable indicating national level estimate or regional estimate|
|P |estimate|
|L_adj|lower bound of the adjusted asymmetric 95% confidence interval|
|U_adj|upper bound of the adjusted asymmetric 95% confidence interval|
|width|width of the adjusted asymmetric 95% confidence interval|
|logitP |logit of the estimate|
|se_of_b |standard error of b|
|L |lower bound of the symmetric 95% confidence interval|
|U |upper bound of the symmetric 95% confidence interval|
|se_of_P |standard error of P|




