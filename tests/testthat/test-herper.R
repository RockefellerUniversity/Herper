library(Herper)

tempdir2 <- function(){
  gsub("\\","/", tempdir(),fixed=TRUE)
}
myMiniconda <- file.path(tempdir2(),"Test")

#Test that the install works okay
# test_that("1_install_CondaTools", {
#   expect_equal(length(install_CondaTools("multiqc", "herper", pathToMiniConda = myMiniconda)), 3)
#   if(!identical(.Platform$OS.type, "windows")){expect_error(install_CondaTools("mui", "herper", pathToMiniConda = myMiniconda, updateEnv = T))
#   }else{expect_message(install_CondaTools("mui", "herper", pathToMiniConda = myMiniconda))}
# 
#   }
# )
# 
# 
# #Test that installed functionality works
# test_that("3_with_CondaEnv", {
#   expect_equal(grepl("version", with_CondaEnv("herper", system2("multiqc","--version", stdout = TRUE),
#                                                        pathToMiniConda = myMiniconda)), TRUE)
# })

