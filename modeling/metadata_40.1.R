library(dplyr)

out_file <- "/Users/agoldst/Documents/signs-model/scrape_txt/citations.tsv"

metadata_40.1 <- function () {
    # scraped text metadata created by exporting 40.1 citations as RIS from jstor,
    # removing the header,
    # running my mlaib2014/aggregate.py on them 
    
    ris40.1 <- read.csv(
        "/Users/agoldst/Documents/signs-model/data/40.1/citations.ris.csv",
        as.is=T)
    stopifnot(all(ris40.1$Y1 == "2014/09/01"))
    meta40.1 <- ris40.1 %>%
        mutate(bk_review=grepl("ArticleType: book-review",M1)) %>%
        mutate(other_type=grepl("ArticleType: other",M1) |
               (TI == "About the Contributors"))
    meta40.1 <- meta40.1 %>% 
        mutate(id=DO,
               doi=DO,
               title=TI,
               author=gsub(",,",",",AU), # correct glitch; more below
               journaltitle=JO,
               volume=VL,
               issue=IS,
               pubdate="2014-09-01T00:00:00Z",
               pagerange=paste("pp. ",SP,"-",EP,sep=""),
               publisher="",
               type=ifelse(bk_review | other_type,"whatevs","fla"),
               reviewed.work="",
               abstract=AB) %>%
        select(id, doi, title, author, journaltitle, volume, issue, pubdate,
               pagerange, publisher, type, reviewed.work, abstract)

    auth <- strsplit(meta40.1$author,";;")
    auth <- sapply(lapply(auth,function (s) gsub("(.*), (.*)","\\2 \\1",s)),
                   paste,collapse=", ")
    meta40.1$author <- auth

    meta40.1
}

write.table(metadata_40.1(),out_file,quote=F,sep='\t',row.names=F)

# simulate bone-headed trailing tab
ll <- readLines(out_file)
ll[-1] <- paste(ll[-1],"\t",sep="")
writeLines(ll,out_file)
