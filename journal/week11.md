# Week 11/X — CleanUp 

Following the live-streamed vidoes on Week X by Andrew Brown and guest instructors, we were able to focus on cleaning up the application and ensuring it is in a stable state.

## CleanUp
This process involved a lot of changes which includes;

1. Refactor JWT to use decorator, by making changes to `backend-flask/app.py, backend-flask/lib/cognito_jwt_token.py and frontend-react-js/src/components/ReplyForm.js`

[Refactor JWT Commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/42bee47ef64a7cb893336a489b2be1fbc5ff348e#diff-0014cc1f7ffd53e63ff797f0f2925a994fbd6797480d9ca5bbc5dc65f1b56438)

2. Refactor app.py and flask routes, by making changes to backend-flask/app.py, backend-flask/lib/

```python
-cloudwatch.py
-cognito_jwt_token.py
-honeycomb.py
-rollbar.py
-xray.py
```
Also in the backend-flask/routes/

```python
-activities.py
-general.py
-messages.py
-users.py
```

And also made changes to `frontend-react-js/src/pages/NotificationsFeedPage.js.`

[Refactor app.py commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/add66069de6db39fdc41857db9f1aa7cd5d5ae3a)
[flask routes commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/e28c0f0f6a79c496597a49d220ed802f94f18da6)

3. Worked on replies, made a lot of changes to;

```sh
frontend-react-js/src/components/
-ActivityActionReply.js
-ActivityItem.css
-ActivityItem.js
-ReplyForm.js
```
[Replies commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/0489574cfac0ab50feeb6d12a933a6399b2505c9)

4. Refactoring error handling and fetch requests by making changes to;

backend-flask/db/sql/activities/home.sql and backend-flask/db/sql/activities/show.sql

```
frontend-react-js/src/components/
-ActivityActionReply.js
-ActivityFeed.css
-ActivityFeed.js
-ActivityForm.js
-FormErrorItem.js
-FormError.js
-FormError.css
-MessageForm.js
-ProfileForm.js
-ReplyForm.js
```
Also, made some changes in the frontend-react-js/src/pages (tree)
  [Refactoring error handling and fetch requests commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/2195586a8029913dae4f83a2beed2e1790a1beb6)

5. Activity show page was created by making new files called `Replies.js and Replies.css` in the `frontend-react-js/src/components/`, whilst making changes to existing files in the directory.

     [Activity show page commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/8d7f15092c73e6238a637f7f1bcfb6e1e46a2391)

6. Fixed migrations to include uuid instead of integer to the reply_to_activity column in our database.
   
     [Fixed migrations commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/261eeb7c6335bed022c769a74399eb7c971694f3)

7. Fixed template for sync changes and static-build compile errors.
    [Template changes commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/46409ac3433c5e32c28baab633d870ec001fcbbb)

8. Added dynamodb table column.
  [DynamoDB commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/e0b095d07c459b72366c221547835e87585cf89d)

9. Updated Service `template.yaml`
  [Service commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/0a031999fa4325b6082f3f07916f148ad560696d)
  
10. Created a machine template and config file and fixed frontend for `MessageGroupPage.js`
  [MachineUser commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/130024095c88b1b4522d26cc07b4d6f1707718b3)

11. Rollbar Fix for Updated Flask
  [UpdatedFlask commit](https://github.com/Firdous2307/aws-bootcamp-cruddur-2023/commit/7a154b196752119ddbcaa85e999d49757fa8826b)


## Proof of Implementation
![Image of Activities-Backend](assets/week%2011/backend%20activities.png)
![Image of Home Prod](assets/week%2011/home%20prod.png)
![Image of Local Home](assets/week%2011/local%20home.png)
![Image of MessageProd](assets/week%2011/new%20message%20prod.png)
![Image of ProfileProd](assets/week%2011/profile%20prod.png)
