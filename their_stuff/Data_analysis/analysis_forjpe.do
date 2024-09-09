cap log close
clear
set more off
log using analysis_forjpe.log, replace

/* This .do file generates the results in Abramitzky, Boustan, Eriksson ("A Nation of Immigrants").*/

/* This .dta file is based on matched Census data from 1900-1920 for immigrants from 16 sending countries and a comparison sample of natives. An explanation for 
how this dataset was created is presented in build_panel_forjpe.do*/
use panel_all_forjpe.dta

/* Original dataset contains all migrants who arrived before 1900. For the analysis, we focus our attention on migrants who arrived between 1880-1900. Here, we 
keep immigrants who arrived after 1880 and the native born. Whenever possible, we use IPUMS variable names, so .bpl. = birthplace. Observations with 
birthplace<100 were born in US.*/
keep if (yrimmig>=1880 | bpl<100)

/* Create sample weights for the panel sample. The panel oversamples small countries so that we will have a large enough sample of observations from each 
sending country. These weights are based on the distribution of the population between native and foreign born (and within country of origin for the 
foreign born) from 1920 IPUMS sample. The actual numbers for each weight depend on (a) the number of observations of a particular type (say, native born men) in 
our panel sample and (b) the number of observations of the same type in the IPUMS sample of 1920. So, given these two numbers, we need each observation for 
native-born men to count as 9.86 observations, and each observation for men born in Denmark (bpl = 400) to count as only 6% of an observation, and so on.*/ 
gen weight2=9.86 if bpl==1
replace weight2=0.058 if bpl==400
replace weight2=0.064 if bpl==401
replace weight2=0.326 if bpl==404
replace weight2=0.596 if bpl==405
replace weight2=0.442 if bpl==410
replace weight2=0.027 if bpl==411
replace weight2=0.031 if bpl==412
replace weight2=0.454 if bpl==414
replace weight2=0.044 if bpl==420
replace weight2=0.105 if bpl==421
replace weight2=0.022 if bpl==426
replace weight2=0.408 if bpl==434
replace weight2=0.070 if bpl==436
replace weight2=0.484 if bpl==450
replace weight2=0.338 if bpl==453
replace weight2=0.501 if bpl==465

/* Append in IPUMS data*/
/* Create an indicator to differentiate between the IPUMS and the panel samples*/
gen Panel=1
append using ipums_forjpe.dta
replace Panel=0 if Panel==.
/* Each of the IPUMS samples are representative of the population -- so the weight for IPUMS observations is set to 1*/
replace weight2=1 if Panel==0

/* Convert dependent variables to 2010 dollars. Note that .occscore_all. is originally denominated in 100s of 1950 dollars, as it is based on the IPUMS OCCSCORE 
variable, while the .income. variable is originally in 1901 dollars. We use CPI adjustments from the website measuringworth.net to translate 1901 and 1950 dollars 
into 2010 dollars. We also multiply .occscore_all. by 100 so that both dependent variables are measured in single dollars, rather than in 100s of dollars.*/
replace occscore_all=occscore_all*900
replace income=income*26.8
replace lnincome=ln(income)
replace lnoccscore=ln(occscore_all)
/* Dummy for foreign born*/
replace fb=(bpl>100) if fb==.
/* Interact the indicators for 'years in the US' categories with a dummy for being in the panel sample -- for the specifications that pool IPUMS and panel to 
estimate equation (1) for repeated cross-section and panel together. Note that the categorical variables Iyrsusa2_1, etc. are defined in the two .do files 
.build_panel_forjpe.do. and .ipums_forjpe.do.*/
gen PIyrsusa2_1=Panel*Iyrsusa2_1
gen PIyrsusa2_2=Panel*Iyrsusa2_2
gen PIyrsusa2_3=Panel*Iyrsusa2_3
gen PIyrsusa2_4=Panel*Iyrsusa2_4
gen PIyrsusa2_5=Panel*Iyrsusa2_5
/* Do the same for the indicator for being in the after 1890 arrival cohort. Note that the indicator variable C1 is =1 for any immigrant who arrives after 1890 
and =0 for immigrants who arrive in 1890 or before and for the native born. This variable is also defined in the two .build. .do files.*/
gen PC1=Panel*C1
/* Generate consistent Census year fixed effects in the panel and IPUMS samples*/
drop Y*
xi, pref(Y) i.year

/* Appendix Table 1: This table reports mean occupation-based earnings for natives and foreign born and then compares the occupation-based earnings for men in 
the representative population sample (IPUMS) and the panel sample in 1920*/
/*Mean earnings*/
tab fb if year==1920 & Panel==1 [aw=weight2], summ(occscore_all)
/*Regressions comparing representative sample to panel sample for natives and then for foreign born*/
reg occscore_all Panel if fb==0 & year==1920
reg occscore_all Panel if fb==1 & year==1920 [pw=weight2]
/* Add country-of-origin FE*/
reg occscore_all Panel T* if fb==1 & year==1920 [pw=weight2]
/* Use ln(occscore) as DV*/
reg lnoccscore Panel if fb==1 & year==1920 [pw=weight2]
reg lnoccscore Panel T* if fb==1 & year==1920 [pw=weight2]
/*Separately compare panel sample to IPUMS sample by country of origin - etc.*/
foreach num of numlist 400 401 404 405 410 411 412 414 420 421 426 434 436 450 453 465 {
	reg occscore_all Panel if bpl==`num' & year==1920
}

/* Currently, the indicators Iyrs and C1 are non-zero for the cross section and the panel sample. So, the coefficients on P*Iyrs and P*C1 represent the 
incremental difference between the cross section and panel samples. Instead, for ease of interpretation, we want the interactions P*Iyrs and P*C1 to represent 
the ACTUAL value of, say, being in the US for 0-5 years for immigrants in the panel sample. So, we set the indicators Iyrs and C1 =0 for observations in the 
panel sample. We also set the variable "Panel" =0 for immigrants in the panel sample so that it reflects earnings for native born in the panel sample only.*/
foreach var of varlist Iyrs* {
replace `var'=0 if Panel==1
}
/* Create a new indicator =1 for ALL observations in the panel sample (both native and foreign born)*/
gen panel_flag=Panel
replace Panel=0 if fb==1

/* Table 3: Baseline results*/
/* Note that Figure 2 reports the coefficients on the Iyrs indicators for the cross section and repeated cross section and on (Iyrs + Panel) for the panel 
sample*/
/* Each regression contains a quadratic in age, indicators for years spent in the US for the cross-section sample (I*), indicators for years spent in the US for 
the panel sample along with a dummy for being native born and in the panel sample (all included in P*), country-of-origin fixed effects (T*) and Census year fixed 
effects (Y*). Regressions are weighted by .weight2. to reflect the population distribution in 1920. The pooled cross section regression only contains observations 
from the IPUMS sample. Country-of-origin fixed effects are defined in the two .build. .do files*/
/* Cross section only*/
reg occscore_all age age2 age3 age4 I* P* T* Y* [pw=weight2] if panel_flag==0
/* The RCS and panel regression add a dummy for the post-1890 arrival cohort (C1) and an interaction for this arrival cohort dummy and being in the panel sample 
(included in P*)*/
/* Repeated cross-section and panel (pooled)*/
reg occscore_all age age2 age3 age4 I* P* C1 T* Y* [pw=weight2]
/* Test if difference between immigrants-natives is different across two samples*/
test Iyrsusa2_1==(PIyrsusa2_1-Panel)
test Iyrsusa2_2==(PIyrsusa2_2-Panel)
test Iyrsusa2_3==(PIyrsusa2_3-Panel)
test Iyrsusa2_4==(PIyrsusa2_4-Panel)
test Iyrsusa2_5==(PIyrsusa2_5-Panel)

/* Table 6: Robustness*/
/* No country FE = drop T**/
reg occscore_all age age2 age3 age4 I* P* Y* [pw=weight2] if panel_flag==0
reg occscore_all age age2 age3 age4 I* P* C1 Y* [pw=weight2]
/* Drop immigrants who arrive as children*/
reg occscore_all age age2 age3 age4 I* P* Y* T* [pw=weight2] if (fb==0 | (age_immig>9 & age_immig<40)) & panel_flag==0
reg occscore_all age age2 age3 age4 I* P* Y* C1 T* [pw=weight2] if (fb==0 | (age_immig>9 & age_immig<40))
reg occscore_all age age2 age3 age4 I* P* Y* C1 T* [pw=weight2] if (fb==0 | (age_immig>11 & age_immig<40))
/* Finer arrival cohorts . Define four arrival cohorts for 1880-85; 1886-1890, etc. Interact each with being in the panel sample.*/
gen Coha=(yrimmig>=1886 & yrimmig<=1890)
gen Cohb=(yrimmig>=1891 & yrimmig<=1895)
gen Cohc=(yrimmig>=1896 & yrimmig<=1900)
gen Coha_Panel=Coha*panel_flag
gen Cohb_Panel=Cohb*panel_flag
gen Cohc_Panel=Cohc*panel_flag
replace Coha=0 if panel_flag==1
replace Cohb=0 if panel_flag==1
replace Cohc=0 if panel_flag==1
reg occscore_all age age2 age3 age4 I* PI* Y* T* Coha-Cohc Coha_Panel-Cohc_Panel Panel [pw=weight2]
/* Use ln(occscore) as dependent variable*/
replace lnoccscore=ln(occscore_all) if lnoccscore==.
reg lnoccscore age age2 age3 age4 I* P* Y* T* [pw=weight2] if panel_flag==0
reg lnoccscore age age2 age3 age4 I* P* Y* C1 T* [pw=weight2]

/* Table 5: State fixed effects*/
xi, pref(S) i.stateicp
reg occscore_all age age2 age3 age4 I* P*  T* Y* S* [pw=weight2] if stateicp!=. & panel_flag==0
reg occscore_all age age2 age3 age4 I* P* C1 T* Y* S* [pw=weight2] if stateicp!=.
/* Urban only. Note that our urban definition is based on the share of the population in the county of residence that lives in an urbanized area, with urbanized 
defined as towns of at least 2,500 residents. See the two .build. .do files for more details.*/
*gen urban=(shurb1_1900>=.4 & shurb1_1900!=.)
*replace urban=. if shurb1_1900==.
reg occscore_all age age2 age3 age4 I* P* T* Y* [pw=weight2] if panel_flag==0 & urban==1
reg occscore_all age age2 age3 age4 I* P* C1 T* Y* [pw=weight2] if urban==1

/* Table 4: Use Cost of Living income as dependent variable instead*/
reg income age age2 age3 age4 I* P* T* Y* [pw=weight2] if panel_flag==0
reg income age age2 age3 age4 I* P* C1 T* Y* [pw=weight2]
/* Calculate 1950 occupation-based earnings that are as close as possible to the 1901 Cost of Living survey. That is, calculate *mean* (rather than median) 
earnings for *urban workers* only. Replace farmer earnings with 1900 Census of Agriculture*/
sort occ1950_all
drop _merge
merge occ1950_all using urb_rural_occscores.dta
drop _merge
/* Adjust for CPI to 2010 dollars*/
gen occscore_adj=inctot_mean*9.06
/* Replace DV = 1900 Census of Ag. based estimate of earnings for owner-occupier farmers*/
replace occscore_adj=income if occ1950_all>=100 & occ1950_all<=120
reg occscore_adj age age2 age3 age4 I* P* T* Y* [pw=weight2] if panel_flag==0
reg occscore_adj age age2 age3 age4 I* P* C1 T* Y* [pw=weight2]


/* For online appendix*/
/* Hatton specification*/
reg occscore_all exp age35 age35exp I* P* T* Y* [pw=weight2] if panel_flag==0
reg occscore_all exp age35 age35exp I* P* C1 T* Y* [pw=weight2]
/* Separately estimate RCS and panel*/
reg occscore_all age age2 age3 age4 I* P* C1 T* Y* [pw=weight2] if panel_flag==0
reg occscore_all age age2 age3 age4  PI* C1 T* Y* [pw=weight2] if panel_flag==1
/* Drop countries that have mismatch between panel sample and population - Mentioned in Appendix in paper*/
reg occscore_all age age2 age3 age4 I* P* Y* T* C1 [pw=weight2] if (bpl!=420 | bpl!=414 | bpl!=421 | bpl!=404)


/*Country-by-country results -- Figures 3-5*/

/* Create an indicator for Italy, which up until now has been the omitted category among the foreign-born, given that we include two sets of indicator variables 
that completely span the foreign born: (1) years in US and (2) country of origin*/
gen Tbpl1_434=(bpl==434)

/* Create interactions between county-of-origin dummies and years spent in US dummies for the panel sample*/
foreach var of varlist T* {
gen PIyrs1_`var'=`var'*PIyrsusa2_1
gen PIyrs2_`var'=`var'*PIyrsusa2_2
gen PIyrs3_`var'=`var'*PIyrsusa2_3
gen PIyrs4_`var'=`var'*PIyrsusa2_4
gen PIyrs5_`var'=`var'*PIyrsusa2_5
}
/* Regress occupation score on set of indicators for years in the US interacted with country of origin (included in PIyrs*) for panel sample only.*/
reg occscore_all age age2 age3 age4 PIyrs1* PIyrs2* PIyrs3* PIyrs4* PIyrs5* Y* [pw=weight2] if panel_flag==1 
/* Test whether the difference between the indicator for recent arrival and the indicator for long-term (30+ year) migrant are different by country-of-origin to 
determine whether immigrants from that country experienced a statistically significant amount of convergence*/
test (PIyrs1_Tbpl1_400-PIyrs5_Tbpl1_400)==0
test (PIyrs1_Tbpl1_401-PIyrs5_Tbpl1_401)==0
test (PIyrs1_Tbpl1_404-PIyrs5_Tbpl1_404)==0
test (PIyrs1_Tbpl1_405-PIyrs5_Tbpl1_405)==0
test (PIyrs1_Tbpl1_410-PIyrs5_Tbpl1_410)==0
test (PIyrs1_Tbpl1_411-PIyrs5_Tbpl1_411)==0
test (PIyrs1_Tbpl1_412-PIyrs5_Tbpl1_412)==0
test (PIyrs1_Tbpl1_414-PIyrs5_Tbpl1_414)==0
test (PIyrs1_Tbpl1_420-PIyrs5_Tbpl1_420)==0
test (PIyrs1_Tbpl1_421-PIyrs5_Tbpl1_421)==0
test (PIyrs1_Tbpl1_426-PIyrs5_Tbpl1_426)==0
test (PIyrs1_Tbpl1_434-PIyrs5_Tbpl1_434)==0
test (PIyrs1_Tbpl1_436-PIyrs5_Tbpl1_436)==0
test (PIyrs1_Tbpl1_450-PIyrs5_Tbpl1_450)==0
test (PIyrs1_Tbpl1_453-PIyrs5_Tbpl1_453)==0
test (PIyrs1_Tbpl1_465-PIyrs5_Tbpl1_465)==0


/* Figure 3 (black bars) - Initial immigrant arrivals (0-5 yrs) vs. natives in panel by country*/
/* Reports (coeff. on PIyrs1 + coeff. on Panel) by country*/
/* Figure 3 (gray bars) - Long-term immigrants (30+ yrs) vs. natives in panel by country*/
/* Reports (coeff. on PIyrs5 + coeff. on Panel) by country*/

/* Figure 4 - Cohort quality. Compare cohort effect for longest-standing (arrive 1880-85) to most recent arrival (1895-1900) in panel sample*/
gen Cohd_Panel=(yrimmig<=1885 & panel_flag==1 & bpl>100)
foreach var of varlist T* {
gen PCohc_`var'=`var'*Cohc_Panel
gen PCohd_`var'=`var'*Cohd_Panel
}
reg occscore_all age age2 age3 age4 PIyrsusa2_1-PIyrsusa2_5 T* PCohc* PCohd* Coha_Panel  Y* [pw=weight2] if panel_flag==1
test (PCohc_Tbpl1_400-PCohd_Tbpl1_400)==0
test (PCohc_Tbpl1_401-PCohd_Tbpl1_401)==0
test (PCohc_Tbpl1_404-PCohd_Tbpl1_404)==0
test (PCohc_Tbpl1_405-PCohd_Tbpl1_405)==0
test (PCohc_Tbpl1_410-PCohd_Tbpl1_410)==0
test (PCohc_Tbpl1_411-PCohd_Tbpl1_411)==0
test (PCohc_Tbpl1_412-PCohd_Tbpl1_412)==0
test (PCohc_Tbpl1_414-PCohd_Tbpl1_414)==0
test (PCohc_Tbpl1_420-PCohd_Tbpl1_420)==0
test (PCohc_Tbpl1_421-PCohd_Tbpl1_421)==0
test (PCohc_Tbpl1_426-PCohd_Tbpl1_426)==0
test (PCohc_Tbpl1_434-PCohd_Tbpl1_434)==0
test (PCohc_Tbpl1_436-PCohd_Tbpl1_436)==0
test (PCohc_Tbpl1_450-PCohd_Tbpl1_450)==0
test (PCohc_Tbpl1_453-PCohd_Tbpl1_453)==0
test (PCohc_Tbpl1_465-PCohd_Tbpl1_465)==0

/* Figure 5 - Return migrants. Compare "occupational growth" between recent arrivals (0-5 yr) and long-term migrants (30+ yrs) in the cross section and the 
panel*/
foreach var of varlist T* {
gen CSIyrs1_`var'=`var'*(1-panel_flag)*Iyrsusa2_1
gen CSIyrs4_`var'=`var'*(1-panel_flag)*Iyrsusa2_4
}
#delimit ;
reg occscore_all age age2 age3 age4 PIyrs1* PIyrs4* CSIyrs1* CSIyrs4* Y* C1 PC1 [pw=weight2] if (fb==0 | PIyrsusa2_1==1 | PIyrsusa2_4==1 | Iyrsusa2_1==1 | 
Iyrsusa2_4==1);
#delimit cr

test ((CSIyrs4_Tbpl1_400-CSIyrs1_Tbpl1_400)-(PIyrs4_Tbpl1_400-PIyrs1_Tbpl1_400))==0
test ((CSIyrs4_Tbpl1_401-CSIyrs1_Tbpl1_401)-(PIyrs4_Tbpl1_401-PIyrs1_Tbpl1_401))==0
test ((CSIyrs4_Tbpl1_404-CSIyrs1_Tbpl1_404)-(PIyrs4_Tbpl1_404-PIyrs1_Tbpl1_404))==0
test ((CSIyrs4_Tbpl1_405-CSIyrs1_Tbpl1_405)-(PIyrs4_Tbpl1_405-PIyrs1_Tbpl1_405))==0
test ((CSIyrs4_Tbpl1_410-CSIyrs1_Tbpl1_410)-(PIyrs4_Tbpl1_410-PIyrs1_Tbpl1_410))==0
test ((CSIyrs4_Tbpl1_411-CSIyrs1_Tbpl1_411)-(PIyrs4_Tbpl1_411-PIyrs1_Tbpl1_411))==0
test ((CSIyrs4_Tbpl1_412-CSIyrs1_Tbpl1_412)-(PIyrs4_Tbpl1_412-PIyrs1_Tbpl1_412))==0
test ((CSIyrs4_Tbpl1_414-CSIyrs1_Tbpl1_414)-(PIyrs4_Tbpl1_414-PIyrs1_Tbpl1_414))==0
test ((CSIyrs4_Tbpl1_420-CSIyrs1_Tbpl1_420)-(PIyrs4_Tbpl1_420-PIyrs1_Tbpl1_420))==0
test ((CSIyrs4_Tbpl1_421-CSIyrs1_Tbpl1_421)-(PIyrs4_Tbpl1_421-PIyrs1_Tbpl1_421))==0
test ((CSIyrs4_Tbpl1_426-CSIyrs1_Tbpl1_426)-(PIyrs4_Tbpl1_426-PIyrs1_Tbpl1_426))==0
test ((CSIyrs4_Tbpl1_434-CSIyrs1_Tbpl1_434)-(PIyrs4_Tbpl1_434-PIyrs1_Tbpl1_434))==0
test ((CSIyrs4_Tbpl1_436-CSIyrs1_Tbpl1_436)-(PIyrs4_Tbpl1_436-PIyrs1_Tbpl1_436))==0
test ((CSIyrs4_Tbpl1_450-CSIyrs1_Tbpl1_450)-(PIyrs4_Tbpl1_450-PIyrs1_Tbpl1_450))==0
test ((CSIyrs4_Tbpl1_453-CSIyrs1_Tbpl1_453)-(PIyrs4_Tbpl1_453-PIyrs1_Tbpl1_453))==0
test ((CSIyrs4_Tbpl1_465-CSIyrs1_Tbpl1_465)-(PIyrs4_Tbpl1_465-PIyrs1_Tbpl1_465))==0



log close








