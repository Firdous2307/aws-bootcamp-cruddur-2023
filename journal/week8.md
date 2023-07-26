# Week 8 — Serverless Image Processing

## Preparation

We need to use CDK (Cloud Development Kit) to create S3 buckets, Lambda functions, SNS topics, etc., allowing users to upload their avatars to update their profiles.

Before launching the CDK, you need to bootstrap

```sh
cdk bootstrap "aws://AWSACCOUNTNUMBER/REGION"
```

Example:
```sh
for a single region
cdk bootstrap "aws://123456789012/us-east-1"
```

## Creating a folder 

The name of this folder was `thumbing-serverless-cdk`.

Move into the folder and run  `npm install aws-cdk -g`. This command installs the AWS Cloud Development Kit (CDK) globally on your dev env using the Node.js package manager (npm)

So, I added the following lines into my `gitpod.yml`. This automatically reinstalls cdk every time you launch a new workspace in gitpod.

```sh
 - name: cdk
    before: |
      cd thumbing-serverless-cdk
      cp .env.example .env
      npm i
      npm install aws-cdk -g
```


Navigate to the `thumbing-serverless-cdk` folder and initialise it for typescript.

```sh
cdk init app --language typescript
```

To work with the cdkfile, go to the file inside the lib/thumbing-serverless-cdk-stack.ts

To define the s3 bucket do the following:

import the library for s3 

```sh
import * as s3 from 'aws-cdk-lib/aws-s3';
```

###  Implementing the CDK Stack

- Created a S3 bucket named `assets.mohammedfirdous.works` in my AWS account. This will be used to store avatar images, banners for the website
- Create the following file `.env.example`. This will be used by the lamba application to define the source and output buckets
- Create lambda function that will be invoked by our CDK stack in `aws\lambdas\process-images`



export following env vars according to your domain name and another S3 bucket (e.g., `mohammedfirdous-uploaded-avatars`), which will be created by CDK later for saving the original uploaded avatar images:

```sh
export DOMAIN_NAME=mohammedfirdous.works
gp env DOMAIN_NAME=mohammedfirdous.works
export UPLOADS_BUCKET_NAME=mohammedfirdous-uploaded-avatars
gp env UPLOADS_BUCKET_NAME=mohammedfirdous-uploaded-avatars
```

```sh
mkdir -p aws/lambdas/process-images
cd aws/lambdas/process-images
touch index.js s3-image-processing.js test.js  example.json
npm init -y
npm install sharp @aws-sdk/client-s3
```


```sh
cd /workspace/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk
touch .env.example
```

#### Sample .env.example file

[.env.example](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/thumbing-serverless-cdk/.env.example)

```env
UPLOADS_BUCKET_NAME="mohammedfirdous-uploaded-avatars"
ASSETS_BUCKET_NAME="assets.mohammedfirdous.works"
THUMBING_S3_FOLDER_INPUT=""
THUMBING_S3_FOLDER_OUTPUT="avatars"
THUMBING_WEBHOOK_URL="https://api.mohammedfirdous.works/webhooks/avatar"
THUMBING_TOPIC_NAME="cruddur-assets"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/process-images"
```


#### S3 Bucket for images

`assets.<domain_name>` e.g. `assets.mohammedfirdous.works`


Deploy the CDK using AWS CloudFormation

`cdk deploy`

To verify the application has been deployed successfully, run the following command.

`cdk ls`


### Sharp Installation

Once the npm package has been installed we need to run the following npm command.

In order to let the `sharp` dependency work in Lambda, run the script:

```sh
cd /workspace/aws-bootcamp-cruddur-2023
./bin/avatar/build

cd thumbing-serverless-cdk
```

```sh
cd /workspace/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk
npm install
rm -rf node_modules/sharp
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install --arch=x64 --platform=linux --libc=glibc sharp
```



## Test Deployed Lambda

- Run the `bin/avatar/upload` [script]() that uploads a file `data.jpg`. 
- Verify that the image has been uploaded to the destination bucket.




## Serving Avatars via CloudFront

Amazon CloudFront is designed to work seamlessly with S3 to serve your S3 content. Also, using CloudFront to serve s3 content gives you a lot more flexibility and control.
For more information, check out the official documentation by AWS.[CloudFront](https://aws.amazon.com/cloudfront/).


To create a CloudFront distribution, a certificate in the `us-east-1` zone for `*.<your_domain_name>` is required. If you don't have one yet, create one via AWS Certificate Manager, and click "Create records in Route 53" after the certificate is issued.

### Certificate Creation

- Go to `AWS Certificate Manager (ACM)`
- Click `Request Certificate`
- Select `Request a public certificate`
- In `Fully qualified domain name` enter `<domainname>` e.g. `mohammedfirdous.works`
- Select `Add Another Name to this certificated` and add `*.mohammedfirdous.works`
- Ensure `DNS validation - recommended` is selected
- Click `Request`

Create a distribution by:
- set the Origin domain to point to `assets.<your_domain_name>`
- choose Origin access control settings (recommended) and create a control setting
- select Redirect HTTP to HTTPS for the viewer protocol policy
- choose CachingOptimized, CORS-CustomOrigin as the optional Origin request policy, and SimpleCORS as the response headers policy
- set Alternate domain name (CNAME) as `assets.<your_domain_name>`
- choose the previously created ACM for the Custom SSL certificate.

Once the CloudFront distribution has been created, we need to copy it's bucket policy.

This policy needs to be applied to the bucket `assets.mohammedfirdous.works` under `Permissions` -> `Bucket Policy`


When uploading a new version of an image until it expires it will keep displaying the old version of the file. To stop this from happening we need to enable [invalidation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)

- In `Cloudfront` select the cloudfront distribution
- Select `Invalidations`
- Add the pattern `/*` and click `Create Invalidation`
- It will take a minute or so for the change to take effect



## Backend and Frontend for Profile Page

For the backend, update/create the following scripts ([repo](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/tree/main/frontend-react-js)

- `backend-flask/db/sql/users/show.sql` to get info about user
- `backend-flask/db/sql/users/update.sql` to update bio
- `backend-flask/services/user_activities.py`
- `backend-flask/services/update_profile.py`
- `backend-flask/app.py`

For the frontend, update/create the following scripts ([repo](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/tree/main/frontend-react-js)

- `frontend-react-js/src/components/ActivityFeed.js`
- `frontend-react-js/src/components/CrudButton.js`
- `frontend-react-js/src/components/DesktopNavigation.js` 
- `frontend-react-js/src/components/EditProfileButton.css`
- `frontend-react-js/src/components/EditProfileButton.js`
- `frontend-react-js/src/components/Popup.css`
- `frontend-react-js/src/components/ProfileAvatar.css`
- `frontend-react-js/src/components/ProfileAvatar.js`
- `frontend-react-js/src/components/ProfileForm.css`
- `frontend-react-js/src/components/ProfileForm.js` 
- `frontend-react-js/src/components/ProfileHeading.css`
- `frontend-react-js/src/components/ProfileHeading.js` 
- `frontend-react-js/src/components/ProfileInfo.js`
- `frontend-react-js/src/components/ReplyForm.css`
- `frontend-react-js/src/pages/HomeFeedPage.js`
- `frontend-react-js/src/pages/NotificationsFeedPage.js`
- `frontend-react-js/src/pages/UserFeedPage.js` 
- `frontend-react-js/src/lib/CheckAuth.js`
- `frontend-react-js/src/App.js`
- `frontend-react-js/jsconfig.json`


## DB Migration

In our Previous postgresql, there was no column named `bio`, therefore migration is required.

Create an empty `backend-flask/db/migrations/.keep`, and an executable script `bin/generate/migration` 

```python
#!/usr/bin/env python3
import time
import os
import sys

if len(sys.argv) == 2:
  name = sys.argv[1]
else:
  print("pass a filename: eg. ./bin/generate/migration add_bio_column")
  exit(0)

timestamp = str(time.time()).replace(".","")

filename = f"{timestamp}_{name}.py"

# covert undername name to title case eg. add_bio_column -> AddBioColumn
klass = name.replace('_', ' ').title().replace(' ','')

file_content = f"""
from lib.db import db
class {klass}Migration:
  def migrate_sql():
    data = \"\"\"
    \"\"\"
    return data
  def rollback_sql():
    data = \"\"\"
    \"\"\"
    return data

  def migrate():
    db.query_commit({klass}Migration.migrate_sql(),{{
    }})

  def rollback():
    db.query_commit({klass}Migration.rollback_sql(),{{
    }})

    
migration = AddBioColumnMigration
"""
#remove leading and trailing new lines
file_content = file_content.lstrip('\n').rstrip('\n')

current_path = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations',filename))
print(file_path)

with open(file_path, 'w') as f:
  f.write(file_content)
  
```  
  

Run `./bin/generate/migration add_bio_column`
- a python script such as `backend-flask/db/migrations/16888600785058737_add_bio_column.py` is generated. 

Also, Update `backend-flask/db/schema.sql`, and update `backend-flask/lib/db.py` with the option of verbose.

Create executable scripts `bin/db/migrate` and `bin/db/rollback`.

In the `bin/db/migrate` script;

``` python
#!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
    sql = """
    SELECT last_successful_run
    FROM public.schema_information
    LIMIT 1
    """
    result = db.query_value(sql, {}, verbose=True)
    return int(result) if result is not None else 0

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  WHERE id = 1
  """
  db.query_commit(sql,{'last_successful_run': value},verbose=True)
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


for migration_file in migration_files:
  filename = os.path.basename(migration_file)
  module_name = os.path.splitext(filename)[0]
  match = re.match(r'^\d+', filename)
  if match:
    file_time = int(match.group())
    if last_successful_run <= file_time:
      mod = importlib.import_module(module_name)
      print('running migration: ',module_name)
      mod.migration.migrate()
      timestamp = str(time.time()).replace(".","")
      last_successful_run = set_last_successful_run(timestamp)
```



In the `bin/db/rollback`

```python
#!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
    sql = """
    SELECT last_successful_run
    FROM public.schema_information
    LIMIT 1
    """
    result = db.query_value(sql, {}, verbose=False)
    return int(result) if result is not None else 0

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  WHERE id = 1
  """
  db.query_commit(sql,{'last_successful_run': value})
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


last_migration_file = None
for migration_file in migration_files:
  if last_migration_file == None:
    filename = os.path.basename(migration_file)
    module_name = os.path.splitext(filename)[0]
    match = re.match(r'^\d+', filename)
    if match:
      file_time = int(match.group())
      print("====")
      print(last_successful_run, file_time)
      print(last_successful_run > file_time)
      if last_successful_run > file_time:
        last_migration_file = module_name
        mod = importlib.import_module(module_name)
        print('===== rolling back: ',module_name)
        mod.migration.rollback()
        set_last_successful_run(file_time)

print(last_migration_file)

```

If we run `./bin/db/migrate`, a new column called bio will be created in the db table of `users`.



## Avatar Upload Implementation

We need to create an API endpoint, which invoke a presigned URL like `https://<API_ID>.execute-api.<AWS_REGION>.amazonaws.com`. This presigned URL can give access to the S3 bucket (`mohammedfirdous-uploaded-avatars`), and can deliver the uploaded image to the bucket.

### Pre-Requisites for Avatar Upload

- Create a lambda function to authorise the currently logged in user `aws/lambdas/lambda-authorizer`
- Create a lambda function to upload the image `aws/lambdas/cruddur-upload-avatar/`
- Create an API gateway which invokes the lambda functions.

### Implementing the Lambda Function called CruddurAvatarUpload

```sh
cd /workspace/aws-bootcamp-cruddur-2023/
mkdir -p aws/lambdas/cruddur-upload-avatar/
cd aws/lambdas/cruddur-upload-avatar/
touch function.rb
bundle init
```

Run `bundle init`; edit the generated `Gemfile`, then run `bundle install` and `bundle exec ruby function.rb`; a presigned url can be generated.[repo](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/lambdas/cruddur-upload-avatar/function.rb)


### Implement the Lambda Function called Lambda-Authorizer


```sh
cd /workspace/aws-bootcamp-cruddur-2023/
mkdir -p aws/lambdas/lambda-authorizer/
cd aws/lambdas/lambda-authorizer/
touch index.js
npm init -y
npm install aws-jwt-verify --save
```
In `aws/lambdas/lambda-authorizer/`, create `index.js`, run `npm install aws-jwt-verify --save`, and download everything in this folder into a zip file (you can zip by command `zip -r lambda_authorizer.zip .`), which will be uploaded into `CruddurApiGatewayLambdaAuthorizer`.


## Creating two Functions

In `CruddurAvatarUpload`

- Create a Ruby Application named `CruddurAvatarUpload`

- Upload the code from [function.rb](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/lambdas/cruddur-upload-avatar/function.rb), ensuring it has the correct GitPod frontend URL set in `Access-Control-Allow-Origin`
  
- Set an environment variable `UPLOADS_BUCKET_NAME` with `mohammedfirdous-uploaded-avatars` the location where avatars are to be uploaded to

- Edit `runtime settings` to have the handler set as `function.handler`
  
- Modify the current permissions policy and attach a new inline policy `PresignedUrlAvatarPolicy` using this [S3 Policy](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/policies/s3-upload-avatar-presigned-url-policy.json)



In `CruddurApiGatewayLambdaAuthorizer`

- Create a Node.js Application named `CruddurApiGatewayLambdaAuthorizer`
  
- upload `lambda_authorizer.zip` into the code source. If packaged and uploaded correctly.
  
- Set the environment variables `USER_POOL_ID` and `CLIENT_ID` with your Cognito clients `USER_POOL_ID` and `AWS_COGNITO_USER_POOL_CLIENT_ID` respectively.

### Update S3 Bucket COR Policy

- Under the permissions for `mohammed-firdous-uploaded-avatars` edit `Cross-Origin resource sharing (CORS)` with this [S3 CORS Policy](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/blob/main/aws/s3/cors.json)

### Create API Gateway

- In `API Gateway`, create a `HTTP API` with api.<domain_name> e.g. `api.mohammedfirdous.works`
  
- Create the two routes;

- `POST /avatars/key_upload` with authorizer `CruddurJWTAuthorizer` which invoke Lambda `CruddurApiGatewayLambdaAuthorizer`, and with integration `CruddurAvatarUpload`
- `OPTIONS /{proxy+}` without authorizer, but with integration `CruddurAvatarUpload`


## CORS Not Working

Following the videos and looking through the discord support community, I could not get CORS working.

I had to deploy my `CruddurAvatarUpload` function again and i was able to get back my presigned url when i checked my CloudWatch Logs.
I figured it would not be much of an issue to push foward to other wweks because it mostly dealt with infrastructure and not running tasks or problems on the application itself.

## Proof of Implementation 

![Image of CORS error](assets/week%208/CORS%20error.png)
![Image of AvatarsFolder](assets/week%208/avatars%20folder.png)
![Image of bio-column](assets/week%208/bio%20column.png)
![Image of event-notifications](assets/week%208/event%20notifications.png)
![Image of Fetch-Error](assets/week%208/fetch%20error.png)
![Image of key-upload-error](assets/week%208/key-upload%20error.png)
![Image of lambda-authorizer error](assets/week%208/lambda-authorizer%20error.png)
![Image of latest lambda layer](assets/week%208/latest%20lambda%20layer.png)
![Image of mock not uploading](assets/week%208/mock%20not%20uploading.png)
![Image of presigned url showing](assets/week%208/presigned%20url%20showing.png)
![Image of preview seeded data](assets/week%208/preview%20seeded%20data.png)
![Image of profile display](assets/week%208/profile%20display.png)
![Image of profile edit](assets/week%208/profile%20edit.png)
![Image of status 200](assets/week%208/status%20200.png)
![Image of trigger](assets/week%208/trigger.png)
![Image of unauthorized error](assets/week%208/unauthorized%20error.png)
![Image of undefined error](assets/week%208/undefined%20error.png)
![Image of uploaded-avatars bucket](assets/week%208/uploaded-avatars%20bucket.png)


