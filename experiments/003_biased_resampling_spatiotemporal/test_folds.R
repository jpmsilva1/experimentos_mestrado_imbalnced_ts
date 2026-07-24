load("src/results/inds_df.Rdata")
ind_df <- inds_df[["BEIJno"]]
ind_df$time_char <- ind_df$time
ind_df$time <- lubridate::ymd_hms(ind_df$time)
time.ids <- sort(unique(ind_df[["time"]]))
t.folds <- cut(seq_len(NROW(time.ids)), breaks=10, labels=FALSE)
names(t.folds) <- paste0("time_", time.ids)
f <- t.folds[paste0("time_", ind_df[["time"]])]
print(length(unique(f)))
print(sum(is.na(f)))
