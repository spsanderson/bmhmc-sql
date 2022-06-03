# * Run Before Upgrade ----
tmp <- installed.packages()
installedpkgs <- as.vector(tmp[is.na(tmp[,"Priority"]), 1])
save(installedpkgs, file="installed_old.rds")

# * Run After Upgrade ----
tmp <- installed.packages()
installedpkgs.new <- as.vector(tmp[is.na(tmp[,"Priority"]), 1])
load(file = "installed_old.rds")
missing <- setdiff(installedpkgs, installedpkgs.new)
install.packages(missing)
update.packages()
