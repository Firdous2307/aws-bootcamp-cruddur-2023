# Week 2 — Distributed Tracing

## Required Homework/Tasks
Following the live streamed Week 2 about Observability, I was able to complete the required assignment with slight challenges, but I was able to scale through.


### 1. Setting up Honeycomb

Let's set up our environment in honeycomb

First, login to your account through this [link](https://www.honeycomb.io)

Once logged in, got to `ENVIRONMENT` on the left panel of your page

![Image of the ENVIRONMENT panel](assets/week%202/Environment.png)

Click `Manage Environments` to create one. I named mine `bootcamp`

![Image of environment creation](assets/week%202/%20Environment-Creation.png)

After creating the environment, you should can see the environment you just created. 

![Image of bootcamp environment](assets/week%202/bootcamp%20environment.png)

Furthermore,I went ahead to grab/copy the `API keys` under `View API keys`. The API keys used will determine the environment in which the data will land in. 

Let's export our `API key` to `gitpod` using the commands below:
```bash
# to export it to our gitpod terminal 
export HONEYCOMB_API_KEY="..."

# confirm export 
env | grep HONEY

# to have it permanently saved unto gitpod env variables
# when it starts next time, we don't have to export it again  
gp env HONEYCOMB_API_KEY="..."
```



### 2. Instrument backend flask to use OpenTelemetry (OTEL) with Honeycomb.io as the provider 

Honeycomb typically refers to a cloud-based observability platform. Honeycomb is an all-in-one solution for distributed tracing, metrics, and logging that provides deep visibility into the performance and behavior of complex systems and applications. It uses `OTEL` libraries which is simply the `OpenTelemetry` libraries. Read more [here](https://www.honeycomb.io/)


Let's set our honeycomb env variable for our `backend` in the `docker-compose.yml` file. Add the following lines of code to the file:

``` 
OTEL_SERVICE_NAME: 'backend-flask'
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
```

Now, let's install the `OTEL` libraries into our application. 
Add the following lines to the `requirements.txt` file located in the `backend-flask/` directory
```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests # this should instrument outgoing HTTP calls
```

Go ahead and install the dependencies you listed in the `requirements.txt` file
In the `backend-flask` directory, run the following command:
```
pip install -r requirements.txt
```
![Image of installation](assets/week%202/%20pip%20installation.png)

Let's create and initialize honeycomb by adding the following lines of code to `app.py` file
```python
# Honeycomb
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# Initialize automatic instrumentation with Flask
app = Flask(__name__) # if this link already exists, DON'T call it again
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
```

After the updates, test out your configuration by running this command:
` docker compose up` 

![Image of Datasets creation](assets/week%202/%20DataSets%20Creation.png)

Confirm that honeycomb is getting your data. If not, here are some steps for troubleshooting
- Check what API key your environment is using. Do that by checking your env variables 
`env | grep HONEYCOMB_API_KEY`

- If it is still not set, you can restart or create a new workspace, but make sure you commit and push your changes to your repository to avoid data loss. 


### 3. Working with traces/spans/attribute in Honeycomb.io

Checkout this [doc](https://docs.honeycomb.io/getting-data-in/opentelemetry/python/#creating-spans) for better documentation

**Configure a Tracer**

Add the following lines of code to your `backend-flask/services/home_activities.py` file:
```python
from opentelemetry import trace

# add before the HomeActivities class
tracer = trace.get_tracer("home.activities") 
```

**Create a Span**

Create a span with our configured **tracer**. A span describes what is happening in your application.

Add the following lines of code to your `backend-flask/services/home_activities.py` file:
```python
# add under def run():
with tracer.start_as_current_span("home-activities-mock-data"):
# make sure every other line beneath is properly indented under the code you pasted 
```

After the updates, test out your configuration by running this command:
` docker compose up` 

To create some spans, append this URL to your backend, `.../api/activities/home`

![Image of Created Spans](assets/week%202/%20Created%20Span.png)

**Add Attribute to Span**

These attributes gives us more context to our logs. Go ahead and add a few by including these lines of code to your `backend-flask/services/home_activities.py` file:
```python
# in the def run(): section
# add attribute -> app.now 
span = trace.get_current_span()
span.set_attribute("app.now", now.isoformat())

# at the bottom -> app.result_length
span.set_attribute("app.result_length", len(results))
```

After the updates, test out your configuration by running this command:
` docker compose up` 


### 4. Run queries to explore traces within Honeycomb.io

With our previously hard-coded attributes `app.now` and `app.result_length`, let's create and run some queries

*Query 1*

![Image of Query 1](assets/week%202/%20Query(1).png)
![Image of Query 1](assets/week%202/%20%20Query(1)%20Extended.png)

*Query 2*

![Image of Query 2](assets/week%202/%20Query(2).png)

*Query 3*

Latency - checks how long these requests take
![Image of Query 3](assets/week%202/Query%20(3).png)


### 5. Instrument AWS X-ray into the backend
AWS X-Ray is a distributed tracing system that helps developers analyze and debug distributed applications. Read more [here](https://aws.amazon.com/xray/)

**Install AWS X-ray**

We need to install the [AWS SDK](https://github.com/aws/aws-xray-sdk-python) 

Add the following lines to the `requirements.txt` file located in the `backend-flask/` directory
```
aws-xray-sdk
```

Go ahead and install the dependencies you listed in the `requirements.txt` file
In the `backend-flask` directory, run the following command:
```
pip install -r requirements.txt
```
![Image of AWS XRay Installation](assets/week%202/Xray%20installation.png)


**Instrument X-ray for Flask**

To instrument our `backend-flask`, add the following lines of code to the `app.py` file
```python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)

XRayMiddleware(app, xray_recorder)
```

**Create Sampling Rule**

Create a `json` file in the `aws/json` directory 
```bash
aws/json/xray.json
```

Add the following lines of code to your newly created file:
```json
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```

 Create an x-ray trace group and a sampling rule. Then, run the following command:
```bash
# create a group in AWS x-ray or Gipod Terminal
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\")"
   ```
   
![Image of XRay Group](assets/week%202/%20xray%20group.png)
![Image of AWS XRay Group](assets/week%202/%20AWS%20xray%20group.png)

# create a sampling rule
```
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```
![Image of Sample Group](assets/week%202/%20sampling%20group.png)
![Image of AWS Sample Group](assets/week%202/AWS%20Sampling%20group.png)

**Configure X-ray daemon with docker-compose**

Setup the daemon in the `docker-compose.yml` file by adding these following lines:
```YAML
# add these env variables above in the ENV section
AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"

xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "us-east-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
```

After the updates, test out your configuration by running this command:
` docker compose up` 

Check your x-ray container logs to make sure logs were successfully sent to AWS X-ray.

![Image of XRay logs](assets/week%202/%20xray%20logs.png)

![Image of AWS XRay logs](assets/week%202/%20AWS%20Xray%20trace.png)


### 6. Creating a Custom Segment and Subsegment with AWS X-ray

In the `backend-flask/services/user_activities.py` file, add the following lines of code:
```python
from aws_xray_sdk.core import xray_recorder

# Start a segment
	subsegment = xray_recorder.begin_segment('mock-data')

    dict = {
      "now": now.isoformat(),
      "results-size": len(model['data'])
    }

    subsegment.put_metadata('key', dict, 'namespace')

    # Close subsegment
    xray_recorder.end_subsegment()
```
![Image of XRay Segment](assets/week%202/xray%20segment.png)
![Image of AWS XRay Segment](assets/week%202/AWS%20xray%20segment.png)
![Image of XRay SubSegment](assets/week%202/xray%20subsegment.png)

Add the following to the `app.py` file:
```python

@app.route("/api/activities/home", methods=['GET'])
@xray_recorder.capture('actAWS ivities_home'(assets/))
def data_home():
  data = HomeActivities.run(logger=LOGGER)
  return data, 200

@app.route("/api/activities/@<string:handle>", methods=['GET'])
@xray_recorder.capture('activities_users')
def data_handle(handle):
  model = UserActivities.run(handle)
  if model['errors'] is not None:
    return model['errors'], 422
  else:
    return model['data'], 200

@app.route("/api/activities/<string:activity_uuid>", methods=['GET'])
@xray_recorder.capture('activities_show')
def data_show_activity(activity_uuid):
  data = ShowActivity.run(activity_uuid=activity_uuid)
  return data, 200
```


### 7. Installing WatchTower and how to write custom logger to send app log data to CloudWatch Log Group

Add the following lines to the `requirements.txt` file located in the `backend-flask/` directory
```
watchtower
```

Go ahead and install the application you listed in the `requirements.txt` file
In the `backend-flask` directory, run the following command:
```
pip install -r requirements.txt
```

**Setting environment variables for watchtower**

In the `docker-compose.yml` file, add the following lines:
```YAML
AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```

 Configuring our CloudWatch logger. Add the following lines to the `app.py` file:
```python
# CloudWatch Logs
import watchtower
import logging
from time import strftime

# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("test message")
```

Before `@app.route...` paste this before it:
```python
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```

 Log something in one of the API endpoint by adding the following lines to our `backend-flask/services/home_activities.py` file:
```python
# in the class HomeActivities: section, update and add these lines
def run(logger):
    logger.info("HomeActivities")
```

In the `app.py` file, update your code to look like this:
```python
@app.route("/api/activities/home", methods=['GET'])
def data_home():
  data = HomeActivities.run(logger=LOGGER)
  return data, 200
```

After the updates, test out your configuration by running this command:
` docker compose up` 


![Image of CloudWatch Log](assets/week%202/cloudwatch%20logs.png)
![Image of CloudWatch Log Details](assets/week%202/cloudwatch%20logs%20details.png)
![Image of CloudWatch Log Events](assets/week%202/cloudwatch%20log%20events.png)



### 8. Integrate Rollbar for Error Logging

Rollbar is a cloud-based platform for detecting and resolving software errors and exceptions. Rollbar integrates with popular development tools and languages, such as JavaScript, Ruby, Python, PHP, and Java, to provide a comprehensive error tracking solution for web and mobile applications.  Read more [here](https://rollbar.com/)

Add the following lines to the `requirements.txt` file located in the `backend-flask/` directory
```
blinker 
rollbar
```

Now install the application you listed in the `requirements.txt` file
In the `backend-flask` directory, run the following command:
```
pip install -r requirements.txt
```

Let's add the rollbar access token
```bash
export ROLLBAR_ACCESS_TOKEN=""
gp env ROLLBAR_ACCESS_TOKEN=""
```
![Image of Rollbar](assets/week%202/rollbar.png)
![Image of Rollbar Access Token](assets/week%202/rollbar%20access%20token.png)

`Add ACCESS_TOKEN` to `docker-compose.yml`

```YAML
ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
```

**Import Rollbar Libraries**

Let's import the rollbar libraries 
Add the following lines in the `app.py` file 
```python
# Rollbar
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception

# after app = Flask(__name__),
# add these lines 
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```

**Add Rollbar Endpoint**

Below, check for the `@app.route...` to add a rollbar endpoint 
```python
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```
![Image of Rollbar Hello World](assets/week%202/rollbar%20hello%20world.png)

After the updates, test out your configuration by running this command:
` docker compose up` 

Then we can test out the new endpoint I added by appending `/rollbar/test` to your backend URL
![Image of Rollbar Test](assets/week%202/rollbar%20test.png)


### 9. Trigger an error and observe it with Rollbar 

I created an error log for Rollbar. Delete some words in one of the `../service/` file to create an error. 

Navigate to this URL `.../api/activities/home` to view the error page 

![Image of Rollbar Error page](assets/week%202/rollbar%20error%20page.png)

We should see the error message logged in your rollbar account, under "Items"

![Image of Rollbar Error message](assets/week%202/rollbar%20error%20message.png)


