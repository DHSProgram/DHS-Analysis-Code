
# Purpose: approximation of level-weight

The purpose of this section is to support users regarding the approximation of level-weight of DHS surveys. 
The approximation follows the methods explained in the [DHS Methodological Report #27](https://www.dhsprogram.com/publications/publication-mr27-methodological-reports.cfm?csSearch=423113_1)

In addition to the provided Stata code, the user will need more information from the final report of the survey, especially from tables in Appendix A of the report.
The Stata code illustarte the approximation based on the household weight, hv005. 

The same code can be used to approximate level-weights based on other weights, such as v005 and mv005.

## Example of applying multi-level weights for analysis
An example of this procedure is available in the code provided for [the DHS Analytical Study 82](https://www.dhsprogram.com/publications/publication-as82-analytical-studies.cfm?csSearch=574722_1).
The Stata code used for estimating the level-weights for three DHS surveys Nigeria 2018, Nepal 2016, and Zambia 2018 is found in the AS82_community_norms folder of the [DHS-Analysis-Code Repository](https://github.com/DHSProgram/DHS-Analysis-Code).
Please check the readme file for this study for more details. 
