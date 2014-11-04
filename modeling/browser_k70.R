library(dfrtopics)

root <- "/Users/agoldst/Documents/signs-model/"
model_dir <- "/Users/agoldst/Documents/signs-model/model_k70"
metadata <- read_metadata(file.path(root,c("data/20140827/citations.tsv",
                                           "scrape_txt/citations.tsv")))

dt_most <- read.csv(file.path(model_dir, "doc_topics.csv"))
dt39.4 <- read.csv(file.path(model_dir, "signs_39.4.doc_topics.csv"))

doc_topics <- rbind(dt_most,dt39.4)

export_browser_data(out_dir=model_dir,
                    metadata=metadata,
                    doc_topics=doc_topics)



