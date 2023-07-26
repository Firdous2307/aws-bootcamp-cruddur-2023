# Week 6-7 — Deploying Containers and Solving CORS with a Load Balancer and Custom Domain

Following the live streamed Week 6-7 about Deploying containers and solving CORS with a Load Balancer and custom domain, I was able to complete the required tasks;

First we need to create a script to check if we can estabilish a connection with the RDS


Create a new file `backend-flask/bin/db/test`

```
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("PROD_CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()

```
-Make sure to chmod u+x this file for permission granted else it will be denied.

Afterwards, We create a health check of our backend-flask container and add the following code inside `app.py` 

```
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```


Create a new bin script on `bin/flask/health-check`

```
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
# This for some reason is not capturing the error....
#except ConnectionRefusedError as e:
# so we'll just catch on all even though this is a bad practice
except Exception as e:
  print(e)
  exit(1) # false
```
-Make sure to chmod u+x this file for permission granted else it will be denied.

 
Create the Cloudwatch log group. 

```
aws logs create-log-group --log-group-name "/cruddur/"
aws logs put-retention-policy --log-group-name "/cruddur/" --retention-in-days 1
```


Create the Container Registry 
```
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```

Create an ECS cluster named `cruddur`, and three ECR repos namely; `cruddur-python`, `backend-flask`, `frontend-react-js`.

Login to ECR using the following command; 
```
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"

```


Create the python repository
```
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```

Using the follwoing commands, we can set the repository.
```
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

Pull the python:3.10-slim-buster, tag the image and push to the repository in ECR
```
docker pull python:3.10-slim-buster
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
docker push $ECR_PYTHON_URL:3.10-slim-buster
```

In `dockerfile/backend-fask` change the following 
```
FROM python:3.10-slim-buster

ENV FLASK_ENV=development
````
to
```
FROM 173482565935.dkr.ecr.us-east-1.amazonaws.com/cruddur-python

ENV FLASK_DEBUG=1
```

Create the repository for the backend-flask
```
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

Using the follwoing commands, we can set the repository.
```
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```
 
Build the backend-flask image
```
docker build -t backend-flask .
```

Tag it
```
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```

Push to our repository in ECR.

```
docker push $ECR_BACKEND_FLASK_URL:latest
```



Furthermore, it is important that we need to pass the parameters to the SSM for better security practices.
```
export OTEL_EXPORTER_OTLP_HEADERS="x-honeycomb-team=$HONEYCOMB_API_KEY"
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```



Create `aws/policies/service-assume-role-execution-policy.json`
[Policy Commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/policies/service-assume-role-execution-policy.json)


Create another `aws/policies/service-execution-policy.json`
[Policy Commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/policies/service-execution-policy.json)


Then, run the following command;
```
aws iam create-role \
    --role-name CruddurServiceExecutionRole \
    --assume-role-policy-document file://aws/policies/service-assume-role-execution-policy.json
```

```
aws iam put-role-policy \
    --policy-name CruddurServiceExecutionPolicy \
    --role-name CruddurServiceExecutionRole  \
    --policy-document file://aws/policies/service-execution-policy.json
```



## Creating the TaskRole

```
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"
```

Create the Task Definition 

New file called `/aws/task-definitions/backend-flask.json`
[Backend-flask-task-definition](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/task-definitions/backend-flask.json)

Launch 
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```

To find the Default VPC
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

Security Group
```
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```

```
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 4567 \
  --cidr 0.0.0.0/0
  ```

Create a file called service-backend-flask.json under the path /aws/json/
[Backend-flask-service](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/json/service-backend-flask.json)

  
Launch the following command; 
```
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json

```


Connect to the containers using the Session Manager tool for Ubuntu.
```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"


sudo dpkg -i session-manager-plugin.deb

session-manager-plugin

```

connect to the command
```
aws ecs execute-command  \
    --region $AWS_DEFAULT_REGION \
    --cluster cruddur \
    --task TOCHANGED \
    --container backend-flask \
    --command "/bin/bash" \
    --interactive
  ```


The following code should be inserted into the gitpod.yml

```
name: fargate
    before: |
      curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
      sudo dpkg -i session-manager-plugin.deb
      cd backend-flask

```


Create the new file `connect-to-service`  

```
#! /usr/bin/bash
if [ -z "$1" ]; then
  echo "No TASK_ID argument supplied eg ./bin/ecs/connect-to-backend-flask 26117436c8544e249a23eba139de6d87"
  exit 1
fi
TASK_ID=$1

CONTAINER_NAME=backend-flask

echo "TASK ID: $TASK_ID"
echo "Container Name: $CONTAINER_NAME"

aws ecs execute-command \
  --region $AWS_DEFAULT_REGION \
  --cluster CrdClusterFargateCluster \
  --task $TASK_ID \
  --container $CONTAINER_NAME \
  --command "/bin/bash" \
  --interactive
```

Create a load balancer 

add the following code on `service-backend-flask.json`

```
"loadBalancers": [
      {
          "targetGroupArn": "",
          "containerName": "",
          "containerPort": 0
      }
    ],
```

Create the task-definition for the `frontend-react-js`
[Frontend-react-js TaskDefinition](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/task-definitions/frontend-react-js.json)


create the `dockerfile.prod` under the `frontend-react-js`
``` sh
# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```

Create a file called nginx.conf under the frontend-react-js
```sh
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}

```

Run the command to build

```
npm run build
```

Run the following command to build the image 
```
docker build \
--build-arg REACT_APP_BACKEND_URL="https://${CODESPACE_NAME}-4567.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="$AWS_USER_POOLS_ID" \
--build-arg REACT_APP_CLIENT_ID="$APP_CLIENT_ID" \
-t frontend-react-js \
-f Dockerfile.prod \
.

```



Create the repository for the frontend ECR

```
aws ecr create-repository \
  --repository-name frontend-react-js \
  --image-tag-mutability MUTABLE
```


and set the repository

```
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
```

Tag the image

```
docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
```

Push to the repository in ECR.

```
docker push $ECR_FRONTEND_REACT_URL:latest
```

To test locally,
```
docker run --rm -p 3000:3000 -it frontend-react-js 

```

Create the `service-frontend-react-js.json`
[Service Frontend-react-js](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/json/service-frontend-react-js.json)


To Create the task definition for the frontend.
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json

```

Create the service for the frontend-react-js 
```
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json

```

# Configuration of Domain from AWS Route53 and NameCheap.com

-Create the hosted zone for your domain
-In route53 under domains, go to `registered domain`.


To create a SSL/TLS certificate go to `AWS Certificate Manager`
Go to request and select "Request a public certificate".


# Securing Backend flask

```sh
FROM 173482565935.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY . .



EXPOSE ${PORT}
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]
```

# Implementation of XRay on Ecs and Container Insights

on our task definition backend and frontend, add the following part for the xray
```
{
      "name": "xray",
      "image": "public.ecr.aws/xray/aws-xray-daemon" ,
      "essential": true,
      "user": "1337",
      "portMappings": [
        {
          "name": "xray",
          "containerPort": 2000,
          "protocol": "udp"
        }
      ]
    },
```

Create a file called `register`.
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/backend-flask.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition \
--cli-input-json "file://$TASK_DEF_PATH"
```

do the same thing for the frontend,Create a file called `register`.

```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/frontend-react-js.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition \
--cli-input-json "file://$TASK_DEF_PATH"
```

on the folder aws-bootcamp-cruddur-2023/bin/backend create a file called run.
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
ENVFILE_PATH="$PROJECT_PATH/backend-flask.env"

docker run --rm \
--env-file $ENVFILE_PATH \
--network cruddur-net \
--publish 4567:4567 \
-it backend-flask-prod

```

/bin/frontend,Create a file called `run`.
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
ENVFILE_PATH="$PROJECT_PATH/frontend-react-js.env"

docker run --rm \
--env-file $ENVFILE_PATH \
--network cruddur-net \
--publish 3000:3000 \
-it frontend-react-js-prod

```

change the code of the `docker-compose-gitpod.yml` of the Backend-Flask
[Commit]()


Create a file generate-env under the aws-bootcamp-cruddur-2023/bin/backend

and paste the following code
```
#! /usr/bin/env ruby

require 'erb'

template = File.read 'erb/backend-flask-gitpod.env.erb'
content = ERB.new(template).result(binding)
filename = "backend-flask.env"
File.write(filename, content)

```


create a file `generate-env` under `/bin/frontend`

and paste the following code
```
#! /usr/bin/env ruby

require 'erb'

template = File.read 'erb/frontend-react-js.env.erb'
content = ERB.new(template).result(binding)
filename = "frontend-react-js.env"
File.write(filename, content)

```

Create  a folder called `erb` and create the following file `backend-flask.env.erb` 

```sh
AWS_ENDPOINT_URL=http://dynamodb-local:8000
CONNECTION_URL=postgresql://postgres:password@db:5432/cruddur
FRONTEND_URL=https://3000-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
OTEL_SERVICE_NAME=backend-flask
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io
OTEL_EXPORTER_OTLP_HEADERS=x-honeycomb-team=<%= ENV['HONEYCOMB_API_KEY'] %>
AWS_XRAY_URL=*4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>*
AWS_XRAY_DAEMON_ADDRESS=xray-daemon:2000
AWS_DEFAULT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
AWS_ACCESS_KEY_ID=<%= ENV['AWS_ACCESS_KEY_ID'] %>
AWS_SECRET_ACCESS_KEY=<%= ENV['AWS_SECRET_ACCESS_KEY'] %>
ROLLBAR_ACCESS_TOKEN=<%= ENV['ROLLBAR_ACCESS_TOKEN'] %>
AWS_COGNITO_USER_POOL_ID=<%= ENV['AWS_USER_POOLS_ID'] %>
AWS_COGNITO_USER_POOL_CLIENT_ID=<%= ENV['APP_CLIENT_ID'] %>

```

Create  a folder called `erb` and create the following file `frontend-react-js.env.erb` 

```sh
REACT_APP_BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
REACT_APP_AWS_PROJECT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_COGNITO_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_USER_POOLS_ID=<%= ENV['AWS_USER_POOLS_ID'] %>
REACT_APP_CLIENT_ID=<%= ENV['APP_CLIENT_ID'] %>
```


Link all the containers to connect with a specific network.
In your `docker-compose.yml`
```
networks: 
  internal-network:
    driver: bridge
    name: cruddur
```
TO
```
networks: 
  cruddur-net:
    driver: bridge
    name: cruddur-net
```

And also for each services, 
```
  networks:
      - cruddur-net
```

For troubleshooting, We can use a busy box.
create a file called busybox
```
#! /usr/bin/bash

docker run --rm \
  --network cruddur-net \
  -p 4567:4567 \
  -it busybox
```

##  Proof of Implementation
![Proof of Implementation](assets/week%2011/week%206-7/Route53.png)
![Proof of Implementation](assets/week%2011/week%206-7/Target-groups.png)
![Proof of Implementation](assets/week%2011/week%206-7/backend-flask%20healthy.png)
![Proof of Implementation](assets/week%2011/week%206-7/cognito%20user%20session.png)
![Proof of Implementation](assets/week%2011/week%206-7/domain%20working.png)
![Proof of Implementation](assets/week%2011/week%206-7/elb%20success.png)
![Proof of Implementation](assets/week%2011/week%206-7/elb%20working%20for%20backend.png)
![Proof of Implementation](assets/week%2011/week%206-7/health%20check.png)
![Proof of Implementation](assets/week%2011/week%206-7/health-check%20running.png)
![Proof of Implementation](assets/week%2011/week%206-7/new%20user.png)
![New listener](assets/week%2011/week%206-7/Listeners.png)
![Proof of Implementation](assets/week%2011/week%206-7/prod.png)
![Proof of Implementation](assets/week%2011/week%206-7/tasks%20healthy.png)
