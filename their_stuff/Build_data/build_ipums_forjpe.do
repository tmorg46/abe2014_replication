/* This do file explains how we construct the Census (IPUMS) data used in Abramitzky, Boustan and Eriksson (ipums_forjpe.dta)*/

clear
clear matrix
set mem 1000m
/* This is a raw dataset downloaded from the IPUMS website with individual Census records for 1900-1920*/
use 1900_20_ipums.dta

/*Define sample: Men only*/
keep if sex==1
/* Drop natives if live in South*/
drop if region>=31 & region<=33 & nativity<5
/* Keep if ages 18-55 (later restrict to specific ages in specific Census years to match panel sample)*/
keep if age>=18 & age<=55
/* Drop 46 immigrants who do not report years in US*/
drop if nativity==5 & yrsusa2==0

/*Define age at immigration*/
gen birthyear=year-age
gen age_immig=(yrimmig-birthyear) if nativity==5
replace age_immig=0 if bpl<100
replace age_immig=0 if age_immig<0

/* Define variables for regression*/
gen fb=(nativity==5)
/* Experience = age for Hatton specification*/
gen exp=age
gen age35=(age>=35)
gen age35exp=age35*exp
/* Higher order age terms*/
gen age2=age*age
gen age3=age2*age
gen age4=age3*age
/* Redefine years in US categories to match those used in panel sample*/
replace yrsusa2=3 if yrsusa2==4
replace yrsusa2=4 if yrsusa2==5
replace yrsusa2=5 if yrsusa1>30 & fb==1
xi, pref(I) i.yrsusa2

/* Keep immigrants only if they were born in one of our 16 sendin countries*/
#delimit ;
keep if bpl<99 | bpl==400 | bpl==401 | bpl==404 | (bpl>=410 & bpl<=412) | bpl==420 | bpl==421 | bpl==426 | bpl==434 | bpl==436 | bpl==465 | bpl==453 | bpl==450 | 
bpl==405 | bpl==414;
#delimit cr
gen bpl1=bpl
replace bpl1=0 if bpl<99
xi, pref(T) i.bpl1
/* Italy is omitted country when include two sets of indicator variables that span the foreign born: (1) Years in US (2) country of origin. So drop the Italy 
dummy variable*/
drop Tbpl1_434
/* Dependent variable 1: Occupation score*/
gen lnoccscore=ln(occscore)

/* Dependent variable 2: Match to Cost of Living survey income*/
/*Merge in cost of living-based income from Haines and Preston data*/
rename occ1950 occ1950_all
sort occ1950_all
merge occ1950_all using occ1950_hpincomes.dta
tab _merge
/*Replace farmer's income with average for three states from 1900 Agricultural Census (see build_panel_jpe.do for details)*/
replace income=796 if hp==16
gen lnincome=ln(income)

/* Sample to match panel*/ 
/* For ages: Keep if between ages 18-35 in 1900*/
keep if (age>=18 & age<=35 & year==1900) | (age>=28 & age<=45 & year==1910) | (age>=38 & age<=55 & year==1920)
/* Keep only immigrants who arrived between 1880-1900*/
keep if ((yrimmig>=1880 & yrimmig<=1900 & nativity==5) | fb==0)

/* Census year dummies*/
xi, pref(Y) i.year
/* Arrival cohort dummy*/
gen C1=(yrimmig>=1891 & fb==1)
/* Drop few observations that report being in US for less than 5 years but arriving before 1891. This option is logically inconsistent*/
drop if Iyrsusa2_1==1 & C1==0

/*Drop observations with 'zero' occupation score*/
drop if occscore==0
rename occscore occscore_all

/*Merge in urban/rural by county to create an urban indicator (see build_panel_forjpe.do for details)*/
sort statefip county
merge statefip county using icpsr_urbrural.dta
tab _merge
drop _merge
/* Generate an "urban" dummy*/
/* Rename the IPUMS urban variable which is an individual-level variable based on actual location*/
rename urban urban1
/* Generate the county-level variable to match the panel sample*/
gen urban=(shurb1>=.4 & shurb1!=.)
replace urban=. if shurb1==.

label var urban "=1 if live in county that is 40% or more urban, to match panel"
label var lnoccscore "ln(occupation-based income), 1950 basis"
label var hp "Haines-Preston occupation code"
label var income "occupation-based income from 1901 Cost of Living"
label var lnincome "ln(income), 1901 CoL survey"
label var C1 "=1 if foreign born and arrive in US after 1890"
label var bpl1 "birthplace, with all native born coded as '0'"
label var birthyear "Calendar year of birth"
label var age_immig "Calculated age at immigration"
label var fb "=1 if foreign born"
label var shurb1 "% of county living in jurisdiction with 2,500+ residents"
label var shurb2 "% of county living in jurisdiction with 25,000+ residents"
label var exp "Experience (=age)"
label var age35 "=1 if age>35"
label var age35exp "age35 * exp"



save ipums_forjpe.dta, replace








