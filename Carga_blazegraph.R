# ==============================================================================
# SCRIPT DE CONEXIÓN R - BLAZEGRAPH
# ==============================================================================

# 1. CARGA DE LIBRERÍAS
if(!require(SPARQL)) {
  install.packages("SPARQL")
}
library(SPARQL)

# 2. CONFIGURACIÓN DEL ENDPOINT 
# Ahora apunta a 'pd_esd'
nombre_namespace <- "pd_esd" 
endpoint <- paste0("http://dayhoff.inf.um.es:3035/blazegraph/namespace/", nombre_namespace, "/sparql")

# Imprimimos la URL para verificar que queda bien:
print(paste("Conectando a:", endpoint))

# 3. CONSULTA DE PRUEBA (CONTAR TRIPLETAS)
consulta_query <- "
  SELECT (COUNT(*) AS ?totalTripletas)
  WHERE {
    ?s ?p ?o .
  }
"

# 4. EJECUCIÓN
# Si todo va bien, esto tardará menos de 1 segundo
datos <- SPARQL(url = endpoint, query = consulta_query)

# 5. VER RESULTADOS
if(length(datos$results) > 0) {
  print("¡Conexión exitosa!")
  print(paste("Número total de tripletas encontradas:", datos$results$totalTripletas))
} else {
  print("Conexión realizada, pero no se recibieron resultados. Verifica si el grafo está vacío.")
}