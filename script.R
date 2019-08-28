# install.packages("SparkR")
# install.packages("tidyr")

library("SparkR")
library("tidyr")

# Check do ambiente se existe spark
if (nchar(Sys.getenv("SPARK_HOME")) < 1) {
  Sys.setenv(SPARK_HOME = "/home/spark")
}
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "2g"))

# Organiza os dados de forma a virar um data.frame
arrangeData <- function(info) {
  
  firstFilter <- data.frame(lapply(info, function(x) {
    gsub(" - - ", " ", x)
  })
  )
  
  secondFilter <- data.frame(lapply(firstFilter, function(x) {
    gsub(" -", "", x)
  })
  )
  
  thirdFilter <- data.frame(lapply(secondFilter, function(x) {
    gsub("\"", "", x)
  })
  )
  
  fourthFilter <- data.frame(lapply(thirdFilter, function(x) {
    gsub("GET ", "GET", x)
  })
  )
  
  fifthFilter <- data.frame(lapply(fourthFilter, function(x) {
    gsub(" HTTP", "HTTP", x)
  })
  )
  
  names(fifthFilter) <- c("columnIndex")
  nasaRDFSep <- separate(fifthFilter, columnIndex, c("host","timestamp","request","return","bytes"), sep = " ")
  
}

# Le o arquivo instanciado local
nasaDF <- data.frame(read.csv("C:\\Users\\luiz.fernandes\\Desktop\\Dados\\NASA_access_log_Aug95.gz"))

# Aplica a função de arrangeData na massa de dados
testefunctiondata <- arrangeData(nasaDF)

# Devolve o arquivo no formato dataframe para o diretorio
write.csv(testefunctiondata , "C:\\Users\\luiz.fernandes\\Desktop\\Dados\\teste.csv")

# cria sessão
sconn <- sparkR.session(master = "local")

# le o arquivo do diretorio com formato S4
nasaRDF <- read.df("C:\\Users\\luiz.fernandes\\Desktop\\Dados\\teste.csv", source = "csv", header="true", inferSchema = "true")

# Cria temporaria para fazer as consultas
createOrReplaceTempView(nasaRDF, "nasaRDF")

# Numero de hosts unicos
uniqueHostsCount <- sql("select count(distinct hosts) as hosts_unicos from nasaRDS")

# total de error 404
errorCount <- sql("select count(*) as errors from nasaRDS where response = '404' ")

# Os 5 URLS que mais causaram erro 404
topErrorsUrls <- sql("select host as URL, count(return) as nr_errors from nasaRDS where 1=1 group by host order by count(response) desc limit 5")

# Quantidade de erros 404 por dia
dailyErrors <- sql("select extract( 'day' from timestamp::date) as dia, count(return) as nr_errors from nasaRDS where 1=1 group by timestamp::date limit 5")

# O Total de bytes retornados
totalReturnedBytes <- sql("select sum(bytes) from nasaRDS where 1=1")



