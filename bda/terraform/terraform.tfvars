project_name = "document-processor-dba"

aws_region = "us-west-2"

env = "dev"

extensions = {
    "image jpg"=".jpg", 
    "image jpeg"=".jpeg", 
    "image png"=".png", 
    "image tiff"=".tiff", 
    "image tif"=".tif", 
    "document pdf"=".pdf"
}

bda_project_description = "Document Processor Test Project"

blueprint_schema_file = "../src/blueprints/invoice_blueprint_schema.json"

blueprint_type = "DOCUMENT"