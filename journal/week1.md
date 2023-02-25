# Week 1 — App Containerization

# REQUIRED Homework/Tasks
Following the live streamed Week 1 Video about App Containerization, I was able to complete the required assignment with slight challenges, but I was able to scale through.

## 1. Created Dockerfile into the backend-flask folder and copied code into the file

```
# This image is fetched from Docker Hub
FROM python:3.10-slim-buster

# Create this directory within the container 
WORKDIR /backend-flask

# Copy this file from your computer to the container: source -> destination 
# This file contains the libraries needed to run the app
COPY requirements.txt requirements.txt

# Run this cmd in the container 
# This is to install the python libraries needed for the app
RUN pip3 install -r requirements.txt

# Copy everything in the current directory to the container 
COPY . .

# Set env variables in the container 
# This is a way to configure our environment
ENV FLASK_ENV=development

# This will expose our app port 4567 
EXPOSE ${PORT}

# -m means to use the flask module
# --host=0.0.0.0 is for setting the port in the container 
# --port=4567 is for setting the app port
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]

```

# From the Dockerfile I was able to build a container inside with these commands.

```
docker build -t  backend-flask ./backend-flask

```

# From the Dockerfile I was able to run the container using these commands.

```

docker run --rm -p 4567:4567 -it backend-flask
FRONTEND_URL="*" BACKEND_URL="*" docker run --rm -p 4567:4567 -it backend-flask
export FRONTEND_URL="*"
export BACKEND_URL="*"
docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask
docker run --rm -p 4567:4567 -it  -e FRONTEND_URL -e BACKEND_URL backend-flask
unset FRONTEND_URL="*"
unset BACKEND_URL="*"

```

# I built the container in the background
```
docker container run --rm -p 4567:4567 -d backend-flask

```
# I forgot to take a screenshot of the port showing 404 not found, I hope this is sufficient enough
![Image of Dockerfile](assets/week%201%20Dockerfile.png)


## 2. Created Dockerfile into the frontend-react-js folder and copied code into this file
```
FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]

```
# Before doing the docker build I had to install npm into the gitpod workspace.
```
npm install

```

# From the Dockerfile I was able to build an image inside with these commands.
```
docker build -t frontend-react-js ./frontend-react-js
```
# I was able to run the container
```
docker run -p 3000:3000 -d frontend-react-js
```
## 3. Multiple Containers(Using Docker Compose)

