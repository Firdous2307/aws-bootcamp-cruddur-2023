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
