
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

sort(unique(mydata_openalexr$doi))

# Como vemos, aquí el DOI se reporta con https://doi.org/ antes, cosa que no nos sirve
# Nuestras opciones son: o agregar el texto previo a la versión del data frame 'publications';
# o quitar el texto adicional a la versión de OpenAlexR
# Las dos son opciones válidas
# Aquí quitaremos el texto previo de OpenAlexR

mydata_openalexr1 <- mydata_openalexr %>%
  mutate(doi=str_extract(doi,"\\d.*$")) %>% # recuperar sólo lo que corresponde al primer número y lo que viene después
  mutate(doi=tolower(doi)) # asegurarnos que todo quede en minúsculas

sort(unique(mydata_openalexr1$doi))

# Renombramos las columnas con prefijo, excluyendo la variable DOI
mydata_openalexr2 <- mydata_openalexr1 %>%
  rename_with( .fn = function(.x){paste0("OpenAlex_", .x)},
               .cols= -c(doi))

names(mydata_openalexr2)

# Opcional pero útil: crear la variable available_openalex
mydata_openalexr2 <- mydata_openalexr2 %>%
  mutate(available_openalex=1) # Queda un paso pendiente que debemos completar más adelante

# Aplicar left_join
publications1 <- left_join(publications,mydata_openalexr2,by="doi")

table(publications1$available_openalex)

# El data frame tiene 11 observaciones y 9 valores en available_openalex,
# por lo que left_join() funcionó bien

# Agregamos el valor 0 en available_openalex
publications2 <- publications1 %>%
  mutate(available_openalex=replace_na(available_openalex,0))

table(publications2$available_openalex)

cat("####OPENALEXR DATA SUCCESFULLY RETRIEVED####")

# Guardar base de datos
saveRDS(publications2,paste0(directory_output,"2 Data Retrieved from OpenAlex.rds"))
