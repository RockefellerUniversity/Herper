Introduction
============

The CondaSysReqs package offers a simple toolset to install and manage
Conda environments from R using the the **install\_CondaTools** and
**install\_CondaSysReqs** functions.

Installation
============

Use the `BiocManager` package to download and install the package from
our Github repository:

``` r
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("https://github.com/RockefellerUniversity/CondaSysReqs")
```

Once installed, load it into your R session:

``` r
library(CondaSysReqs)
```

Simple install Conda Environment from R console using **install\_CondaTools**.
==============================================================================

The **install\_CondaTools()** function allows the user to specify
required Conda software and the desired environment to install into.

Miniconda is installed as part of the process (by default into the
r-reticulate’s default Conda location).

``` r
install_CondaTools("salmon","myCondaToolSet")
```

    ## $pathToConda
    ## [1] "/Users/mattpaul/Library/r-miniconda/bin/conda"
    ## 
    ## $environment
    ## [1] "myCondaToolSet"
    ## 
    ## $pathToEnvBin
    ## [1] "/Users/mattpaul/Library/r-miniconda/envs/myCondaToolSet/bin"

We can add additional tools to our Conda environment by specifying
*updateEnv = TRUE*.

``` r
pathToConda <- install_CondaTools("macs2","myCondaToolSet",updateEnv = TRUE)
pathToConda
```

    ## $pathToConda
    ## [1] "/Users/mattpaul/Library/r-miniconda/bin/conda"
    ## 
    ## $environment
    ## [1] "myCondaToolSet"
    ## 
    ## $pathToEnvBin
    ## [1] "/Users/mattpaul/Library/r-miniconda/envs/myCondaToolSet/bin"

Although we will not activate the environment, many tools can be used
straight from the Conda environment’s bin directory.

``` r
pathToMacs <- file.path(pathToConda$pathToEnvBin,"macs2")
pathToMacs
```

    ## [1] "/Users/mattpaul/Library/r-miniconda/envs/myCondaToolSet/bin/macs2"

``` r
Macs_help <- system(paste(pathToMacs,"-h"),intern = TRUE)
Macs_help
```

    ##  [1] "usage: macs2 [-h] [--version]"                                                                                                 
    ##  [2] "             {callpeak,bdgpeakcall,bdgbroadcall,bdgcmp,bdgopt,cmbreps,bdgdiff,filterdup,predictd,pileup,randsample,refinepeak}"
    ##  [3] "             ..."                                                                                                              
    ##  [4] ""                                                                                                                              
    ##  [5] "macs2 -- Model-based Analysis for ChIP-Sequencing"                                                                             
    ##  [6] ""                                                                                                                              
    ##  [7] "positional arguments:"                                                                                                         
    ##  [8] "  {callpeak,bdgpeakcall,bdgbroadcall,bdgcmp,bdgopt,cmbreps,bdgdiff,filterdup,predictd,pileup,randsample,refinepeak}"           
    ##  [9] "    callpeak            Main MACS2 Function: Call peaks from alignment"                                                        
    ## [10] "                        results."                                                                                              
    ## [11] "    bdgpeakcall         Call peaks from bedGraph output. Note: All regions on"                                                 
    ## [12] "                        the same chromosome in the bedGraph file should be"                                                    
    ## [13] "                        continuous so only bedGraph files from MACS2 are"                                                      
    ## [14] "                        accpetable."                                                                                           
    ## [15] "    bdgbroadcall        Call broad peaks from bedGraph output. Note: All"                                                      
    ## [16] "                        regions on the same chromosome in the bedGraph file"                                                   
    ## [17] "                        should be continuous so only bedGraph files from MACS2"                                                
    ## [18] "                        are accpetable."                                                                                       
    ## [19] "    bdgcmp              Deduct noise by comparing two signal tracks in"                                                        
    ## [20] "                        bedGraph. Note: All regions on the same chromosome in"                                                 
    ## [21] "                        the bedGraph file should be continuous so only"                                                        
    ## [22] "                        bedGraph files from MACS2 are accpetable."                                                             
    ## [23] "    bdgopt              Operations on score column of bedGraph file. Note: All"                                                
    ## [24] "                        regions on the same chromosome in the bedGraph file"                                                   
    ## [25] "                        should be continuous so only bedGraph files from MACS2"                                                
    ## [26] "                        are accpetable."                                                                                       
    ## [27] "    cmbreps             Combine BEDGraphs of scores from replicates. Note: All"                                                
    ## [28] "                        regions on the same chromosome in the bedGraph file"                                                   
    ## [29] "                        should be continuous so only bedGraph files from MACS2"                                                
    ## [30] "                        are accpetable."                                                                                       
    ## [31] "    bdgdiff             Differential peak detection based on paired four"                                                      
    ## [32] "                        bedgraph files. Note: All regions on the same"                                                         
    ## [33] "                        chromosome in the bedGraph file should be continuous"                                                  
    ## [34] "                        so only bedGraph files from MACS2 are accpetable."                                                     
    ## [35] "    filterdup           Remove duplicate reads at the same position, then save"                                                
    ## [36] "                        the rest alignments to BED or BEDPE file. If you use '"                                                
    ## [37] "                        --keep-dup all option', this script can be utilized to"                                                
    ## [38] "                        convert any acceptable format into BED or BEDPE"                                                       
    ## [39] "                        format."                                                                                               
    ## [40] "    predictd            Predict d or fragment size from alignment results."                                                    
    ## [41] "                        *Will NOT filter duplicates*"                                                                          
    ## [42] "    pileup              Pileup aligned reads with a given extension size"                                                      
    ## [43] "                        (fragment size or d in MACS language). Note there will"                                                
    ## [44] "                        be no step for duplicate reads filtering or sequencing"                                                
    ## [45] "                        depth scaling, so you may need to do certain pre/post-"                                                
    ## [46] "                        processing."                                                                                           
    ## [47] "    randsample          Randomly sample number/percentage of total reads."                                                     
    ## [48] "    refinepeak          (Experimental) Take raw reads alignment, refine peak"                                                  
    ## [49] "                        summits and give scores measuring balance of"                                                          
    ## [50] "                        waston/crick tags. Inspired by SPP."                                                                   
    ## [51] ""                                                                                                                              
    ## [52] "optional arguments:"                                                                                                           
    ## [53] "  -h, --help            show this help message and exit"                                                                       
    ## [54] "  --version             show program's version number and exit"                                                                
    ## [55] ""                                                                                                                              
    ## [56] "For command line options of each command, type: macs2 COMMAND -h"

``` r
pathToSalmon <- file.path(pathToConda$pathToEnvBin,"salmon")
pathToSalmon
```

    ## [1] "/Users/mattpaul/Library/r-miniconda/envs/myCondaToolSet/bin/salmon"

``` r
Salmon_help <- system(paste(pathToSalmon,"-h"),intern = TRUE)
Salmon_help
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

Acknowledgements
================

Thank you to Ji-Dung Luo and Wei Wang for testing/vignette
review/critical feedback and Ziwei Liang for their support.

Session info
============

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
    ##  [1] stats4    grid      parallel  stats     graphics  grDevices utils     datasets  methods  
    ## [10] base     
    ## 
    ## other attached packages:
    ##  [1] rmarkdown_2.3               magrittr_1.5                dplyr_1.0.2                
    ##  [4] stringr_1.4.0               ggplot2_3.3.2               CondaSysReqs_0.9.8         
    ##  [7] reticulate_1.16             MOFA_1.4.0                  MultiAssayExperiment_1.14.0
    ## [10] SummarizedExperiment_1.18.2 DelayedArray_0.14.1         matrixStats_0.56.0         
    ## [13] Biobase_2.48.0              GenomicRanges_1.40.0        GenomeInfoDb_1.24.2        
    ## [16] IRanges_2.22.2              S4Vectors_0.26.1            Rgraphviz_2.32.0           
    ## [19] graph_1.66.0                BiocGenerics_0.34.0        
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] fs_1.5.0               bitops_1.0-6           usethis_1.6.1          devtools_2.3.1        
    ##  [5] doParallel_1.0.15      RColorBrewer_1.1-2     rprojroot_1.3-2        tools_4.0.2           
    ##  [9] backports_1.1.9        R6_2.4.1               vipor_0.4.5            colorspace_1.4-1      
    ## [13] withr_2.2.0            tidyselect_1.1.0       prettyunits_1.1.1      processx_3.4.4        
    ## [17] compiler_4.0.2         cli_2.0.2              desc_1.2.0             scales_1.1.1          
    ## [21] callr_3.4.4            digest_0.6.25          XVector_0.28.0         pkgconfig_2.0.3       
    ## [25] htmltools_0.5.0        sessioninfo_1.1.1      rlang_0.4.7            rstudioapi_0.11       
    ## [29] generics_0.0.2         jsonlite_1.7.1         RCurl_1.98-1.2         GenomeInfoDbData_1.2.3
    ## [33] Matrix_1.2-18          Rcpp_1.0.5             ggbeeswarm_0.6.0       munsell_0.5.0         
    ## [37] Rhdf5lib_1.10.1        fansi_0.4.1            lifecycle_0.2.0        stringi_1.5.3         
    ## [41] yaml_2.2.1             zlibbioc_1.34.0        rhdf5_2.32.2           pkgbuild_1.1.0        
    ## [45] plyr_1.8.6             ggrepel_0.8.2          crayon_1.3.4           lattice_0.20-41       
    ## [49] cowplot_1.1.0          knitr_1.29             ps_1.3.4               pillar_1.4.6          
    ## [53] rjson_0.2.20           reshape2_1.4.4         codetools_0.2-16       pkgload_1.1.0         
    ## [57] glue_1.4.2             evaluate_0.14          remotes_2.2.0          BiocManager_1.30.10   
    ## [61] vctrs_0.3.4            foreach_1.5.0          testthat_2.3.2         gtable_0.3.0          
    ## [65] purrr_0.3.4            assertthat_0.2.1       xfun_0.17              tibble_3.0.3          
    ## [69] pheatmap_1.0.12        iterators_1.0.12       beeswarm_0.2.3         memoise_1.1.0         
    ## [73] corrplot_0.84          ellipsis_0.3.1         BiocStyle_2.16.0

References
==========
