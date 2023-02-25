# Week 1 — App Containerization

# REQUIRED Homework/Tasks
Following the live streamed Week 1 Video about App Containerization, I was able to complete the required assignment with slight challenges, but I was able to scale through.

### 1. Created Dockerfile into the backend-flask folder and copied code into the file

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


### 2. Created Dockerfile into the frontend-react-js folder and copied code into this file
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
### 3. Multiple Containers(Using Docker Compose)

# The use of docker compose helps us deal with multiple containers. Let's create a docker compose file at the root of our project /workspace/aws-bootcamp-cruddur-2023, assuming you are using gitpod.

# To make sure you are in the root of your project 
pwd 

# now create the docker-compose file
 ```
 docker-compose.yml
```
Go ahead and copy this content into your file 
```yaml
version: "3.8"

# here is where you declare your services -> frontend & backend 
services:

  # BACKEND
  backend-flask:

    # passing our env variables
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    
    # building our image
    build: ./backend-flask

    # mapping our ports -> local:container
    ports:
      - "4567:4567"
    
    # mapping our volumes -> local:container
    volumes:
      - ./backend-flask:/backend-flask
  
  # FRONTEND
  frontend-react-js:
    
    # passing our env variables
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    
    # building our image
    build: ./frontend-react-js
    
    # mapping our ports -> local:container
    ports:
      - "3000:3000"
    
    # mapping our volumes -> local:container
    volumes:
      - ./frontend-react-js:/frontend-react-js

# the name flag is a hack to change the default prepend folder
# name when outputting the image names
networks: 
  internal-network:
    driver: bridge
    name: cruddur
```

Start up our containers using this command:
```
docker compose up
```
**Now you should see both services up and running**
![Image of Cruddur](assets/week1%20%20frontend-backend.png)
![Proof of Docker Compose](assets/week%201%20docker%20compose.png)



### 4. Creating and Running DynamoDB Local 

```yaml
  dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```


### 5. Creating and Running Postgres DB

To create our `postgres` service, add this content to the `docker compose` file 
```yaml
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data

volumes:
  db:
    driver: local
```

To be able to interact with the `postgres client`, we need to install the extension into the gitpod. And to do that, we need to add these following lines to our `gitpod.yml` file:
```yaml
- name: postgres
    init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
```
 

After installation, create a database with any password of your choice using the postgres extension in `gitpod`.
![Image of the DB ](assets/week1%20Postgres.png)

Connect to the `postgres client` using these commands:
```
# to connect to the postgres client
psql --host localhost

# to access the postgres DB
psql -h localhost -U postgres

# play around with the postgres commands 
\l # lists the tables you have 
\dl
\q # quits the DB
```


### 6. Adding Endpoint for Notifications - Using Flask for Backend 

Add the notifications endpoint to the `openapi.yml` file using these contents:
```yaml
#create a path using the OpenAPI extension
/api/activities/notifications:
    get:
      description: 'Return a feed of activity for all those I follow'
      tags: 
        - activities
      parameters: []
      responses:
        '200':
          description: Return an array of activities 
          content:
            application/json:
              schema:
                type: array
                items: 
                  $ref: '#/components/schemas/Activity'
```

Now we need to add a route for the endpoint we created. Add these contents to the `backend-flask/app.py` file 
```python
# add this in the beginning of the file.
# It adds the notifications module
from services.notifications_activities import *

# add notifications route 
@app.route("/api/activities/notifications", methods=['GET'])
def data_notifications():
  data = NotificationsActivities.run()
  return data, 200
```

Go ahead and add a `notification` file in the `backend-flask/services/` directory
```bash
touch backend-flask/services/notifications_activities.py
```

Add the following content to the created file 
```python
from datetime import datetime, timedelta, timezone
class NotificationsActivities:
  def run():
    now = datetime.now(timezone.utc).astimezone()
    results = [{
      'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
      'handle':  'Dev Queen',
      'message': 'Yah, I got this!',
      'created_at': (now - timedelta(days=2)).isoformat(),
      'expires_at': (now + timedelta(days=5)).isoformat(),
      'likes_count': 5,
      'replies_count': 1,
      'reposts_count': 0,
      'replies': [{
        'uuid': '26e12864-1c26-5c3a-9658-97a10f8fea67',
        'reply_to_activity_uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
        'handle':  'Worf',
        'message': 'This post has no honor!',
        'likes_count': 0,
        'replies_count': 0,
        'reposts_count': 0,
        'created_at': (now - timedelta(days=2)).isoformat()
      }],
    }
    ]
    return results
```

### 5. Adding a React Page for Notifications

We need to add a notification feed to the `app.js` file in the `frontend-react-js/src/app.js` directory. Go ahead and add the following contents:

```js
//to import the module
import NotificationsFeedPage from './pages/NotificationsFeedPage';

//delete this line from the code
import process from 'process';

//under the const router ... add a router for notifications
{
    path: "/notifications",
    element: <NotificationsFeedPage />
  },
```

Now let's create a page for the feed we just created:
```bash
# in frontend-react-js/src/pages/
touch frontend-react-js/src/pages/NotificationsFeedPage.js
touch frontend-react-js/src/pages/NotificationsFeedPage.css
```

Add the following content to the `NotificationsFeedPage.js` file:
```js
import './NotificationsFeedPage.css';
import React from "react";

import DesktopNavigation  from '../components/DesktopNavigation';
import DesktopSidebar     from '../components/DesktopSidebar';
import ActivityFeed from '../components/ActivityFeed';
import ActivityForm from '../components/ActivityForm';
import ReplyForm from '../components/ReplyForm';

// [TODO] Authenication
import Cookies from 'js-cookie'

export default function NotificationsFeedPage() {
  const [activities, setActivities] = React.useState([]);
  const [popped, setPopped] = React.useState(false);
  const [poppedReply, setPoppedReply] = React.useState(false);
  const [replyActivity, setReplyActivity] = React.useState({});
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/notifications`
      const res = await fetch(backend_url, {
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };

  const checkAuth = async () => {
    console.log('checkAuth')
    // [TODO] Authenication
    if (Cookies.get('user.logged_in')) {
      setUser({
        display_name: Cookies.get('user.name'),
        handle: Cookies.get('user.username')
      })
    }
  };

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth();
  }, [])

  return (
    <article>
      <DesktopNavigation user={user} active={'notifications'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm  
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <ActivityFeed 
          title="Notifications" 
          setReplyActivity={setReplyActivity} 
          setPopped={setPoppedReply} 
          activities={activities} 
        />
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
}
```
