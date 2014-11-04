library(stringr)
library(dfrtopics)
library(RJSONIO)
library(dplyr)

setwd("/Users/agoldst/Documents/signs-model")

# model_dir <- "model65_fla_800"
#model_dir <- "model_k65_fla_len800_stoprefs"
model_dir <- "model_k70"
# data_dir <- "data"
# citations_file <- file.path(data_dir,"citations.CSV")
data_dir <- "data/20140827"
citations_file <- c(file.path(data_dir,"citations.tsv"),
                    "scrape_txt/citations.tsv")

# backup source files

meta_file <- "browser/data/meta.csv.zip"
info_file <- "browser/data/info.json"

file.copy(meta_file,"meta.csv.zip.bak")
file.copy(info_file,"info.json.bak")

m <- read_metadata(citations_file)

ids <- c(readLines(file.path(model_dir,"id_map.txt")),
         read.csv(file.path(model_dir,"signs_39.4.doc_topics.csv"),
                  as.is=T)$id)


i_md <- match(ids,m$id)
m <- m[i_md,]

# keep only unneeded columns
keep_cols <- c("id","title","author","journaltitle","volume","issue",
               "pubdate","pagerange")
m <- m[,keep_cols]


# correct the dates

#contents <- read.csv("contents.csv")
#contents <- tbl_df(contents[-398,])
#if (any(is.na(contents$Vol) | is.na(contents$No))) {
#    stop("NA values in Vol/No")
#}
#issues <- str_c(contents$Vol,"_",contents$No)
#
## one item has missing information, which we'll drop
#check_dates <- contents %>% group_by(Vol,No) %>%
#    summarize(tally=n_distinct(Date.1))
#stopifnot(all(check_dates$tally==1))

#date_lookup <- dates$date
#names(date_lookup) <- dates$issue
#
#date_keys <- str_c(m$volume,"_",m$issue)
#m$pubdate <- date_lookup[date_keys]

# Add special issue column

# read special issue information
specials <- read.csv("specials.csv",as.is=T)
special_keys <- str_c(specials$VOLUME,"_",specials$ISSUE) 

info_obj <- fromJSON(info_file)
info_obj$issues <- matrix(c(special_keys,
                            specials$SPECIAL.ISSUE.TITLE,
                            str_trim(specials$JSTOR.LINK)),
                          ncol=3)


# keys to index into special_keys for each doc:
issue_keys <- str_c(m$volume,"_",m$issue)

# but 5.3S is 5.3 as far as jstor knows, but with S page numbers:

issue_keys[m$volume == 5 & m$issue == 3
           & grepl("S",m$pagerange,fixed=T)] <- '5_3S'

# and correct the issue number itself
m$issue[issue_keys == "5_3S"] <- "3S"

# and 1.3S is not annotated in jstor metadata (yet JSTOR knows the
# difference between the two issues somehow?)
# so instead we can use the fact that 1.3 has page numbers 585-808
# whereas 1.3S has page numbers 1-317
# actually this is tricky because both issues have roman-numeral prefatory 
# matter, but we'll get away with it because none of the prefaces and 
# editorials made it into our document set.

is_13s <- function (pp) {
    num_match <- str_match(pp,"p\\. (\\d+)")[,2]
    ifelse(is.na(num_match),F,as.numeric(num_match) < 400)
}

issue_keys[m$volume == 1 & m$issue == 3
           & is_13s(m$pagerange)] <- "1_3S"

# and correct the issue number itself
m$issue[issue_keys == "1_3S"] <- "3S"

m$special <- ifelse(issue_keys %in% special_keys,issue_keys,"")

# verify match on existing metadata file

m_check <- read.csv(unz(meta_file,"meta.csv"),header=F,
                    as.is=T)

# skip the issue column (which we've changed)
# and the rightmost column (pubtype in the old data, dropped here;
# special in the new data, not in old data)
# if the original file has the new column 10 (abstract), ignore that too
if (ncol(m_check == 10)) {
    skipcol <- c(6,9,10)
} else {
    skipcol <- c(6,9)
}

if (!isTRUE(all.equal(m_check[,-skipcol],m[,-skipcol],
                      check.attributes=F))) {
    stop("mismatch between old metadata file and new")
}

message("Overwriting ",info_file)
writeLines(toJSON(info_obj, pretty=T),info_file)

# output csv file in the expected zipped format

f_temp <- file.path(tempdir(),"meta.csv")
write.table(m,f_temp,
            quote=T,sep=",",
            col.names=F,row.names=F,
            # d3.csv.* expects RFC 4180 compliance
            qmethod="double")

unlink(meta_file)
message("Overwriting ",meta_file)
status <- zip(meta_file,f_temp,flags="-9Xj")
stopifnot(status == 0)
