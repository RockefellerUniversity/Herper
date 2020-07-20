---
title: "Intro to CondaSysReqs"
author: "BRC"
date: "7/20/2020"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Introduction

The CondaSysReqs package offers a simple toolset to install and manage Conda environments from R using the the **install_CondaTools**  and **install_CondaSysReqs** functions.

# Installation

Use the `BiocManager` package to download and install the package from our Github repository:

```{r getPackage, eval=FALSE}
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("https://github.com/RockefellerUniversity/CondaSysReqs")
```

Once installed, load it into your R session:

```{r}
library(CondaSysReqs)
```


# Simple install Conda Environment from R console using **install_CondaTools**. 

The  **install_CondaTools()** function allows the user to specify required Conda software and the desired environment to install into.

Miniconda is installed as part of the process (by default into the r-reticulate's default Conda location).

```{r}
install_CondaTools("salmon","myCondaToolSet")
```

We can add additional tools to our Conda environment by specifying *updateEnv = TRUE*.

```{r}
pathToConda <- install_CondaTools("macs2","myCondaToolSet",updateEnv = TRUE)
pathToConda
```

Although we will not activate the environment, many tools can be used straight from the Conda environment's bin directory.

```{r}
pathToMacs <- file.path(pathToConda$pathToEnvBin,"macs2")
pathToMacs
system(paste(pathToMacs,"-h"))

pathToSalmon <- file.path(pathToConda$pathToEnvBin,"salmon")
pathToSalmon
system(paste(pathToSalmon,"-h"))

```
