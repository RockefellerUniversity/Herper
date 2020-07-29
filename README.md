Introduction
============

The CondaSysReqs package offers a simple toolset to install and manage
Conda environments from R using the the **install\_CondaTools** and
**install\_CondaSysReqs** functions.

Installation
============

Use the `BiocManager` package to download and install the package from
our Github repository:

    if (!requireNamespace("BiocManager", quietly = TRUE))
        install.packages("BiocManager")
    BiocManager::install("https://github.com/RockefellerUniversity/CondaSysReqs")

Once installed, load it into your R session:

    library(CondaSysReqs)

Simple install Conda Environment from R console using **install\_CondaTools**.
==============================================================================

The **install\_CondaTools()** function allows the user to specify
required Conda software and the desired environment to install into.

Miniconda is installed as part of the process (by default into the
r-reticulate’s default Conda location).

    install_CondaTools("salmon","myCondaToolSet")

    ## $pathToConda
    ## [1] "/Users/thomascarroll/Library/r-miniconda/bin/conda"
    ## 
    ## $environment
    ## [1] "myCondaToolSet"
    ## 
    ## $pathToEnvBin
    ## [1] "/Users/thomascarroll/Library/r-miniconda/envs/myCondaToolSet/bin"

We can add additional tools to our Conda environment by specifying
*updateEnv = TRUE*.

    pathToConda <- install_CondaTools("macs2","myCondaToolSet",updateEnv = TRUE)
    pathToConda

    ## $pathToConda
    ## [1] "/Users/thomascarroll/Library/r-miniconda/bin/conda"
    ## 
    ## $environment
    ## [1] "myCondaToolSet"
    ## 
    ## $pathToEnvBin
    ## [1] "/Users/thomascarroll/Library/r-miniconda/envs/myCondaToolSet/bin"

Although we will not activate the environment, many tools can be used
straight from the Conda environment’s bin directory.

    pathToMacs <- file.path(pathToConda$pathToEnvBin,"macs2")
    pathToMacs

    ## [1] "/Users/thomascarroll/Library/r-miniconda/envs/myCondaToolSet/bin/macs2"

    Macs_help <- system(paste(pathToMacs,"-h"),intern = TRUE)
    Macs_help

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

    pathToSalmon <- file.path(pathToConda$pathToEnvBin,"salmon")
    pathToSalmon

    ## [1] "/Users/thomascarroll/Library/r-miniconda/envs/myCondaToolSet/bin/salmon"

    Salmon_help <- system(paste(pathToSalmon,"-h"),intern = TRUE)
    Salmon_help

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
