library(Herper)

tempdir2 <- function(){
  gsub("\\","/", tempdir(),fixed=TRUE)
}
myMiniconda <- file.path(tempdir2(),"Test")

#Test that the install works okay
test_that("1_install_CondaTools", {
  expect_equal(length(install_CondaTools("multiqc", "herper", pathToMiniConda = myMiniconda)), 3)
  if(!identical(.Platform$OS.type, "windows")){expect_error(install_CondaTools("multi", "herper", pathToMiniConda = myMiniconda))
  }else{expect_message(install_CondaTools("multi", "herper", pathToMiniConda = myMiniconda))}
})

#Test install with mock
# test_that("2_install_CondaTools_mock", {
#   mockr::with_mock(
#     conda_install_silentJSON = function(...) {},
#     {expect_equal(names(install_CondaTools("multiqc", "herper2", pathToMiniConda = myMiniconda)), c("pathToConda","environment","pathToEnvBin"))})})

#Test that installed functionality works
test_that("3_with_CondaEnv", {
  expect_equal(grepl("version", with_CondaEnv("herper", system2("multiqc","--version", stdout = TRUE),
                                                       pathToMiniConda = myMiniconda)), TRUE)
})

#Conda search testing
test_that("4_conda_search", {
  expect_true(conda_search("multiqc",pathToMiniConda=myMiniconda))
})

