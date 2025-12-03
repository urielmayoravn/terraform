# 🚀 AWS Lambda Python Deployment Guide

This guide outlines the workflow for developing an AWS Lambda function in Python and generating the necessary deployment archive (`.zip`) to upload the function and all its dependencies to AWS.

## 📋 1. Prerequisites

Ensure you have the following installed:

- Python 3.x
- pip (Python package installer)
- venv (Python virtual environment module)

## 🏗️ 2. Project Structure

Create a directory for your project and define your function code and dependencies.

```
/my-lambda-app
├── handler.py      # Your Lambda function code
└── requirements.txt # List of dependencies
```

`handler.py` (Code Example):

```py
import json
import requests # Example of an external library

def lambda_handler(event, context):
    try:
        # Using the requests library (needs to be packaged)
        response = requests.get("https://api.github.com/users/octocat")
        data = response.json()

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Success!', 'github_user': data['login']})
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

`requirements.txt` (Dependencies Example):

```
requests
```

OBS: you can use `pip install <package>` and then use `pip freeze > requirements.txt` with your environment activated to generte the requirements file

## 📦 3. Deployment Package Creation Process `(.zip)`

This process uses a virtual environment to isolate and gather only the necessary libraries for your function, as suggested by AWS documentation.

### Step 3.1: Setup and Dependency Installation

1. Create a virtual environment:
   ```
   python -m venv <virtual_env>
   ```
2. activate the virtual environment:
   ```
   source <virtual_env>/bin/activate
   ```
3. Install the dependencies from requirements.txt:
   ```
   pip install -r requirements.txt
   ```

Skip this if you followed the observation

### Step 3.2: Package Libraries and Code

Now, we move the necessary files to create the ZIP structure that Lambda expects: all dependencies at the root of the `.zip`, alongside your `handler.py`.

1. Naviage to the package folder and geneate a zip in the lambda root directory
   ```
   cd <virtual_env>/lib/python3.x/site-packages
   zip -r ../../../../deployment_package.zip .
   ```
2. Return to the main project directory and add the `handle.py` to the zip:
   ```
   cd ../../../../
   zip deployment_package.zip lambda_function.py
   ```

## And you are done!!

For more information visit [THIS AWS DOCS PAGE](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html#python-package-create-dependencies)
