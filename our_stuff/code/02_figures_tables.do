/*

step 2: do analysis by replicating tables and figures with our new results!

	

*/

clear all
frames reset

global route "/Users/tmorg46/Desktop/abe2014_replication/our_stuff"


******************************************************
* Replicate their Table 1 - Sample Sizes & Match Rates
******************************************************
// pending
*we need to get 1900 baseline number-in-universe counts, so we'll loop through our pooled-cs and panel specifications:
foreach spec in pcs links {
		
	*open the canadian version first:
	use if year==1900 using "${route}/intermediate_datasets/canada_`spec'.dta", clear
		
	*loop through the two birthplaces
	foreach bpl_name in USA Canada {
		
		qui sum year if bpl_name=="`bpl_name'"
		local `spec'_`bpl_name'_men = r(N) // this stores the count in a local!
		
	}

	*now let's go get the ladies:
	use if year==1900 using "${route}/intermediate_datasets/women_`spec'.dta", clear

	*and now loop through all the countries:
	levelsof bpl_name, local(bpl_names) // get them all into a list in a local

	foreach bpl_name of local bpl_names { // and loop through that local!
		
		qui sum year if bpl_name=="`bpl_name'"
		local `spec'_`bpl_name'_women = r(N)
		
	}
}


	












