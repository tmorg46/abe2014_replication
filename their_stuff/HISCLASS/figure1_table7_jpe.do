/***This file creates Figure 1 and Table 7 in Abramitzky, Boustan and Eriksson***/

cap clear

/****analysis with PANEL data**********/

/*open panel data and merge in hisclass classification*/

use panel_all_forjpe
keep if (yrimmig>=1880 | bpl<100)

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

/*put incomes in 2010 dollars*/

replace occscore_all=occscore_all*900
replace income=income*26.8

gen occ50us = occ1950_all

sort occ50us
cap drop _merge

merge occ50us using hisclass50.dta

tab _merge

keep if _merge==3

gen native = bpl==1


/*fix some hisclass values that are missing*/
replace hisclass = 9 if occ1950_all==290 & hisclass==.
replace hisclass = 12 if occ1950_all==970 & hisclass==.
replace hisclass = 3 if occ1950_all==523 & hisclass==.
replace hisclass = 3 if occ1950_all==290


/*first drop 1910 then collapse 11 hisclass categories into 5*/
keep if year!=1910
gen hiscnew = 1 if hisclass==2 | hisclass==3 | hisclass==4 | hisclass==5 | hisclass==6
replace hiscnew = 2 if hisclass==7
replace hiscnew = 3 if hisclass==8
replace hiscnew = 4 if hisclass==9
replace hiscnew = 5 if hisclass==10 | hisclass==11 | hisclass==12


/*information for figure 1, panel b*/
tab hiscnew if year==1900 & native==1 [aw=weight2]
tab hiscnew if year==1900 & native==0  [aw=weight2]

/*info for figure 1, panel d*/
tab hiscnew if year==1900 & native==0  & yrimmig>1890 & yrimmig<=1900  [aw=weight2]
tab hiscnew if year==1900 & native==0  & yrimmig>1880 & yrimmig<=1890  [aw=weight2]


/*summarize occscore_all and income by new hisclass category for Figure 1, panel E*/
tab hiscnew [aweight=weight2], sum(occscore_all)
tab hiscnew [aweight=weight2], sum(income)

sum(occscore_all) [aweight=weight2] if native==0
sum(income) [aweight=weight2] if native==0

sum(occscore_all) [aweight=weight2] if native==1
sum(income) [aweight=weight2] if native==1


/**reshape the data so there is one observation for each person but so that we have a hisclass for 1900 and 1920*/
sort idnum_1900_uniq
by idnum_1900_uniq: egen min = min(weight2)

by idnum_1900_uniq: egen max = max(weight2)

drop if min!=max
drop if weight2==.

sort  idnum_1900_uniq year
drop if idnum_1900_uniq==idnum_1900_uniq & year==year[_n-1]

keep idnum_1900_uniq native year hiscnew weight2 native
reshape wide hiscnew, i(idnum_1900_uniq) j(year)

/*Table 7: create transition matrices*/
tab hiscnew1900 hiscnew1920 if native==1 [aw=weight2]
tab hiscnew1900 hiscnew1920 if native==0 [aw=weight2]

clear



/****analyis with IPUMS data********/

use ipums_forjpe.dta

gen native = bpl<100

/*Define sample: Men, if native-born, not living in South*/
keep if sex==1
/* Drop natives if live in South*/
drop if region>=31 & region<=33 & nativity<5
/* Start with all men age 18-55*/
keep if age>=18 & age<=55

gen occ50us = occ1950_all

sort occ50us

/* merge in hisclass*/
merge occ50us using hisclass50

tab _merge

keep if _merge==3
/*fix some hisclass values*/
replace hisclass = 9 if occ1950_all==290 & hisclass==.
replace hisclass = 12 if occ1950_all==970 & hisclass==.
replace hisclass = 3 if occ1950_all==523 & hisclass==.

replace hisclass = 3 if occ1950_all==290

tab hisclass if year==1900 & fb==0
tab hisclass if year==1900 & fb==1
tab hisclass if year==1900 & fb==1 & yrsusa2==1

tab hisclass if year==1920 & fb==0
tab hisclass if year==1920 & fb==1

gen hiscnew = 1 if hisclass==2 | hisclass==3 | hisclass==4 | hisclass==5 | hisclass==6
replace hiscnew = 2 if hisclass==7
replace hiscnew = 3 if hisclass==8
replace hiscnew = 4 if hisclass==9
replace hiscnew = 5 if hisclass==10 | hisclass==11 | hisclass==12

/*information for Figure 1, panel a*/

tab hiscnew if native==0, 
tab hiscnew if native==1


/*information for Figure 1, panel c*/
tab hiscnew if native==0 & yrimmig>=1880 & yrimmig<=1890
tab hiscnew if native==0 & yrimmig>1890 & yrimmig<=1900

