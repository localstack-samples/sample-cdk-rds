# Amazon RDS initialization using CDK

| Key          | Value                                                                |
| ------------ | -------------------------------------------------------------------- |
| Environment  | LocalStack, AWS                                                      |
| Services     | RDS, Lambda, SecretsManager, ECR                                     |
| Integrations | AWS CDK, AWS SDK for JavaScript                                      |
| Categories   | Databases                                                            |
| Level        | Intermediate                                                         |
| Use Case     | Cloud Pods, Pre-Seeding Databases                                    |
| GitHub       | [Repository link](https://github.com/localstack/amazon-rds-init-cdk) |

## Introduction

The Amazon RDS initialization using CDK sample application demonstrates how LocalStack supports RDS instances initialization using CDK and CloudFormation Custom Resources. The sample application implements a Node.js Lambda function for compute layer, which is able to run custom SQL scripts. It also executes custom commands supported by the [Node.js client for MySQL2](https://www.npmjs.com/package/mysql2). To test this application sample, we will demonstrate how you use LocalStack to deploy the infrastructure on your developer machine and your CI environment and use a Lambda function to run queries against the RDS database after successful deployment. We will also show how to pre-seed the RDS database with dummy data and use Cloud Pods to load resources instantly without full redeploys, reducing test execution time.

## Architecture

The following diagram shows the architecture that this sample application builds and deploys:

![Architecture Diagram demonstrating Amazon RDS initialization using CDK](images/architecture-diagram.png)

* [RDS](https://docs.localstack.cloud/user-guide/aws/rds/) as the central part of the sample application which is initialized and pre-filled with data.
* [Lambda](https://docs.localstack.cloud/user-guide/aws/lambda/) to initialize the database, and query data
* [Secrets Manager](https://docs.localstack.cloud/user-guide/aws/secretsmanager/) to store the credentials and configuration of the RDS database.

## Prerequisites

- [`localstack` CLI](https://docs.localstack.cloud/getting-started/installation/#localstack-cli) with a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/getting-started/auth-token/).
- [AWS CLI](https://docs.localstack.cloud/user-guide/integrations/aws-cli/) with the [`awslocal` wrapper](https://docs.localstack.cloud/user-guide/integrations/aws-cli/#localstack-aws-cli-awslocal).
- [CDK](https://docs.localstack.cloud/user-guide/integrations/aws-cdk/) with the [`cdklocal`](https://www.npmjs.com/package/aws-cdk-local) wrapper.
- [Node.js](https://nodejs.org/en/download/)
- [`make`](https://www.gnu.org/software/make/) (**optional**, but recommended for running the sample application)

## Installation

To run the sample application, you need to install the required dependencies.

First, clone the repository:

```shell
git clone https://github.com/localstack-samples/sample-cdk-rds.git
```

Then, navigate to the project directory:

```shell
cd sample-cdk-rds
```
Next, install the project dependencies by running the following command:

```shell
make install
```

## Deployment

Start LocalStack with the `LOCALSTACK_AUTH_TOKEN` pre-configured:

```shell
localstack auth set-token <your-auth-token>
localstack start
```

> By default, LocalStack uses the MariaDB engine (see [RDS documentation](https://docs.localstack.cloud/user-guide/aws/rds/#mysql-engine)). To use the real MySQL engine in a separate Docker container, set the environment variable `RDS_MYSQL_DOCKER=1`.

To deploy the sample application, run the following command:

```shell
make deploy
```

The output will be similar to the following:

```shell
Outputs:
RdsInitExample.RdsInitFnResponse = {"status":"OK","results":[/*...SQL operations...*/]}
RdsInitExample.functionName = my-lambda-rds-query-helper
RdsInitExample.secretName = /rdsinitexample/rds/creds/mysql-01
Stack ARN:
arn:aws:cloudformation:us-east-1:000000000000:stack/RdsInitExample/3f53b7bd

✨  Total time: 80.21s

CDK deployed successfully.
```

-   `RdsInitExample.RdsInitFnResponse` shows the result of running the SQL script at `demos/rds-init-fn-code/script.sql`.
-   `RdsInitExample.functionName` is the function name used to run test queries on RDS.
-   `RdsInitExample.secretName` is the secret name with database info, required by the Lambda to run queries.

## Testing

The sample application sets up the database by creating tables and inserting dummy data. It includes a Lambda function named `my-lambda-rds-query-helper`, which is used to run SQL queries against the RDS database.

This function requires two parameters: 

- `sqlQuery`, which specifies the SQL command to execute
-  `secretName`, which provides the name of the secret containing the database connection details.

To run a query using AWS CLI, you can invoke the Lambda function with the following command:

```shell
make run
```

The output will contain the execution status and results, for example:

```shell
{"status":"SUCCESS","results":[{"Author":"Jane Doe"},{"Author":"Jane Doe"},{"Author":"LocalStack"}]}
```

You can run full end-to-end integration tests using the following command:

```shell
make test
```

## Use Cases

### Pre-seeding Databases

In the sample, we set up the database by creating tables and adding dummy data using the `demos/rds-init-fn-code/scripts.sql` script.

The setup process can be enhanced to cover various use cases, including:

- Initializing databases.
- Initializing and maintaining users and their permissions.
- Initializing and maintaining stored procedures, views, or other database resources.
- Executing custom logic as part of a resource initialization process.
Improving segregation of duties and least privilege by providing a flexible hook in the Infrastructure-as-Code (IaC) to manage RDS instance initialization.
- Initializing database tables (see note below).
- Seeding database tables with initial datasets (see note below).

> [!NOTE]
> Application-specific initialization logic, such as defining the structure of database tables and seeding them with initial data, is typically managed on the application side. It is generally recommended to keep infrastructure initialization/management separate from application-specific initialization.

### Cloud Pods

Cloud Pods are persistent state snapshots of your LocalStack instance that can be stored, versioned, shared, and restored. They enable reproducible environments for development and testing.

In this sample, Cloud Pods are utilized to streamline the CI workflow by pre-seeding the LocalStack environment with the necessary infrastructure and data. This approach eliminates the need to redeploy and reinitialize resources from scratch in every CI job, thereby reducing setup time and ensuring consistency across test runs.

The `.github/workflows/cloud-pods.yml` file demonstrates this workflow:

- The `create-cloud-pod` job deploys the infrastructure using CDK and saves the LocalStack state as a Cloud Pod.
- The `test-cloud-pod` job loads the saved Cloud Pod and runs integration tests against the pre-seeded environment.

This setup ensures that your CI pipeline can quickly spin up a fully-initialized environment, leading to faster and more reliable test executions.

## Summary

This sample helps you locally provision, initialize, and test an Amazon RDS database using AWS CDK and LocalStack. This showcases the following patterns:

- Defining and deploying RDS, Lambda, and Secrets Manager resources using AWS CDK.
- Executing SQL scripts during deployment via a Lambda function to set up the database schema and seed data.
- Leveraging LocalStack to emulate AWS services locally, enabling offline development and testing.
- Utilizing Cloud Pods to save and load LocalStack states, facilitating faster and more consistent CI test runs.
- Ensuring consistent & reproducible development and testing environments by restoring from Cloud Pods.

## Learn More

- Details about the original sample are available in the AWS blog post: [Use AWS CDK to initialize Amazon RDS instances](https://aws.amazon.com/blogs/infrastructure-and-automation/use-aws-cdk-to-initialize-amazon-rds-instances/). 
- Additional technical implementation details are provided in the [original sample’s documentation](https://github.com/aws-samples/amazon-rds-init-cdk?tab=readme-ov-file#technical-implementation).
- For more information about Cloud Pods, visit the [LocalStack documentation](https://docs.localstack.cloud/user-guide/state-management/cloud-pods/).
- For more information about deploying CDK applications on LocalStack, visit the [LocalStack documentation](https://docs.localstack.cloud/user-guide/integrations/aws-cdk/).
