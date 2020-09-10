---
title: "Introduction to Herper"
author: 
- Matt Paul
- Bioinformatics Resource Center - Rockefeller University
- "mpaul@rockefeller.edu"
date: "10 September, 2020"
output: 
  html_document:
    keep_md: yes
    theme: cosmo
---



---





## What is Herper?
The Herper package is a simple toolset to install and manage Conda packages and environments from R.

Many R packages require the use of external dependencies. Often these dependencies can be installed and managed with the Conda package repository. For example 169 Bioconductor packages have external dependencies listed in their System Requirements field (often with these packages having several requirements) [03 September, 2020]. 

---

<img src="imgs/pkg_deps_bar_mask-1.png" width="1920" />

---

The Herper package includes functions that allow the easy management of these external dependencies from within the R console.

---
## Installation

Use the `BiocManager` package to download and install the package from our Github repository:


```r
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("https://github.com/RockefellerUniversity/CondaSysReqs")
```

Once installed, load it into your R session:


```r
library(CondaSysReqs)
```

```
## Loading required package: reticulate
```


---
## Simple install of Conda packages from R console using **install_CondaTools**. 

The **install_CondaTools()** function allows the user to specify required Conda software and the desired environment to install into.

Miniconda is installed as part of the process (by default into the r-reticulate's default Conda location). If you already have Miniconda installed you specify the path with the *pathToMiniConda* parameter.


```
## $pathToConda
## [1] "/tmp//r-miniconda/bin/conda"
## 
## $environment
## [1] "myCondaToolSet"
## 
## $pathToEnvBin
## [1] "/tmp//r-miniconda/envs/myCondaToolSet/bin"
```

```r
install_CondaTools("salmon", "myCondaToolSet")
```

We can add additional tools to our Conda environment by specifying *updateEnv = TRUE*.

```
## $pathToConda
## [1] "/tmp//r-miniconda/bin/conda"
## 
## $environment
## [1] "myCondaToolSet"
## 
## $pathToEnvBin
## [1] "/tmp//r-miniconda/envs/myCondaToolSet/bin"
```

```r
pathToConda <- install_CondaTools("macs2", "myCondaToolSet", updateEnv = TRUE)
pathToConda
```



---
## Simple install of R package dependencies using **install_CondaSysReqs**.



---
## Export of Conda environments to YAML files using **export_CondaEnv**.

The **export_CondaEnv** function allows the user to export the environment information to a *.yml* file. These environment YAML files contain all essential information about the package, allowing for reproducibilty and easy distribution of Conda system configuration for collaboration. 


```r
yml_name <- paste0("myCondaToolSet_", format(Sys.Date(), "%Y%m%d"),".yml")
export_CondaEnv("myCondaToolSet", yml_name)
```

```
## [1] "myCondaToolSet_20200910.yml"
```
---
The YAML export will contain all packages in the environment by default. If the user wants to only export the packages that were specifically installed and not their dependencies they can use the *depends* paramter. 

```r
yml_name <- paste0("myCondaToolSet_nodeps_", format(Sys.Date(), "%Y%m%d"),".yml")
export_CondaEnv("myCondaToolSet", yml_name, depends=FALSE)
```

```
## [1] "myCondaToolSet_nodeps_20200910.yml"
```

---
## Import of Conda environments from YAML files using **import_CondaEnv**.

The **import_CondaEnv** function allows the user to create a new conda environment from a *.yml* file. These can be previously exported from **export_CondaEnv**, conda, renv or manually created. 

Users can simply provide a path to the YAML file for import. They can also specify the environment name, but by default the name will be taken from the YAML. 


```r
import_CondaEnv(yml_name, "myCondaToolSet2")
```

---
## Using R packages with System Dependencies


```r
#use_condaenv() 
```

---
## Running Conda packages from R console.

Although we will not activate the environment, many tools can be used straight from the Conda environment's bin directory. When the result of **install_CondaTools()** is assigned to a variable, it will contain the path to the bin directory for that environment. Users can then run these tools with **System()** commands


```r
pathToSalmon <- file.path(pathToConda$pathToEnvBin, "salmon")
pathToSalmon
```

```
## [1] "/tmp//r-miniconda/envs/myCondaToolSet/bin/salmon"
```

```r
Salmon_help <- system(paste(pathToSalmon,"-h"), intern = TRUE)
Salmon_help
```

```
##  [1] "salmon v1.3.0"                                                      
##  [2] ""                                                                   
##  [3] "Usage:  salmon -h|--help or "                                       
##  [4] "        salmon -v|--version or "                                    
##  [5] "        salmon -c|--cite or "                                       
##  [6] "        salmon [--no-version-check] <COMMAND> [-h | options]"       
##  [7] ""                                                                   
##  [8] "Commands:"                                                          
##  [9] "     index      : create a salmon index"                            
## [10] "     quant      : quantify a sample"                                
## [11] "     alevin     : single cell analysis"                             
## [12] "     swim       : perform super-secret operation"                   
## [13] "     quantmerge : merge multiple quantifications into a single file"
```

## Session Information


```r
devtools::session_info()
```

```
## ─ Session info ───────────────────────────────────────────────────────────────
##  setting  value                       
##  version  R version 4.0.2 (2020-06-22)
##  os       macOS Catalina 10.15.6      
##  system   x86_64, darwin17.0          
##  ui       X11                         
##  language (EN)                        
##  collate  en_US.UTF-8                 
##  ctype    en_US.UTF-8                 
##  tz       America/New_York            
##  date     2020-09-10                  
## 
## ─ Packages ───────────────────────────────────────────────────────────────────
##  package      * version date       lib source        
##  assertthat     0.2.1   2019-03-21 [1] CRAN (R 4.0.2)
##  backports      1.1.9   2020-08-24 [1] CRAN (R 4.0.2)
##  callr          3.4.4   2020-09-07 [1] CRAN (R 4.0.2)
##  cli            2.0.2   2020-02-28 [1] CRAN (R 4.0.2)
##  CondaSysReqs * 0.9.8   2020-09-10 [1] local         
##  crayon         1.3.4   2017-09-16 [1] CRAN (R 4.0.2)
##  desc           1.2.0   2018-05-01 [1] CRAN (R 4.0.2)
##  devtools       2.3.1   2020-07-21 [1] CRAN (R 4.0.2)
##  digest         0.6.25  2020-02-23 [1] CRAN (R 4.0.2)
##  ellipsis       0.3.1   2020-05-15 [1] CRAN (R 4.0.2)
##  evaluate       0.14    2019-05-28 [1] CRAN (R 4.0.1)
##  fansi          0.4.1   2020-01-08 [1] CRAN (R 4.0.2)
##  fs             1.5.0   2020-07-31 [1] CRAN (R 4.0.2)
##  glue           1.4.2   2020-08-27 [1] CRAN (R 4.0.2)
##  htmltools      0.5.0   2020-06-16 [1] CRAN (R 4.0.2)
##  jsonlite       1.7.1   2020-09-07 [1] CRAN (R 4.0.2)
##  knitr          1.29    2020-06-23 [1] CRAN (R 4.0.2)
##  lattice        0.20-41 2020-04-02 [1] CRAN (R 4.0.2)
##  magrittr       1.5     2014-11-22 [1] CRAN (R 4.0.2)
##  Matrix         1.2-18  2019-11-27 [1] CRAN (R 4.0.2)
##  memoise        1.1.0   2017-04-21 [1] CRAN (R 4.0.2)
##  pkgbuild       1.1.0   2020-07-13 [1] CRAN (R 4.0.2)
##  pkgload        1.1.0   2020-05-29 [1] CRAN (R 4.0.2)
##  png            0.1-7   2013-12-03 [1] CRAN (R 4.0.2)
##  prettyunits    1.1.1   2020-01-24 [1] CRAN (R 4.0.2)
##  processx       3.4.4   2020-09-03 [1] CRAN (R 4.0.2)
##  ps             1.3.4   2020-08-11 [1] CRAN (R 4.0.2)
##  R6             2.4.1   2019-11-12 [1] CRAN (R 4.0.2)
##  Rcpp           1.0.5   2020-07-06 [1] CRAN (R 4.0.2)
##  remotes        2.2.0   2020-07-21 [1] CRAN (R 4.0.2)
##  reticulate   * 1.16    2020-05-27 [1] CRAN (R 4.0.2)
##  rjson          0.2.20  2018-06-08 [1] CRAN (R 4.0.2)
##  rlang          0.4.7   2020-07-09 [1] CRAN (R 4.0.2)
##  rmarkdown      2.3     2020-06-18 [1] CRAN (R 4.0.2)
##  rprojroot      1.3-2   2018-01-03 [1] CRAN (R 4.0.2)
##  sessioninfo    1.1.1   2018-11-05 [1] CRAN (R 4.0.2)
##  stringi        1.5.3   2020-09-09 [1] CRAN (R 4.0.2)
##  stringr        1.4.0   2019-02-10 [1] CRAN (R 4.0.2)
##  testthat       2.3.2   2020-03-02 [1] CRAN (R 4.0.2)
##  usethis        1.6.1   2020-04-29 [1] CRAN (R 4.0.2)
##  withr          2.2.0   2020-04-20 [1] CRAN (R 4.0.2)
##  xfun           0.17    2020-09-09 [1] CRAN (R 4.0.2)
##  yaml           2.2.1   2020-02-01 [1] CRAN (R 4.0.2)
## 
## [1] /Library/Frameworks/R.framework/Versions/4.0/Resources/library
```
