<br>

------------------------------------------------------------------------

What is Herper?
---------------

The Herper package is a simple toolset to install and manage Conda
packages and environments from R.

Many R packages require the use of external dependencies. Often these
dependencies can be installed and managed with the Conda package
repository. For example 169 Bioconductor packages have external
dependencies listed in their System Requirements field (often with these
packages having several requirements) \[03 September, 2020\].

<br>

<img src="/Library/Frameworks/R.framework/Versions/4.0/Resources/library/CondaSysReqs/extdata/pkg_deps_bar_mask-1.png" width="1000px" style="display: block; margin: auto;" />

The Herper package includes functions that allow the easy management of
these external dependencies from within the R console.

<br>

Installation
------------

Use the `BiocManager` package to download and install the package from
our Github repository:

``` r
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("https://github.com/RockefellerUniversity/CondaSysReqs")
```

<br> Once installed, load it into your R session:

``` r
library(CondaSysReqs)
```

<br>

Simple install of Conda packages from R console using **install\_CondaTools**.
------------------------------------------------------------------------------

The **install\_CondaTools()** function allows the user to specify
required Conda software and the desired environment to install into.

Miniconda is installed as part of the process (by default into the
r-reticulate’s default Conda location -
/Users/mattpaul/Library/r-miniconda) and the user’s requested conda
environment built within the same directory (by default
/Users/mattpaul/Library/r-miniconda/envs/USERS\_ENVIRONMENT\_HERE).

If you already have Miniconda installed or you would like to install to
a custom location, you can specify the path with the *pathToMiniConda*
parameter.

``` r
myMiniconda <- file.path(tempdir(),"Test")
install_CondaTools("salmon", "herper", pathToMiniConda = myMiniconda)
```

    ## $pathToConda
    ## [1] "/var/folders/zy/x35d37h50sq2_fp3zrjydcl00000gn/T//RtmpSfl9gI/Test/bin/conda"
    ## 
    ## $environment
    ## [1] "herper"
    ## 
    ## $pathToEnvBin
    ## [1] "/var/folders/zy/x35d37h50sq2_fp3zrjydcl00000gn/T//RtmpSfl9gI/Test/envs/herper/bin"

<br> We can add additional tools to our Conda environment by specifying
*updateEnv = TRUE*. A vector of tools can be used to install several at
once.

``` r
pathToConda <- install_CondaTools(c("samtools", "macs2"), "herper", updateEnv = TRUE, pathToMiniConda = myMiniconda)
pathToConda
```

    ## $pathToConda
    ## [1] "/var/folders/zy/x35d37h50sq2_fp3zrjydcl00000gn/T//RtmpSfl9gI/Test/bin/conda"
    ## 
    ## $environment
    ## [1] "herper"
    ## 
    ## $pathToEnvBin
    ## [1] "/var/folders/zy/x35d37h50sq2_fp3zrjydcl00000gn/T//RtmpSfl9gI/Test/envs/herper/bin"

<br> Specific package versions can be installed using conda formatted
inputs into the *tools* argument i.e. “salmon==1.3”, “salmon\>=1.3” or
“salmon\<=1.3”. This can also be used to specifically upgrade or
downgrade existing tools in the chosen environment.

``` r
pathToConda <- install_CondaTools("salmon<=1.3", "herper", updateEnv = TRUE, pathToMiniConda = myMiniconda)
```

<br>

Install R package dependencies with **install\_CondaSysReqs**.
--------------------------------------------------------------

The **install\_CondaSysReqs** checks the System Requirements for the
specified R package, and uses Conda to install this software. Here we
will use a test package contained within Herper. This test package has
two System Requirements:

``` r
testPkg <- system.file("extdata/HerperTestPkg",package="CondaSysReqs")
install.packages(testPkg,type = "source",repos = NULL)
utils::packageDescription("HerperTestPkg",fields = "SystemRequirements")
```

    ## [1] "samtools==1.10, rmats>=v4.1.0"

The user can simply supply the name of an installed R package, and
**install\_CondaSysReqs** will install the System Requirements through
conda.

``` r
condaPaths <- install_CondaSysReqs("HerperTestPkg",pathToMiniConda=myMiniconda,SysReqsAsJSON=FALSE)
```

By default these packages are installed in a new environment, which has
the name name of the R package and its version number. Users can control
the environment name using the *env* parameter. As with
**install\_CondaTools()**, user can control which version of Miniconda
with the parameter *pathToMiniConda*, and whether they want to amend an
existing environment with the parameter *updateEnv*.

*Note: **install\_CondaSysReqs** can handle standard System Requirement
formats, but will not work if the package has free form text. In this
case just use **install\_CondaTools***

<br>

Using R packages with System Dependencies with **with\_CondaEnv**
-----------------------------------------------------------------

**with\_CondaEnv** allows users to run an R command using a specific
conda environment. This will give the R package access to the conda
tools, Python, Perl and Java in this environment. This is done without
formally activating your environment or initializing your conda. The
Python/Perl/Java libraries used can also be controlled with the
corresponding parameters \_\_\*\_additional\_\_.

To demonstrate this we will use the first command from the
[seqCNA](https://www.bioconductor.org/packages/release/bioc/html/seqCNA.html)
vignette. This step requires access samtools. If this is not installed
there is an error. But if the command is run using **with\_CondaEnv**,
then seqCNA can find samtools.

``` r
library(seqCNA)
data(seqsumm_HCC1143)
try(rco <- readSeqsumm(tumour.data=seqsumm_HCC1143),silent = F)
install_CondaSysReqs("seqCNA",env="seqCNA",pathToMiniConda=myMiniconda,SysReqsAsJSON=FALSE)
```

    ## $pathToConda
    ## [1] "/var/folders/zy/x35d37h50sq2_fp3zrjydcl00000gn/T//RtmpSfl9gI/Test/bin/conda"
    ## 
    ## $environment
    ## [1] "seqCNA"
    ## 
    ## $pathToEnvBin
    ## [1] "/var/folders/zy/x35d37h50sq2_fp3zrjydcl00000gn/T//RtmpSfl9gI/Test/envs/seqCNA/bin"

``` r
with_CondaEnv("seqCNA", rco <- readSeqsumm(tumour.data=seqsumm_HCC1143)
 ,pathToMiniConda = myMiniconda)
```

<br>

Running Conda packages from R console with **with\_CondaEnv**
-------------------------------------------------------------

**with\_CondaEnv** allows users to run an conda tools from within R. The
user simply has to wrap the command in the **system()** or **system2()**
fucntions.

``` r
with_CondaEnv("HerperTestPkg_0.1.0",system2(command = "rmats.py",args = "-h"),pathToMiniConda = myMiniconda)
```

Finding Conda packages with **conda\_search**
---------------------------------------------

If the user is unsure of the exact name, or version of a tool available
on conda, they can use the **conda\_search** function.

``` r
conda_search("salmon",pathToMiniConda = myMiniconda)
```

    ##      name version                                    channel
    ## 2  salmon   0.8.2 https://conda.anaconda.org/bioconda/osx-64
    ## 3  salmon   0.9.0 https://conda.anaconda.org/bioconda/osx-64
    ## 5  salmon   0.9.1 https://conda.anaconda.org/bioconda/osx-64
    ## 6  salmon  0.10.0 https://conda.anaconda.org/bioconda/osx-64
    ## 7  salmon  0.10.1 https://conda.anaconda.org/bioconda/osx-64
    ## 9  salmon  0.10.2 https://conda.anaconda.org/bioconda/osx-64
    ## 11 salmon  0.11.3 https://conda.anaconda.org/bioconda/osx-64
    ## 12 salmon  0.12.0 https://conda.anaconda.org/bioconda/osx-64
    ## 14 salmon  0.13.0 https://conda.anaconda.org/bioconda/osx-64
    ## 15 salmon  0.13.1 https://conda.anaconda.org/bioconda/osx-64
    ## 17 salmon  0.14.0 https://conda.anaconda.org/bioconda/osx-64
    ## 20 salmon  0.14.1 https://conda.anaconda.org/bioconda/osx-64
    ## 22 salmon  0.14.2 https://conda.anaconda.org/bioconda/osx-64
    ## 23 salmon  0.15.0 https://conda.anaconda.org/bioconda/osx-64
    ## 24 salmon   1.0.0 https://conda.anaconda.org/bioconda/osx-64
    ## 25 salmon   1.1.0 https://conda.anaconda.org/bioconda/osx-64
    ## 26 salmon   1.2.0 https://conda.anaconda.org/bioconda/osx-64
    ## 27 salmon   1.2.1 https://conda.anaconda.org/bioconda/osx-64
    ## 28 salmon   1.3.0 https://conda.anaconda.org/bioconda/osx-64

    ## [1] TRUE

Specific package versions can be searched for using the conda format
i.e. “salmon==1.3”, “salmon\>=1.3” or “salmon\<=1.3”. Searches will also
find close matches for incorrect queries. Channels to search in can be
controlled with *channels* parameter.

``` r
conda_search("salmon<=1.0",pathToMiniConda = myMiniconda)
```

    ##      name version                                    channel
    ## 2  salmon   0.8.2 https://conda.anaconda.org/bioconda/osx-64
    ## 3  salmon   0.9.0 https://conda.anaconda.org/bioconda/osx-64
    ## 5  salmon   0.9.1 https://conda.anaconda.org/bioconda/osx-64
    ## 6  salmon  0.10.0 https://conda.anaconda.org/bioconda/osx-64
    ## 7  salmon  0.10.1 https://conda.anaconda.org/bioconda/osx-64
    ## 9  salmon  0.10.2 https://conda.anaconda.org/bioconda/osx-64
    ## 11 salmon  0.11.3 https://conda.anaconda.org/bioconda/osx-64
    ## 12 salmon  0.12.0 https://conda.anaconda.org/bioconda/osx-64
    ## 14 salmon  0.13.0 https://conda.anaconda.org/bioconda/osx-64
    ## 15 salmon  0.13.1 https://conda.anaconda.org/bioconda/osx-64
    ## 17 salmon  0.14.0 https://conda.anaconda.org/bioconda/osx-64
    ## 20 salmon  0.14.1 https://conda.anaconda.org/bioconda/osx-64
    ## 22 salmon  0.14.2 https://conda.anaconda.org/bioconda/osx-64
    ## 23 salmon  0.15.0 https://conda.anaconda.org/bioconda/osx-64

    ## [1] TRUE

``` r
conda_search("salm",pathToMiniConda = myMiniconda)
```

    ## [1] FALSE

<br> \#\# Export of Conda environments to YAML files using
**export\_CondaEnv**.

The **export\_CondaEnv** function allows the user to export the
environment information to a *.yml* file. These environment YAML files
contain all essential information about the package, allowing for
reproducibilty and easy distribution of Conda system configuration for
collaboration.

``` r
yml_name <- paste0("herper_", format(Sys.Date(), "%Y%m%d"),".yml")
export_CondaEnv("herper", yml_name,pathToMiniConda = myMiniconda)
```

    ## [1] "herper_20200918.yml"

<br>

The YAML export will contain all packages in the environment by default.
If the user wants to only export the packages that were specifically
installed and not their dependencies they can use the *depends*
paramter.

``` r
yml_name <- paste0("herper_nodeps_", format(Sys.Date(), "%Y%m%d"),".yml")
export_CondaEnv("herper", yml_name, depends=FALSE, pathToMiniConda = myMiniconda)
```

    ## [1] "herper_nodeps_20200918.yml"

<br>

Import of Conda environments from YAML files using **import\_CondaEnv**.
------------------------------------------------------------------------

The **import\_CondaEnv** function allows the user to create a new conda
environment from a *.yml* file. These can be previously exported from
**export\_CondaEnv**, conda, renv or manually created.

Users can simply provide a path to the YAML file for import. They can
also specify the environment name, but by default the name will be taken
from the YAML.

``` r
import_CondaEnv(yml_name, "herper2",myMiniconda)
```

<br> <br>

Acknowledgements
----------------

The Herper package was developed by Matt Paul, Tom Carroll and Doug
Barrows. Thank you to Ji-Dung Luo and Wei Wang for testing/vignette
review/critical feedback and Ziwei Liang for their support.

<br> \#\# Session Information

``` r
sessionInfo()
```

    ## R version 4.0.2 (2020-06-22)
    ## Platform: x86_64-apple-darwin17.0 (64-bit)
    ## Running under: macOS Catalina 10.15.6
    ## 
    ## Matrix products: default
    ## BLAS:   /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib
    ## LAPACK: /Library/Frameworks/R.framework/Versions/4.0/Resources/lib/libRlapack.dylib
    ## 
    ## locale:
    ## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] BiocStyle_2.16.0    CondaSysReqs_0.99.0 seqCNA_1.34.0       seqCNA.annot_1.24.0
    ##  [5] adehabitatLT_0.3.25 CircStats_0.2-6     boot_1.3-25         MASS_7.3-53        
    ##  [9] adehabitatMA_0.3.14 ade4_1.7-15         sp_1.4-2            doSNOW_1.0.18      
    ## [13] snow_0.4-3          iterators_1.0.12    foreach_1.5.0       GLAD_2.52.0        
    ## [17] reticulate_1.16    
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] Rcpp_1.0.5          BiocManager_1.30.10 compiler_4.0.2      tools_4.0.2        
    ##  [5] testthat_2.3.2      digest_0.6.25       pkgload_1.1.0       evaluate_0.14      
    ##  [9] jsonlite_1.7.1      lattice_0.20-41     rlang_0.4.7         Matrix_1.2-18      
    ## [13] cli_2.0.2           rstudioapi_0.11     yaml_2.2.1          parallel_4.0.2     
    ## [17] xfun_0.17           stringr_1.4.0       withr_2.2.0         knitr_1.29         
    ## [21] desc_1.2.0          rprojroot_1.3-2     grid_4.0.2          glue_1.4.2         
    ## [25] R6_2.4.1            fansi_0.4.1         bookdown_0.20       rmarkdown_2.3      
    ## [29] magrittr_1.5        backports_1.1.9     codetools_0.2-16    htmltools_0.5.0    
    ## [33] assertthat_0.2.1    stringi_1.5.3       rjson_0.2.20        crayon_1.3.4
