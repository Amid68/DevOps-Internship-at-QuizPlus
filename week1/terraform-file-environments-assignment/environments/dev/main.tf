module "dev" {
    source      = "../../modules"
    text_files = {
        dev_file = {
            filename = "dev.txt"
            content  = "Hello, World! This is a test\n"
            path     = "../../output/dev"
        }
    }
}

