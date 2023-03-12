# Week 3 — Decentralized Authentication

## Required Homework/Tasks

### 1. Setting Up AWS Cognito User Pool in Our Console

Amazon Cognito is a fully managed user authentication and authorization service. It allows developers to easily add user sign-up, sign-in, and access control to their applications, and provides scalable and secure user management features. With Amazon Cognito, developers can create user pools to manage user authentication and registration, and identity pools to manage user access to AWS resources

**User pools** are a core feature of Amazon Cognito. A user pool is a collection of users who sign up for the same application. It stores user profile data, such as email addresses, usernames, and passwords, and allows users to sign in using a variety of authentication methods etc. Check this [link](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html) for more explanation of this service.

In Our AWS Console, I went to the **Amazon Cognito Service**. Furthermore, I completed several steps to create a new userpool. 


**Step 1:**
- In the `Provider types` section under `Authentication Providers`, select `Cognito user pool` as shown below:

- I went to the `Cognito user pool sign-in options`, then i made sure to select only the `User name` and `Email` attributes as those were the two options needed to be selected after recieving instructions from the live streamed class. The `Phone Number` attribute will require spend so we are trying to remain in the free tier region. **DO NOT** check any box for the `User name requirements`. Click **Next**



**Step 2:**
- In the `Password policy` section, we will be using the `Cognito defaults` for our project, but you can set a custom one if you want. 

- Next to the `Multi-factor authentication` section. We won't be using any MFA because this service is not included in the free tier. But, if you want to add an MFA, go over the [pricing](https://aws.amazon.com/cognito/pricing/) before implementation. 

- In the `User account recovery` section, check the box that says `Enable self-service account recovery`. This feature enables users to be able to reset their password whenever they want.

- Now select the `Email only` option. We are using this feature because it is free. If you want to use the SMS option, check out the [pricing](https://aws.amazon.com/sns/sms-pricing/). Click **Next**


**Step 3:**
- In the `Self-service sign-up` section, make sure you check the box that says ` Enable self-registration`.

- Next to the `Attribute verification and user account confirmation` section. Make sure to leave the default selections. See the image below:

- In the `Required attributes` section, add some additional required attributes - `name` and `preferred_username`. 

**Note: Required attributes can't be changed once this user pool has been created.**

The `custom attributes` are optional to set since we will be using a database to store our data. Click **Next**

**Step 4:**
- In the `Email provider` section, change the selection to `Send email with Cognito`. After that, leave the default selection that comes with the option. Click **Next**

**Step 5:**
- In the `User pool name` section, add a name of your choice; mine was `cruddur-suer-pool`.

**Note: Your user pool name can't be changed once this user pool is created.**

- Next to the `Hosted authentication pages` section, **DON'T** check the box that says `Use the Cognito Hosted UI`. We won't be using that feature for our project. 

- In the `Initial app client` section, select `Public client` as our `App type`.

- Add a name for the `App client name`; mine was `cruddur`. After that, leave the rest of the default selections and click **Next**


**Step 6:**
- In this section, we will review all our configurations and then go ahead to `Create user pool`. After creation, you should get this success message.


### 2. Configure Amazon Amplify

Amazon Amplify is a development platform that enables developers to build scalable and secure mobile and web applications. It provides a set of tools, libraries, and services that simplify the development process, allowing developers to focus on building high-quality applications rather than infrastructure. Check out this [link](https://aws.amazon.com/amplify/#:~:text=AWS%20Amplify%20is%20a%20complete,Build%20a%20frontend%20UI) for more explanation of this service.

I went ahead to configure Amazon Amplify. 

- In my **Terminal**, I navigated to the `frontend-react-js` directory, and ran this command:
```bash
# navigate to frontend-react-js
cd frontend-react-js/

# add aws-amplify library
npm i aws-amplify --save 
# the `--save` flag saves the library to your package.json file 
```

- I navigated into my `frontend-react-js/src/App.js` and added the following lines of code. Make sure to add it before the `const router` configuration. 

```js
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```

- Now I went ahead to set my environment variables from the code listed above. Go into your `docker-compose.yml` file, and under the `frontend-react-js` service, add the following lines:

```yaml
# AWS Amplify
REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
REACT_APP_AWS_USER_POOLS_ID: "${REACT_APP_AWS_USER_POOLS_ID}"
REACT_APP_CLIENT_ID: "${REACT_APP_CLIENT_ID}"
```

**NOTE** - To view my `user pool ID`, I selected the user pool name from the AWS console. For the `client ID`, click into the pool you created and look for the `App integration` tab as shown in the image below. Then scroll all the way down to view your `client ID`.

![Image of Cognito User pool ID](assets/week%203/Cognito%20User%20Pool%20ID.png)

- In the `frontend-react-js/src/pages/HomeFeedPage.js` file, add the follwoing lines of code:

```js
// AWS Amplify
import { Auth } from 'aws-amplify';

// DELETE THESE LINES
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


// ADD THESE LINES 
// check if we are authenicated
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};
```

- Then I updated my `frontend-react-js/src/components/ProfileInfo.js` file with the following contents:

```js
// DELETE THIS LINE 
import Cookies from 'js-cookie'

//ADD THIS LINE
// AWS Amplify
import { Auth } from 'aws-amplify';

// DELETE THESE LINES 
const signOut = async () => {
    console.log('signOut')
    // [TODO] Authenication
    Cookies.remove('user.logged_in')
    //Cookies.remove('user.name')
    //Cookies.remove('user.username')
    //Cookies.remove('user.email')
    //Cookies.remove('user.password')
    //Cookies.remove('user.confirmation_code')
    window.location.href = "/"
  }

// ADD THESE LINES 
const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```

[Image of ProfileInfo js](assets/week%203/ProfileInfo.png)

After placing the codes into their respective files, I went ahead to spin up my application to be sure everything still works. 

```bash
docker compose up
```
Or right click on the `docker-compose-yaml` file to run `compose up`.

I encountered some error, follow the instructions below to resolve them.

**Debugging**

- After the initial start-up of my frontend application on `3000`port, I got a blank page and an error after i inspected the page. 

![Image of Blank Page](assets/week%203/Blank%20Page.png)
![Image of UserPoolId and ClientId Error](assets/week%203/UserPool%20Id%20and%20ClientId%20Error.png)

**Error message:** `Uncaught Error: Both UserPoolId and ClientId are required.`

Follow the steps below to resolve them. 
- First, I checked my environment variables in our `frontend-react-js` container. Do that by manually attaching a shell to the container, and type `env` to verify the variables are actually set in the container.

![Image of Frontend variables](assets/week%203/frontend%20variables.png)

- Second, I navigated into my `App.js` and `docker-compose.yml` files to double-check if the env variables are rightly spelled out or configured. In the `App.js` file make these changes:

```js
// Replace the Auth{} section with this revised code 
Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
```

Both steps should resolve the error. But I forgot to remove the comments placed on my CloudWatch Code so I could not see it at first but i rectified the issue. Then I was able to see my `frontend` again. 

![Image of Logger](assets/week%203/Logger.png)
![Image of Blank front](assets/week%203/BlankFront.png)
![Image of FrontEnd](assets/week%203/FrontEnd.png)

### 3. Implementing Custom SignIn Page 

I configured my `SignIn` page. Go to your `frontend-react-js/src/pages/SigninPage.js` file and add the following lines of code:

```js
// AWS Amplify
// DELETE this line 
import Cookies from 'js-cookie'

// ADD this line instead
import { Auth } from 'aws-amplify';

// DELETE these line 
const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    console.log('onsubmit')
    if (Cookies.get('user.email') === email && Cookies.get('user.password') === password){
      Cookies.set('user.logged_in', true)
      window.location.href = "/"
    } else {
      setErrors("Email and password is incorrect or account doesn't exist")
    }
    return false
  }

// ADD these lines instead
const onsubmit = async (event) => {
  setErrors('')
  event.preventDefault();
  try {
    Auth.signIn(email, password)
      .then(user => {
        localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
        window.location.href = "/"
      })
      .catch(err => { console.log('Error!', err) });
  } catch (error) {
    if (error.code == 'UserNotConfirmedException') {
      window.location.href = "/confirm"
    }
    setCognitoErrors(error.message)
  }
  return false
}
```

After placing the codes into their respective files, I went ahead to spin up my application to be sure everything still works.

```bash
docker compose up
```
Or right click on the `docker-compose-yaml` file to run `compose up`.

Then I tried signing in to my frontend and see if i got any errors. If you do, you are on the right track. Follow the steps below to resolve them.


**Debugging**

If you got the error message `Incorrect username or password` in your debug page instead of the UI, go ahead into your `frontend-react-js/src/pages/SignInPage.js` file and make these adjustments to correct the error display. 

```js
// Replace your previous "onsubmit" constant with the following
const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    Auth.signIn(email, password)
      .then(user => {
        localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
        window.location.href = "/"
      })
      .catch(error => {
        if (error.code == 'UserNotConfirmedException') {
          window.location.href = "/confirm"
        }
        setErrors(error.message)
      }); 
      return false
  }
```

After the code adjustments, I refreshed my frontend and try logging in with fake credentials. Now you should get an error message displayed on the page like so:

![Image of SignIn Error](assets/week%203/SignIn%20Error.png)


**Testing**

I tested my application with a real user. Then I created my first user through the AWS console. 

- In the AWS console, I navigated to **Cognito** where i created the user pool. Under the `User` tab, click the `Create user` button to create a user. 

- In the `User name` section, enter any username of your choice. I did the same for the `Email address`. Make sure your email is real this time around.

![Image of Cognito User Creation](assets/week%203/New%20User.png)

- After creation, I got an email with your **username** and **temporary password**.

If while trying to log in with the newly created credentials and you get an error, follow the steps below to resolve them. 


*Debugging*

In your **Terminal** run the following command:

```bash
# to make sure your AWS credentials are properly set
aws sts get-caller-identity

# change user's password and update status
aws cognito-idp admin-set-user-password --user-pool-id <your-user-pool-id> --username <your-username> --password <your-password> --permanent
```
![Image of Identity](assets/week%203/identity.png) 

After the configuration, you should now be able to log into the application. 


### 4. Change The Display Name and Handle

I changed the display name `My Name` and `@handle` to a name of my choice:

![Image of Changing Display Name](assets/week%203/Changing%20Display%20Name.png)

- In my AWS console, navigate to **Cognito** and select the created **user** you just created. 

- Under `User attributes`, select `Edit`

- Now give `preferred_name` and `username` of your choice. Click `Save changes`. Now log back in and you should see the **name** and **handle** you configured. 

![Image of Changed Display Name](assets/week%203/Changed%20Display%20Name.png)


