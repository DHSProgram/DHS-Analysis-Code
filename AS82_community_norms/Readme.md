# Readme AS82: Collective Norms Study

These files allow users to recreate the Collective Fertility and Gender Norms analysis from [DHS Analytical Study 82](https://www.dhsprogram.com/publications/publication-as82-analytical-studies.cfm?csSearch=574722_1) 

There are four do files that will recreate the analysis. These do files should be run in the order presented.

## The do files are:

### 1. codevars.do
   This do file uses the IR and MR files to code all necessary variables for the analysis, both individual and community-level. 
   This do file calls the multilev.do file, which is described below. This do file also contains code to estimate the SWPER indicies. 

### 2. multilev.do
   This do file applies the code from MR32 to develop multilevel weights for the multilevel models for each country.

### 3. MLM.do
   This do file includes all the models shown in AS82 - the null model, models with only the individual-level and then only 
   the community-level variables, and then the full models with both the individual and community-level variables. It also 
   includes the multilevel models by age group.

### 4. RegionalMLM.do
   This do file includes the multilevel models by region.
