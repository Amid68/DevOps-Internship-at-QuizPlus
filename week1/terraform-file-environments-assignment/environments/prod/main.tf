module "prod" {
    source      = "../../modules"
    text_files = {
        prod_file = {
            filename = "prod.txt"
            content  = "Hello, World!\n"
            path     = "../../output/prod"
        }
    }
}
