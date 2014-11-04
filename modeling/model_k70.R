options(java.parameters="-Xmx2g")
.libPaths("/spare2/ag978/R/x86_64-pc-linux-gnu-library")

library(dfrtopics)

data_dir <- "/spare2/ag978/signs/"
save_model <- F
save_browser_data <- F

n_topics <- 70L

m <- list(
    metadata=read_metadata(file.path(data_dir,c("20140827/citations.tsv",
                                                 "scrape_txt/citations.tsv"))),
    seed=243L
)
m$trainer <- train_model(file.path(data_dir,"signs_fla_len800_stoprefs.mallet"),
    n_topics=n_topics,
    n_iters=600,
    threads=2L,
    seed=m$seed
)

if (save_model) {
    output_model(m,
        output_dir=file.path(data_dir,"model_k70")
    )
}
    
if (save_browser_data) {
    export_browser_data(
        file.path(data_dir,"model_k70"),
        m$metadata
    )
}


message("Modeling complete. Saving inferencer...")
inf <- m$trainer$model$getInferencer()
fos <- .jnew("java/io/FileOutputStream", file.path(data_dir, "model_k70",
                                                   "inf.jobj"))
oos <- .jnew("java/io/ObjectOutputStream", .jcast(fos, "java/io/OutputStream"))
oos$writeObject(inf)
oos$close()

message("Loading Signs 39.4 instances...")
sampling_interval <- 10L # aka "thinning"
burn_in <- 10L
n_iterations <- 100L

new_insts <- read_instances(file.path(data_dir, "signs_39.4.mallet"))
iter <- new_insts$iterator()

message("Inferring topics for 39.4...")

dt_new <- matrix(nrow=new_insts$size(),ncol=m$trainer$model$numTopics)
for (j in 1:new_insts$size()) {
    inst <- .jcall(iter,"Ljava/lang/Object;","next")
    dt_new[j, ] <- inf$getSampledDistribution(inst, n_iterations,
                                              sampling_interval, burn_in)
    dt_new[j, ] <- round(dt_new[j, ] * inst$getData()$size())
}

message("Saving inferred document topics...")

colnames(dt_new) <- paste("topic",1:ncol(dt_new),sep="")
write.table(data.frame(dt_new, id=instances_ids(new_insts)),
            file.path(data_dir, "signs_39.4.doc_topics.csv"),
            quote=F,sep=",",row.names=F,col.names=T)

message("Done.")
