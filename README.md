# Intelligent Document Processng on AWS

Intelligent Document Processing (IDP) is the process of automating the capture, extraction, and data categorization from documents using, in part, AI or machine learning.

As more companies move online and digitize/automate their workflows to enable scale, more companies will require IDP. In this repo, there are 2 different IDP workflows, one through Textract and one through Bedrock/Claude.

## Pre-requisites:
1- AWS account.   
2- AWS credential set up.   
3- Terraform. 

## Deployment:

### Textract Stack:

The Textract stack and code is found in the `textract_A2I` folder.  
`cd textract_A2I` and follow the README in that folder to deploy the system.  
Do not forget to `terraform destroy` to delete the stack once you are done with it.


### Bedrock Data Automation Stack:

The Bedrock Data Automation stack and code is found in the `bda` folder.  
`cd bda ` and follow the README in that folder to deploy the system.  
Do not forget to `terraform destroy` to delete the stack once you are done with it.

### Bedrock LLM Text Stack:

The Bedrock LLM Text stack and code is found in the `genai_txt` folder.  
`cd genai_txt` and follow the README in that folder to deploy the system.  
Do not forget to `terraform destroy` to delete the stack once you are done with it.


### Bedrock LLM image Stack:

The Bedrock LLM image stack and code is found in the `genai_img` folder.  
`cd genai_img` and follow the README in that folder to deploy the system.  
Do not forget to `terraform destroy` to delete the stack once you are done with it.



## Differences:

Run all solutions and note differences in output and cost.

