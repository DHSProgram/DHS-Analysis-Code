Readme MR31

These files allow users to recreate the effective coverage cascades created for Methodological Report 31 (link).
There are three do files included here. The components of the effective coverage cascade which were created from DHS datasets are not included, 
as there is ample documentation for re-creating those variables elsewhere in GitHub. ANC variables can be found here 
(https://github.com/DHSProgram/DHS-Indicators-Stata/blob/master/Chap09_RH/RH_ANC.do) and sick child variables 
can be found here (https://github.com/DHSProgram/DHS-Indicators-Stata/tree/master/Chap10_CH). 
The components of the effective coverage cascade which were create from SPA datasets are included.

The do files are:

Readiness.do
This do file creates the service readiness variables using SPA facility inventory files and saves them in a new dataset with suffix “ready.dta”

SPAcodevars.do
This do file creates the process quality variables using SPA ANC and sick child observation files and saves them in a new dataset with suffix “coded.dta”.

*************
**IMPORTANT**
*************
In the two do files above, all variables created as a component of the effective coverage cascade are saved with the following naming convention:

‘service area code’_‘effective coverage component code’_‘approach code’

------------------------------------------------------------------------------------------------------------
Service area 			Effective coverage component		Approach
------------------------------------------------------------------------------------------------------------
code	definition		code	definition			code	definition
------------------------------------------------------------------------------------------------------------
anc	antenatal care		c	coverage			1	Used in approach 1
sc	sick child care		r	service readiness		2	Used in approach 2
				i	intervention coverage		3	Used in approach 3
				q	process quality			23	Used in approaches 2 and 3
									123 	Used in all approaches



EC coefficient_nlcom_github.do
This do file puts all the components of the effective coverage cascade together to calculate the effective coverage estimates 
along with confidence intervals using the delta method as described in MR31 and Sauer et al (2020).

For this do file to run correctly the modified datasets created should be saved in separate folders for each country, 
named using the two letter country code. For example, all Haiti datasets should be saved in a folder “HT”.

The output of this do file is one dataset per country ending in “_results_modified.dta” with the following columns:
•	Country			Two letter country code
•	Outcome			ANC or SC
•	Version			Equivalent to “approach”. 1, 2, or 3
•	Model			within each outcome/version combination, this variable will indicate that the estimates 
				are of the components (indicated by “source”) or a step in the effective coverage cascade (indicated by 1x2, 1x2x3, etc). 
				For example, within ANC version 2, source 1 is the crude coverage estimate, source 2 is the service readiness 
				estimate, source 3 is the intervention coverage estimate, source 4 is the process quality estimate. 1x2 is the 
				input-adjusted coverage estimate, 1x2x3 is the intervention coverage estimate, and 1x2x3x4 is the quality-adjusted 
				coverage estimate.
•	P			estimate
•	L_adj			lower bound of the adjusted asymmetric 95% confidence interval
•	U_adj			upper bound of the adjusted asymmetric 95% confidence interval
•	width_adj		width of the adjusted asymmetric 95% confidence interval
•	b			logit of P
•	se_of_b			standard error of b
•	L			lower bound of the symmetric 95% confidence interval
•	U			upper bound of the symmetric 95% confidence interval
•	Width 			width of the symmetric 95% confidence interval
•	Delta			symmetric minus asymmetric 95% confidence interval width
•	se_of_P			standard error of P



