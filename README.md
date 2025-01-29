# azure-terraform-datapipeline

### Problem Statement : 
    Quickly Setup/Orchestrate a Data Pipeline by leveraging IAC to Ensure the Group of Hospitals Provide Quality care while Staying Financially Active  
    

## Tech Stack :
     Azure SQL DB | ADF | ADLS Gen2 | DataBricks | Delta Lake | Azure Key Vault | Github Actions | Terraform | WIP - Airflow | Helm | Docker | Kubernetes | KubeCtl

     
### Objective :
    To Automate Resource Creation for End-To-End Pipeline  (My Previous Project https://github.com/Vijaykrishna94/azure_rcm_project)

### The Arch Diagram :


 ![terraform-project drawio](https://github.com/user-attachments/assets/b89d76ac-43e0-45dd-86ce-3447da5fafd5)

     

### Setup

    - Create An Azure Account And a Resource Group For Terraform
    - Download and Install AZ CLI In Local
    - Create A Github Repo maintain and Deploy the Code
    - In order for the Git to Interact with Azure RM 
            - A Service Principal Needs to be Created Along with A Storage Account + a Container to Store Tf States.
            - An App needs to be Registered and service principal needs to be configured which acts as an entry point for Github  in this case vj-terraform-git.
            - Save The ClientID, TenantID and subsricption ID (So that we can pass them as ENV Secrets on Git)
            - An OIDC Authentication Type is setup by creating Federated Credentials 
            * For Pull Request * On Main Branch * On Production Enviroment 

 ![image](https://github.com/user-attachments/assets/34b1140e-8174-4a7f-a37c-320dbf72ba3b)


            - Configure the following API permissions -   (Basically read and write  Application and directory permissions)

            
 ![image](https://github.com/user-attachments/assets/23955051-c57f-41e3-9c43-fb0fc90e09be)
 ![image](https://github.com/user-attachments/assets/c60e1a33-0f4c-4782-a05e-139b1e8be9b7)
   
     - Install Terrform CLI on Local and Cloud Shell  
     - Setup Github Actions Workflows  Refer to #tf-plan-apply.yml
     - Now We are good lets look at the Code ....
  
### Code
#### Providers.tf
        
        
![image](https://github.com/user-attachments/assets/5ca72e2e-06c6-42a5-b16d-27ba332517c8)


    - Blocks -  Azurerm - Azure Reseouce  Manager | databricks - Databricks | azuread - Azure Active Directory | azapi - ARM Template 

        
![image](https://github.com/user-attachments/assets/42aba8db-521e-41e0-8874-fe92dc4c9401)


    - Backend Block to connect to Storage account where tf state Exists 

    - oidc is Enabled for authentication 

#### variables.tf

        
![image](https://github.com/user-attachments/assets/b8d710cd-3b80-4309-b521-fb6a7b28c138)
        

    - This Module Consists of variables blocks that are used parametrize resource names/Cluster Configuration and other Params

#### main.tf

         
![image](https://github.com/user-attachments/assets/e3c8d35a-f6d2-4832-a9f4-52c3f03dbff1)
         

    - This module consists of all the resources we want to spin of - Basically a bird eye View of all the resources  - Resource Group | Storage Accounts | Adf Account | DataBricks Workspace

![image](https://github.com/user-attachments/assets/fec4be47-884a-4260-b3a0-8a2545f7629c)


### sp.tf


![image](https://github.com/user-attachments/assets/1d42c0dc-7383-4e1d-80b6-32ca3eafdeca)

    - Respective App Registrations and Service Principals are created for the resources that are spinned up  
    - These Sp's are utilized while setting up access policies to the Secrets in Key Vault

![image](https://github.com/user-attachments/assets/4d2bc7de-7165-4f17-b4d9-b6b532929d29)




#### sqldb.tf


![image](https://github.com/user-attachments/assets/8b4e520e-fcb7-4fe2-b316-cabe86cf8212)

    - An Sql Server and Sql Db's are setup 
    

#### adf.tf

   **Linked Services**
   

![image](https://github.com/user-attachments/assets/cd09bdf1-87a3-470e-a939-9f63e0a6ffc6)



    - 5 Linked Services are Created and their respective Secret'names are Provided

    - Delta Table LS to acces Audit table which has information about updated time , type of load etc....

    - Rest Must be self explanaratory 



![image](https://github.com/user-attachments/assets/d350f0e6-dc52-4fd5-80f9-aa97a32a0346)


    
   **DataSets**

    
![image](https://github.com/user-attachments/assets/421ca2ed-e1e9-4565-925d-0c59d3f9e0f2)



    
    - Pipeline Parameters are passed by reading Config File from adls config folder



    
![image](https://github.com/user-attachments/assets/041249f3-ba90-4531-aa1d-680654ced66a)

    

   **Pipelines** 

    
![image](https://github.com/user-attachments/assets/482ffd2d-5b63-4b98-bcf0-5d8fa6bb1074)

 
    
    - Pipelines are setup using `resource "azurerm_data_factory_pipeline"` and ARM Templates



![image](https://github.com/user-attachments/assets/3a6400b2-97e1-4ad5-95b7-49cfc86bdc75)



### adb.tf



![image](https://github.com/user-attachments/assets/e697e399-d98b-4971-bc3d-905c277f66cd)

   
      

    - Along With Cluster Configuration a PAT is also created which will be used by the ADF to sping up the cluster

     


![image](https://github.com/user-attachments/assets/a2a0c84d-9f4d-45d8-810f-b1f0f3afffae)




#### Notebooks.tf




 ![image](https://github.com/user-attachments/assets/f34c22bc-49fd-4f2b-929e-9cf11377a6c7)


    

    
    - Through this module all the ETL Code base including  setup/mounts/silver/gold queries  [.py files - scala/sql/pyspark] are deployed on workspace of adb account

    


![image](https://github.com/user-attachments/assets/00f30bda-db53-4e8a-8d7b-0fa844339bb6)





### kv.tf



![image](https://github.com/user-attachments/assets/33fc59a0-829a-4eeb-9692-1d01edb66c99)





    - A standard Key Vault is setup and access policies are defined for the current service principal (vj-terraform-git)

    - Access Policies are also set for adf,adb,adls Sp's for the level permissions

    - Secrets are securely created and migrated for accessing adls,adb and sqldb

    



     

      


    

    
    


        

    
