
# Limpiar environment
rm(list=ls())

# Librerías
library(tidyverse)
library(openalexR)
library(rcrossref)

# Determinar ubicación de las carpetas
folder <- "D:/GitHub/publications-database/"

directory_code <- paste0(folder,"code/")
directory_data <- paste0(folder,"data/")
directory_output <- paste0(folder,"output/")

# 1: Importar datos
source(paste0(directory_data,"99 Create fictional data frame.R"))
head(publications)

# 2: Crear un identificador para los datos
number_of_rows <- dim(publications)[1]

publications1 <- publications %>%
  mutate(ID=1:number_of_rows) %>%
  relocate(ID)

head(publications1)



