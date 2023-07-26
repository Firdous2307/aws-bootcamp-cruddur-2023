# Week 6-7 — Deploying Containers and Solving CORS with a Load Balancer and Custom Domain

Following the live streamed Week 6-7 about Deploying containers and solving CORS with a Load Balancer and custom domain, I was able to complete the required tasks;

First we need to create a script to check if we can estabilish a connection with the RDS


backend-flask/bin/db/test

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

 
Create the cloudwatch log group. 

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
FROM 238967891447.dkr.ecr.eu-west-2.amazonaws.com/cruddur-python

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

