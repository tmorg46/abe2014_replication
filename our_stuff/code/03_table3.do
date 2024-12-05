/*

step 3: replicate Table 4 from the ABE paper

*/

clear all
frames reset

global route "/Users/tmorg46/Desktop/abe2014_replication/our_stuff"


**********************************************
* Replicate their Table 4 - PCS vs PCS + Panel
**********************************************
// pending
*start with the Canadian men; the specs have to be a bit different because of country fixed effects, etc.
use "${route}/intermediate_datasets/canada_pcs.dta", clear

*do the column 1 regression: just on the pooled cross-section. we don't have birthplace fixed effects because it's only canada or not, and that indicator is collinear with the yrsusa fixed effects
reg occscore2010 i.yrsusa2 i.year age age2 age3 age4, robust

matrix define tab4col1_beta_can = r(table)[1,2..6]' // this puts the coefficients from the yrsusa2 fixed effects into a column vector we can use later
matrix define tab4col1_ster_can = r(table)[2,2..6]' // and the standard errors
local col1_N_can = e(N) // we need the observation count as well!!


*now let's get the panel folks in and marked, then run the next two columns
append using "${route}/intermediate_datasets/canada_links.dta"
gen in_panel   = !missing(panel_id) // if it ain't missing they're in the panel
gen post1890   = yrimmig>1890

gen panel_post   = in_panel * post1890
replace post1890 = 0 if panel_post==1 // they get a negative coefficient on Arrive 1891+ via this interaction, which makes sense in their paper, so we'll do it here

*they do some more funky adjustments to the fixed effects values for their tables, so we'll replicate them here (basically trying to add coefficients together pre-regression)
tab yrsusa2, gen(I_yrs)
foreach var of varlist I_yrs* {
	gen P_`var' = in_panel * `var'		// an interaction term with being in the panel
	replace `var' = 0 if in_panel==1 	// this is the weird one
}

*run the column 2 and 3 regression!!
reg occscore2010 		/// we have to do a gross regression here because they hate us
	I_yrs2 I_yrs3 I_yrs4 I_yrs5 I_yrs6						/// These are the fixed effects on duration for the cross-section, leaving out the natives (they're in I_yrs1)
	P_I_yrs2 P_I_yrs3 P_I_yrs4 P_I_yrs5 P_I_yrs6 P_I_yrs1 	/// these are the interactions on immigrant duration for the panel folks
	post1890 panel_post										///  gotta add these
	i.year age age2 age3 age4, robust
	
matrix define tab4col2_3_beta_can = r(table)[1,1..13]' // this puts the coefficients from the yrsusa2 fixed effects into a column vector we can use later
matrix define tab4col2_3_ster_can = r(table)[2,1..13]' // and the standard errors
local col2_3_N_can = e(N) // we need the observation count as well!!


*now it's time to put together the table into an Excel file:
putexcel set "${route}/output/tables", sheet(table4_can, replace) modify // we're replacing the table4 sheet but modifying the document as a whole; this avoids deleting other tables later but still lets us refresh this table on each rerun
putexcel A1  = "Canadian men"
		 
putexcel B2  = "PCS Only"		///  
		 B3  = `col1_N_can'	///
		 A4  = matrix(tab4col1_beta_can), rownames nformat(#,###.00)
		 
putexcel C2  = "St. Errs"		///
		 C4  = matrix(tab4col1_ster_can), nformat(#.00)
		 
putexcel F2  = "Combo Values" 	///
		 F3	 = `col2_3_N_can'	///
		 E4	 = matrix(tab4col2_3_beta_can), rownames nformat(#,###.00)
		 
putexcel G4  = matrix(tab4col2_3_ster_can), nformat(#.00)
putexcel E14 = "Native-born"


********************************
* Now let's get the ladies done!
use "${route}/intermediate_datasets/women_pcs.dta", clear

*we need a numeric bpl version for easy fixed effects:
replace bpl = 1 if bpl<100 // now all the american folks have the same bpl, and it'll be the excluded one in i. specifications

*do the column 1 regression: just on the pooled cross-section. we don't have birthplace fixed effects because it's only canada or not, and that indicator is collinear with the yrsusa fixed effects
reg occscore2010 i.yrsusa2 i.year age age2 age3 age4 i.bpl, robust

matrix define tab4col1_beta_wom = r(table)[1,2..6]' // this puts the coefficients from the yrsusa2 fixed effects into a column vector we can use later
matrix define tab4col1_ster_wom = r(table)[2,2..6]' // and the standard errors
local col1_N_wom = e(N) // we need the observation count as well!!


*now let's get the panel folks in and marked, then run the next two columns
append using "${route}/intermediate_datasets/women_links.dta"
replace bpl = 1 if bpl<100 // same as above, just gotta do it again post-append

gen in_panel   = !missing(panel_id) // if it ain't missing they're in the panel
gen post1890   = yrimmig>1890

gen panel_post   = in_panel * post1890
replace post1890 = 0 if panel_post==1 // they get a negative coefficient on Arrive 1891+ via this interaction, which makes sense in their paper, so we'll do it here

*they do some more funky adjustments to the fixed effects values for their tables, so we'll replicate them here (basically trying to add coefficients together pre-regression)
tab yrsusa2, gen(I_yrs)
foreach var of varlist I_yrs* {
	gen P_`var' = in_panel * `var'		// an interaction term with being in the panel
	replace `var' = 0 if in_panel==1 	// this is the weird one
}

*run the column 2 and 3 regression!!
reg occscore2010 		/// we have to do a gross regression here because they hate us
	I_yrs2 I_yrs3 I_yrs4 I_yrs5 I_yrs6						/// These are the fixed effects on duration for the cross-section, leaving out the natives (they're in I_yrs1)
	P_I_yrs2 P_I_yrs3 P_I_yrs4 P_I_yrs5 P_I_yrs6 P_I_yrs1 	/// these are the interactions on immigrant duration for the panel folks
	post1890 panel_post										///  gotta add these
	i.year age age2 age3 age4 i.bpl, robust
	
matrix define tab4col2_3_beta_wom = r(table)[1,1..13]' // this puts the coefficients from the yrsusa2 fixed effects into a column vector we can use later
matrix define tab4col2_3_ster_wom = r(table)[2,1..13]' // and the standard errors
local col2_3_N_wom = e(N) // we need the observation count as well!!


*now it's time to put together the table into an Excel file:
putexcel set "${route}/output/tables", sheet(table4_wom, replace) modify // we're replacing the table4 sheet but modifying the document as a whole; this avoids deleting other tables later but still lets us refresh this table on each rerun
putexcel A1  = "European women"
		 
putexcel B2  = "PCS Only"		///  
		 B3  = `col1_N_wom'	///
		 A4  = matrix(tab4col1_beta_wom), rownames nformat(#,###.00)
		 
putexcel C2  = "St. Errs"		///
		 C4  = matrix(tab4col1_ster_wom), nformat(#.00)
		 
putexcel F2  = "Combo Values" 	///
		 F3	 = `col2_3_N_wom'	///
		 E4	 = matrix(tab4col2_3_beta_wom), rownames nformat(#,###.00)
		 
putexcel G4  = matrix(tab4col2_3_ster_wom), nformat(#.00)
putexcel E14 = "Native-born"

// and now we're done! we can hand put it into LaTeX from tables.xlsx because then it will be pretty :)










