library(dfrtopics)

inst_dir <- "/Users/agoldst/Documents/signs-model/instances"
old_file <- file.path(inst_dir,"signs_fla_len800_stoprefs.mallet")
new_file <- file.path(inst_dir,"signs_39.4.mallet")

txt_dir <- "/Users/agoldst/Documents/signs-model/signs39_4/"

ids <- c(
    "10.1086/675722", # 39.4
    "10.1086/675538",
    "10.1086/675539",
    "10.1086/675540",
    "10.1086/675541",
    "10.1086/675736",
    "10.1086/675542",
    "10.1086/675543",
    "10.1086/675578",
    "10.1086/675544",
    "10.1086/675545",
    "10.1086/675546")
    
read_dfr_fulltext <- function(data_dir,type) {
    fv <- Sys.glob(file.path(data_dir,type,"*.txt"))
    ids <- sub(paste("^.*",type,"_",sep=""), "", fv)
    ids <- sub("\\.txt$", "", ids)
    ids <- sub("_", "/", ids)

    texts <- character(length(ids))

    for (j in seq_along(fv)) {
        texts[j] <- paste(readLines(fv[j],warn=F),collapse=" ")
        if (j %% 100 == 0) {
            message("Read ",j," files")
        }
    }

    # rejoin hyphenation as in dfr_tokenize.py
    texts <- gsub("-\\s+","",texts,perl=T)

    # eliminate injected LaTeX; otherwise usepackage is a topic key word
    texts <- gsub("\\\\[\\w}{,\\[\\]]+","",texts,perl=T)

    data.frame(id=ids,text=texts,stringsAsFactors=F)
}

old_insts <- read_instances(old_file)
mallet_pipe <- old_insts$getPipe()

new_insts <- .jnew("cc/mallet/types/InstanceList",
                   .jcast(mallet_pipe, "cc/mallet/pipe/Pipe"))


docs <- read_dfr_fulltext(txt_dir, "ocr")

stopifnot(all(ids %in% docs$id) && all(docs$id %in% ids))

for (j in seq_along(docs$id)) {
    J("cc/mallet/topics/RTopicModel")$addInstance(new_insts,
                                                  docs$id[j],
                                                  docs$text[j])
}

write_instances(new_insts,new_file)

