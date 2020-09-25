library(CondaSysReqs)

tempdir2 <- function(){
  gsub("\\","/", tempdir(),fixed=TRUE)
}
myMiniconda <- file.path(tempdir2(),"Test")

test_that("install_CondaTools", {
  expect_equal(length(install_CondaTools("multiqc", "herper", pathToMiniConda = myMiniconda)), 3)
  if(!identical(.Platform$OS.type, "windows")){expect_error(install_CondaTools("multi", "herper", pathToMiniConda = myMiniconda))
    }else{expect_message(install_CondaTools("multi", "herper", pathToMiniConda = myMiniconda))}
})
