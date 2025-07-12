module "dev" {
    source      = "../../modules"
    text_files = {
        dev_file = {
            filename = "dev.txt"
            content  = "010101123Hello, World! This is a test\nNow I will test if prod recieves same content\n"
            path     = "../../output/dev"
        }
    }
}

output "dev_file_content" {
    value = module.dev.file_content
}
