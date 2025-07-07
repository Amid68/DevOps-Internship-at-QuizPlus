module "dev_file" {
    source      = "./modules/text-file"
    filename    = "dev.txt"
    content     = "Hello, World!\n"
    path        = "./output/dev"
}

module "prod_file" {
    source      = "./modules/text-file"
    filename    = "prod.txt"
    content     = "Hello, World!\n"
    path        = "./output/prod"
}
