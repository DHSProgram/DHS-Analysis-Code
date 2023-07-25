
# Purpose: Special indicators

The section will contain code for construction of special indicators and measures that may not be found the DHS Code Share Library or other repositories.

In no particular order, the following code is available:

### HouseholdStructure

Constructs household structure variable using the PR file. Stata and R code available. 

### SexRatio.do

Calculates the sex retio which is defined here as males per 100 females and females per 100 males and saves the results as scalars.
The program also contains code on how to calculate Sex Ratios by district for each state using the India 2019-2021 survey. 
This code could be adapted for other covariates and surveys. 

### PregOutcomes.do

The program will reshape the IR file to produce a variable "type" which represents the pregnancy outcomes (live births, stillbirths, miscarriages, and abortions) among pregnancies in the 5 years preceding the survey.
Please read the notes provided throughout the file for more details and instructions. 