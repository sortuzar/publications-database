
# Retrieving OpenAlexR data

# Limpiar environment
rm(list=ls())

# Librerías
library(tidyverse)
library(openalexR)

# Determinar ubicación de las carpetas
directory_data <- "data/"
directory_output <- "output/"

# Cargar base de datos
publications <- readRDS(paste0(directory_output,
                               "1 Data Retrieved from CrossRef.rds"))

# Hacer solicitud a OpenAlex
mydata_openalexr <- oa_fetch(
  doi = publications$doi,
  entity = "works",
  output="tibble",
#  mailto="your.mail.here@whatever.com",
  per_page=50,
  verbose = FALSE) 
