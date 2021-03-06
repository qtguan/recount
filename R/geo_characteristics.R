#' Build a data.frame from GEO's charactersitics for a given sample
#'
#' This function builds a data.frame from the GEO characteristics extracted
#' for a given sample. The names of the of columns correspond to the field
#' names. For a given SRA project, this information can be combined for all
#' samples as shown in the examples section.
#'
#' @param pheno A [DataFrame-class][S4Vectors::DataFrame-class] as created by
#' [geo_info].
#'
#' @return A 1 row data.frame with the characteristic fields as column names
#' and the values as the entries on the first row. If the authors of the study
#' used the same names for all samples, you can then combine them using
#' [rbind][base::cbind].
#'
#' @author Leonardo Collado-Torres
#' @export
#'
#' @import S4Vectors
#'
#' @examples
#'
#' ## Load required library
#' library("SummarizedExperiment")
#'
#' ## Get the GEO accession ids
#' # geoids <- sapply(colData(rse_gene_SRP009615)$run[1:2], find_geo)
#' ## The previous example code works nearly all the time but it
#' ## can occassionally fail depending on how rentrez is doing.
#' ## This code makes sure that the example code runs.
#' geoids <- tryCatch(
#'     sapply(colData(rse_gene_SRP009615)$run[1:2], find_geo),
#'     error = function(e) {
#'         c(
#'             "SRR387777" = "GSM836270",
#'             "SRR387778" = "GSM836271"
#'         )
#'     }
#' )
#'
#' ## Get the data from GEO
#' geodata <- do.call(rbind, sapply(geoids, geo_info))
#'
#' ## Add characteristics in a way that we can access easily later on
#' geodata <- cbind(geodata, geo_characteristics(geodata))
#'
#' ## Explore the original characteristics and the result from
#' ## geo_characteristics()
#' geodata[, c("characteristics", "cells", "shrna.expression", "treatment")]
geo_characteristics <- function(pheno) {
    ## Check inputs
    stopifnot("characteristics" %in% colnames(pheno))

    if (is.character(pheno$characteristics)) {
        ## Solves https://support.bioconductor.org/p/116480/
        pheno$characteristics <- IRanges::CharacterList(
            lapply(lapply(pheno$characteristics, str2lang), eval)
        )
    }

    ## Separate information
    result <- lapply(pheno$characteristics, function(sampleinfo) {
        ## Check if there are colons
        if (any(!as.vector(sapply(sampleinfo, grepl, pattern = ":")))) {
            res <- data.frame(
                "characteristics" = paste(unlist(sampleinfo),
                    collapse = ", "
                ),
                stringsAsFactors = FALSE
            )
            return(res)
        }

        info <- strsplit(sampleinfo, ": ")

        ## Get variable names
        varNames <- sapply(info, "[[", 1)
        varNames <- make.names(tolower(varNames))

        ## Construct result
        res <- matrix(sapply(info, "[[", 2), nrow = 1)
        colnames(res) <- varNames
        res <- data.frame(res, stringsAsFactors = FALSE)

        ## Finish
        return(res)
    })

    ## Finish
    result <- do.call(rbind, result)
    return(result)
}
