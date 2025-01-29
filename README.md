# azure-terraform-datapipeline

### Problem Statement : 
    Ensure the Group of Hospitals Provide Quality care while Staying Financially Active  
    

## Tech Stack :
     Azure SQL DB | ADF | ADLS Gen2 | DataBricks | Delta Lake | Azure Key Vault | Github Actions | Terraform | WIP - Airflow | Helm | Docker | Kubernetes | KubeCtl

     
### Objective :
    To Automate Resource Creation for End-To-End Pipeline  (My Previous Project https://github.com/Vijaykrishna94/azure_rcm_project)

### The Arch Diagram :


  ![terraform-project drawio](https://github.com/user-attachments/assets/830c07b3-07f5-4b36-9ec4-55ed64e6bb1b)

     

### Setup
    - Create An Azure Account And a Resource Group For Terraform
    - Download and Install AZ CLI In Local
    - In order for the Git to Interact with Azure RM 
            - A Service Principal Needs to be Created Along with A Storage Account + a Container to Store Tf States.
            - An App needs to be Registered and service principal needs to be configured which acts as an entry point for Github  in this case vj-terraform-git.
            - An OIDC Authentication Type is setup by creating Federated Creadentials 
            * For Pull Request * On Main Branch * On Production Enviroment 

            ![image](https://github.com/user-attachments/assets/5c7019a5-30b1-48a4-9088-d70bfa66f6c7)
            
     - Install Terrform CLI on Local and Cloud Shell   
     
    
