# Readme: Survival Analysis Example

These .do files are adapted from files used in the Initiation of Breastfeeding Working Paper from [DHS Working Paper 163](https://dhsprogram.com/publications/publication-wp163-working-papers.cfm?cssearch=940029_1) to proivde an example of a survival analysis. A revised analysis based on this Working Paper was later published in Global Health Science and Practice (https://doi.org/10.9745/GHSP-D-20-00361).

There are two .do files; the first recodes variables and the second file includes code for the analysis.

Before running the code, you must have downloaded the data of interest and changed your paths. This example produces results from several DHS surveys and can be adapated to one or more surveys of interest. 

## The do files are:

### 1. codevars.do
   This .do file uses the KR files to code all necessary outcome and exposure variables for the analysis. 
   This .do file calls the a Survey_strata.do file (which you can find in section 2) to create a standard variable name for country-specifc survey strata variables. 

### 2. analysis.do
    The second file produces descriptive statistics to support survival analysis, then prepares data for survival and examines several survival models and goodness of fit statistics. 

 