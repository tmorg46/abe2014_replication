/*

we gotta build a log to get this sucker done in a log

so here we go:

*/

clear all

global route "/Users/tmorg46/Desktop/abe2014_replication/our_stuff"

cap log close
log using "${route}/output/oops_all_logs.txt", text replace nomsg

*it's gonna do all four of my stata do files. I can't run Eli's code for the figure and his data structure because I don't have R installed :)

do "${route}/code/01_build_datasets.do"

do "${route}/code/02_table2.do"

do "${route}/code/03_table3.do"

do "${route}/code/04_table4.do"

log close // :) yay!
