rm(list = ls())
setwd("~//HistCensus")
library(ipumsr)

dtypeSQL <- function(type) {
  if ("character" %in% type) {
    return("char(100)")
  } else if ("integer" %in% type) {
    return("int")
  } else if ("numeric" %in% type | "double" %in% type) {
    return("float8")
  }
}

structureSQL <- function(data) {
  retstr <- ""
  retstr <- paste0(retstr, "CREATE TABLE . (")
  for (i in 1:length(names(data))) {
    retstr <- paste0(retstr,
      names(data)[i], " ", dtypeSQL(class(df[[i]])))
    if (i != length(names(data))) {
      retstr <- paste0(retstr, ", ")
    }
  }
  retstr <- paste0(retstr, ");")
  return(retstr)
}

structureSQL(df)
class(df$BIRTHYR)