# Week 10 — CloudFormation 

## Required Homework
Following the live-streamed vide0 on week 10 about CloudFormation(CFN), I was able to complete the required tasks.


create a file called `template.yaml`  under the `aws/cfn` 

```yaml
AWSTempleteFormatVersion: 2010-09-09
Description: |
    Setup ECS Cluster

Resources:
  ECSCluster: #Logical Name 
    Type: 'AWS::ECS::Cluster'
    Properties:
        ClusterName: MyCluster
        CapacityProviders:
            - FARGATE
#Parameters:
#Mappings:
#Resources:
#Outputs:
#Metadata
```


Install cfn lint using the following command
```bash
pip install cfn-lint
```

and also add into `gitpod.yml` file.

```yaml
- name: CFN
    before: |
      pip install cfn-lint
      cargo install cfn-guard
```

Create a `task-definition.guard` under the `aws/cfn`

```guard
aws_ecs_cluster_configuration {
  rules = [
    {
      rule = "task_definition_encryption"
      description = "Ensure task definitions are encrypted"
      level = "error"
      action {
        type = "disallow"
        message = "Task definitions in the Amazon ECS cluster must be encrypted"
      }
      match {
        type = "ecs_task_definition"
        expression = "encrypt == false"
      }
    },
    {
      rule = "network_mode"
      description = "Ensure Fargate tasks use awsvpc network mode"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must use awsvpc network mode"
      }
      match {
        type = "ecs_task_definition"
        expression = "network_mode != 'awsvpc'"
      }
    },
    {
      rule = "execution_role"
      description = "Ensure Fargate tasks have an execution role"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must have an execution role"
      }
      match {
        type = "ecs_task_definition"
        expression = "execution_role == null"
      }
    },
  ]
}

```


To install cfn-guard 
```bash
cargo install cfn-guard
```

launch the following command
```bash
cfn-guard rulegen --template /workspace/aws-bootcamp-cruddur-2023/aws/cfn/template.yaml
```

it will give the following result
```
let aws_ecs_cluster_resources = Resources.*[ Type == 'AWS::ECS::Cluster' ]
rule aws_ecs_cluster when %aws_ecs_cluster_resources !empty {
  %aws_ecs_cluster_resources.Properties.CapacityProviders == ["FARGATE"]
  %aws_ecs_cluster_resources.Properties.ClusterName == "MyCluster"
}
```

copy the following code and create a file called `ecs-cluster.guard` under `aws/cfn`

and run the following command
```
cfn-guard validate -r ecs-cluster.guard
```


## CFN Networking Layer

I was able to create a Networking Template yaml file and a config toml file, for the purpose of implementing and identifying the Networking Stack in AWS Cloudformation. Furtheremore, I was able to create a network bash script to deploy the networking stack into CloudFormation.
Here is the proof of 

[Templatefile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/networking/template.yaml)

[ConfigTomlfile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/networking/config.toml)

[Bashscript](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/bin/cfn/networking)




### CFN Cluster Layer
I was able to create a Cluster Template yaml file and a config toml file, for the purpose of implementing and identifying the Cluster Stack in AWS Cloudformation. Furtheremore, I was able to create a cluster bash script to deploy the cluster stack into CloudFormation.

[Templatefile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/cluster/template.yaml)

[ConfigTomlfile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/cluster/config.toml)

[Bashscript](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/bin/cfn/cluster)



### CFN Service Layer for Backend
I was able to create a Backend Template yaml file and a config toml file, for the purpose of implementing and identifying the Backend Stack in AWS Cloudformation. Furtheremore, I was able to create a backend bash script to deploy the backend stack into CloudFormation.

[Templatefile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/service/template.yaml)

[ConfigTomlfile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/service/config.toml)

[Bashscript](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/bin/cfn/service)




## CFN RDS Layer
I was able to create a Database Template yaml file and a config toml file, for the purpose of implementing and identifying the Database Stack in Cloudformation. Furtheremore, I was able to create a Database Bash script to deploy the stack to AWS Cloudformation


[Templatefile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/db/template.yaml)

[ConfigTomlfile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/db/config.toml)

[Bashscript](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/bin/cfn/db)




### CFN Continuous Integration and Continuous Deployment (CICD) Layer
I was able to create a CICD Template yaml file and also a nested codebuild yaml file and a config toml file, for the purpose of implementing and identifying the CICD Stack in Cloudformation. I also create a CICD Bash script to deploy the stack to AWS Cloudformation.

[Templatefile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/cicd/template.yaml)

[ConfigTomlfile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/cicd/config.toml)

[Bashscript](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/bin/cfn/cicd)



### CFN DynamoDB using Serverless Application Model (SAM)

install the SAM packages to our `gitpod.yml`
```sh
 - name: aws-sam
    init: |
      cd /workspace
      wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
      unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
      sudo ./sam-installation/install
      cd $THEIA_WORKSPACE_ROOT
```

I was able to create a DynamoDb Template yaml file and a config toml file, for the purpose of implementing and identifying the DynamoDb Stack in Cloudformation. I also create a DynamoDb Bash script to deploy the stack to AWS Cloudformation.


[Templatefile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/ddb/template.yaml)

[ConfigTomlfile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/ddb/config.toml)

[Bashscript](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/bin/cfn/ddb)






### CFN Static Website Hosting for Frontend
I was able to create a Frontend template yaml file, alongside a config toml file for the purpose of implementing and identifying the Frontend Stack in Cloudformation. I also create a Frontend Bash script to deploy the stack to AWS Cloudformation.

[Templatefile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/frontend/template.yaml)

[ConfigTomlfile](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/cfn/frontend/config.toml)

[Bashscript](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/bin/cfn/frontend)



### All Cloudformation Stacks Deployed Successfully
Here is a screenshot showing that all the Cloudformation Stacks that were implemented successfully and deployed in Cloudformation.

![Image of Successful Deploy](assets/week%2010/CloudFormation.png)




