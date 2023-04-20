
# Limpiar environment
rm(list=ls())

# Librerías
library(tidyverse)
library(openalexR)
library(rcrossref)

# Determinar ubicación de las carpetas
directory_data <- "data/"
directory_output <- "output/"

# 1: Importar datos
source(paste0(directory_data,"99a Create fictional data frame.R"))
head(publications)

# 2: Crear un identificador para los datos
number_of_rows <- dim(publications)[1]

publications1 <- publications %>%
  mutate(ID=1:number_of_rows) %>%
  relocate(ID)

head(publications1)

# 3: Recuperar datos de CrossRef (primer intento)
# Extraemos el DOI de la base de datos como un vector
# Nos quedamos con una versión reducida de la base
publications2 <- publications1 %>%
  select(ID,notes,doi)

# Veamos cuánta información de CrossRef podemos recuperar
crossref_data <- rcrossref::cr_works(publications2$doi)
print(crossref_data[["data"]]) # El objeto se almacena como lista así que debemos acceder a él así

# Tenemos información de 8 publicaciones solamente
# 4: Intentemos empalmar la base de datos de CrossRef con la base de datos original utilizando el DOI como variable común
publications3 <- left_join(publications2,crossref_data[["data"]],by="doi")
# Vemos que el merge no funciona porque los DOIs de la base original tienen mucho textos que debiéramos limpiar antes

# 5: Limpiar la variable DOI
# Para esto limpiamos antes la variable "doi" en la base de datos original
# Para que la limpieza sea exitosa, tenemos que saber exactamente con qué problemas nos encontramos

sort(unique(publications1$doi))
# Algunos DOI están escritos con https://doi.org/, otros con http://doi.org/
# Uno dice "article" antes
# Uno empieza con un espacio en blanco
# Otro dice "DOI:" antes
# Otro dice "WOS paper" antes
# Otro dice "year-2003"
# etc.

# Podemos limpiar esto utilizando la librería "stringr" del Tidyverse
# Limpiaremos de a uno los errores para ir mostrando la función exacta de cada comando
# En la práctica, puedes hacer esto con muchas menos líneas de código
# Para esto, vamos a crear múltiples copias de la variable DOI e iremos introduciendo los cambios de a uno
publications4 <- publications2
publications4 <- publications2 %>%
  mutate(doi_A=case_when(str_detect(doi,"no doi available")~NA,
                         TRUE~doi))
# Vemos cómo cambia el caso de la fila 10: algo que estaba registrado como DOI en realidad era un string sin información
print(publications4[ , c("doi","doi_A")])

# Como los DOI solamente empiezan con números, cualquier cosa al inicio que no sea un número no corresponde
publications4 <- publications4 %>%
  mutate(doi_B=str_extract(doi_A,"\\d.*$")) # recuperar sólo lo que corresponde al primer número y lo que viene después
print(publications4[ , c("doi_A","doi_B")])
# Es mejor usar str_extract en vez de str_match en este contexto, pues str_match devuelve una matriz y no un vector

# Al eliminar "year-" en la fila 10 quedó el string "2003-" antes del inicio del DOI
publications4 <- publications4 %>%
  mutate(doi_C=str_remove(doi_B,"^2003-"))
print(publications4[ , c("doi_B","doi_C")])

# Vemos que varios DOI tienen espacios en blanco entremedio
sort(unique(publications4$doi_C))

# Podemos quitar todos los espacios en blanco que vienen después del DOI
# Para esto, cuando encontramos un espacio en blanco se elimina dicho espacio y todo lo que viene después de él
publications4 <- publications4 %>%
  mutate(doi_D=str_remove(doi_C,"\\s.*"))
print(publications4[ , c("doi_C","doi_D")])
sort(unique(publications4$doi_D)) # Aquí es más fácil de apreciar

# Vemos que la fila 8 aún tiene un texto "/WOS:" que no corresponde ahí
publications4 <- publications4 %>%
  mutate(doi_E=str_remove(doi_D,"/WOS:.*"))
print(publications4[ , c("doi_D","doi_E")])

# Como a veces los DOI están escritos con mayúsculas y a veces con minúsculas, aquí vamos a cambiar todo a minúsculas
publications4 <- publications4 %>%
  mutate(doi_F=tolower(doi_E))
print(publications4[ , c("doi_E","doi_F")])
# Vemos cambios en algunas filas, por ejemplo, la 5 y la 8
  
# 6: Recuperar datos de CrossRef (segundo intento)
crossref_data1 <- rcrossref::cr_works(publications4$doi_F)
crossref_data1_df <- crossref_data1[["data"]]
print(crossref_data1_df)
# Recuperamos los datos para todas las observaciones que contenían un DOI, aunque estuviera mal escrito

# Debemos convertir los DOI a minúsculas para que tengan el mismo formato que el otro data frame
crossref_data2_df <- crossref_data1_df %>%
  mutate(doi=tolower(doi))

# ***6a: Opcional pero útil: etiquetar todas las variables de la base de datos de CrossRef con un identificador
# Excluimos la variable DOI
crossref_data3_df <- crossref_data2_df %>%
  rename_with( .fn = function(.x){paste0("CrossRef_", .x)},
               .cols= -c(doi))

# ***6b: Opcional pero útil: crear una variable que identifique a las observaciones recuperadas por CrossRef
# (Esto es útil porque podemos hacer el mismo ejercicio con otras APIs, como OpenAlex, y así saber rápidamente la fuente de cada observación)
crossref_data4_df <- crossref_data3_df %>%
  mutate(available_crossref=1) # Queda un paso pendiente que debemos completar más adelante; ver 6b Continuación más adelante

# 7: Preparando las bases para left_join()
# Seleccionamos solo que nos interesa conservar de nuestra base original (ID, notas y el DOI más corregido que tenemos)
publications5 <- publications4 %>%
  select(ID,notes,doi_F) %>%
  rename(doi=doi_F)

# Aplicar left_join
publications6 <- left_join(publications5,crossref_data4_df,by="doi")

# ***6b Continuación: 
publications7 <- publications6 %>%
  mutate(available_crossref=replace_na(available_crossref,0))

table(publications7$available_crossref,exclude=NULL)

View(publications7)

cat("####ANALISIS COMPLETO####")

cat("# Así recuperamos la información de CrossRef para todas las filas que tenían un DOI
# y además pudimos conservar las notas y los identificadores del data frame original,
# de modo de saber cuáles textos de nuestros registros no cuentan con un identificador")

# 8: Guardar base de datos
saveRDS(publications7,paste0(directory_output,"1 Data Retrieved from CrossRef.rds"))
