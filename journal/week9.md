# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy

## TO-DO
- Buildspec.yml - which is to be created in backend-flask i.e `backend-flask/buildspec.yml`
- Policy for permissions required for codebuild, in which mine is named `ecr-codebuild-backend-role.json`
- Create a Prod branch in your repository and Pull requests from the main branch.


My backend service at AWS ECS has always been set to 0 task definitions to manage spend on running the container.
If the backend is updated, I needed to run `./bin/backend/build`, `./bin/backend/push`, and `./bin/backend/deploy`


## AWS CodeBuild

Creating a build project:

- named as`cruddur-backend-flask-bake-image` in AWS Console.
  
- I enabled build badge
  
- Choose source provider as `GitHub`, repository in my GitHub account.

  
## Selected the following:

- the `cruddur` repo and set source version to `prod`.

- `rebuild` every time

- also I selected `single build`.

- event type as `PULL_REQUEST_MERGED`.

- operating system as `Amazon Linux 2`.

- standard `runtime`.

- the `latest image (5.0)`.

- environment type as `Linux`.

- compute as `3 GB memory and 2 vCPUs`.

- `Cloudwatch logs`.

- set group name as `/cruddur/build/backend-flask`.

- stream name as `backend-flask`.

## Created the following;

- a new service role named as `codebuild-cruddur-backend-flask-bake-image-service-role`.

- a `buildspec .yml file`.

- attached a policy named `ecr-codebuild-backend-role.json`, as shown in `aws/policies/`



## For My Required Task on AWS CodePipeline, I was able to;

Created a pipeline:
- as `cruddur-backend-fargate`.

- a new service role named as `AWSCodePipelineServiceRole-us-east-1-cruddur-backend-fargate`.

Configured the following:

- Selected the `default location` and `default managed key` in advanced settings of the pipeline.

- a source stage from `GitHub (Version 2)`.

- Clicked on `Connect to GitHub`.

- Was able to set a connection name as `cruddur`.

- Installed a new app and selected the `cruddur repo`.

- Selected the cruddur repo and a branch named `prod`.

- Clicked on `start the pipeline on source code change`.

- AWS CodeBuild was used as build provider, and in my region, also I selected the newly created project `cruddur-backend-flask-bake-image`.

- In the deploy stage, I selected `Amaxon ECS` as deploy provider.

- Choosed the `cruddur` as a cluster and `backend-flask` as the service.

- Updated `backend-flask/app.py` by changing the return in health_check function from return {"success": True}, 200
to
return {"success": True, "ver": 1}, 200.

-Furthermore, I was able to merge the `prod` branch to the `main` branch.

You will find proof of work CodeBuild and CodePipeline below;

![Proof of CodePipline](assets/week%209/CICD(1).png)
![Proof of CodePipline](assets/week%209/CICD(2).png)
![Proof of CodePipline](assets/week%209/CICD(3).png)
