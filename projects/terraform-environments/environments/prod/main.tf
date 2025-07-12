data "terraform_remote_state" "dev" {
    backend = "local"
    config = {
        path = "../dev/terraform.tfstate"
    }
}

module "prod" {
    source      = "../../modules"
    text_files = {
        prod_file = {
            filename = "prod.txt"
            content  = data.terraform_remote_state.dev.outputs.dev_file_content
            path     = "../../output/prod"
        }
    }
}
