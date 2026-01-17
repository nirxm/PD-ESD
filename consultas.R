# ==============================================================================
# SCRIPT DE EXPLOTACIÓN SEMÁNTICA: ENFERMEDAD DE PARKINSON
# Autor: PEDRO ANDRÉS CORTÉS MARÍN
# ==============================================================================

# 1. CARGA DE LIBRERÍAS Y CONFIGURACIÓN
if(!require(SPARQL)) { install.packages("SPARQL") }
library(SPARQL)

# Configuración del Endpoint (Asegúrate que el namespace es correcto: 'pd_esd')
nombre_namespace <- "pd_esd"
endpoint <- paste0("http://dayhoff.inf.um.es:3035/blazegraph/namespace/", nombre_namespace, "/sparql")

# Prefijos comunes para no repetirlos en cada string
prefixes <- "
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX biolink: <https://w3id.org/biolink/vocab/>
  PREFIX pd_r: <http://dayhoff.inf.um.es/graph/parkinson/resource/>
  PREFIX up: <http://purl.uniprot.org/uniprot/>
"

# ==============================================================================
# CONSULTA 1: Genes y Proteínas asociadas (Relación Genotipo-Fenotipo)
# ==============================================================================
q1 <- paste0(prefixes, "
  SELECT ?gen_label ?proteina_label ?uniprot_id
  WHERE {
    ?gen a biolink:Gene ;
         rdfs:label ?gen_label ;
         biolink:has_gene_product ?proteina .
    
    ?proteina rdfs:label ?proteina_label .
    BIND(STR(?proteina) AS ?uniprot_id) # Convierte la URI en texto para verla mejor
  }
")

print("--- Ejecutando Consulta 1: Genes y Proteínas ---")
res1 <- SPARQL(url = endpoint, query = q1)
print(res1$results)


# ==============================================================================
# CONSULTA 2: Sintomatología No Motora (Uso de FILTER)
# ==============================================================================
# Buscamos fenotipos que tengan explícitamente la categoría 'Sintoma no motor'
q2 <- paste0(prefixes, "
  SELECT ?sintoma ?etiqueta
  WHERE {
    pd_r:PD biolink:has_phenotype ?sintoma .
    ?sintoma rdfs:label ?etiqueta ;
             biolink:category ?categoria .
             
    FILTER regex(?categoria, ' no motor', 'i')
  }
")

print("--- Ejecutando Consulta 2: Síntomas No Motores ---")
res2 <- SPARQL(url = endpoint, query = q2)
print(res2$results)


# ==============================================================================
# CONSULTA 3: Mecanismos Celulares y Proteínas Implicadas (Navegación)
# ==============================================================================
# Relacionamos: Célula -> media -> Proceso -> tiene participante -> Proteína
q3 <- paste0(prefixes, "
  SELECT ?celula_nombre ?proceso_nombre ?proteina_nombre
  WHERE {
    ?proceso a biolink:PathologicalProcess ;
             rdfs:label ?proceso_nombre ;
             biolink:mediated_by ?celula .
             
    ?celula rdfs:label ?celula_nombre .
    
    # Buscamos proteínas que participen en ese proceso (camino inverso o directo)
    ?proteina biolink:participates_in ?proceso ;
              rdfs:label ?proteina_nombre .
  }
")

print("--- Ejecutando Consulta 3: Patología Celular Compleja ---")
res3 <- SPARQL(url = endpoint, query = q3)
print(res3$results)


# ==============================================================================
# CONSULTA 4: Tratamientos y Mecanismos (Uso de OPTIONAL)
# ==============================================================================
# Queremos ver TODOS los tratamientos, tengan o no mecanismo definido
q4 <- paste0(prefixes, "
  SELECT ?tratamiento ?tipo ?mecanismo
  WHERE {
    # Puede ser Drug o Procedure, buscamos cualquier cosa que 'trate' algo
    ?uri_tratamiento biolink:treats ?objetivo ;
                     rdfs:label ?tratamiento ;
                     a ?tipo .
                     
    OPTIONAL {
      ?uri_tratamiento biolink:mechanism_of_action ?mecanismo .
    }
  }
")

print("--- Ejecutando Consulta 4: Tratamientos (con Optional) ---")
res4 <- SPARQL(url = endpoint, query = q4)
print(res4$results)


# ==============================================================================
# CONSULTA 5: Estadísticas de Hallmarks (Agregación con COUNT y GROUP BY)
# ==============================================================================
# ¿Cuántas proteínas distintas participan en cada proceso patológico?
q5 <- paste0(prefixes, "
  SELECT ?proceso_patologico (COUNT(?proteina) AS ?num_proteinas)
  WHERE {
    ?proteina biolink:participates_in ?proceso .
    ?proceso a biolink:PathologicalProcess ;
             rdfs:label ?proceso_patologico .
  }
  GROUP BY ?proceso_patologico
  ORDER BY DESC(?num_proteinas)
")

print("--- Ejecutando Consulta 5: Conteo de Proteínas por Hallmark ---")
res5 <- SPARQL(url = endpoint, query = q5)
print(res5$results)