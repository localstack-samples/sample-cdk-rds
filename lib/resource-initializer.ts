// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import * as ec2 from 'aws-cdk-lib/aws-ec2'
import * as lambda from 'aws-cdk-lib/aws-lambda'
import { Construct } from 'constructs'
import { Duration, Stack } from 'aws-cdk-lib'
import { AwsCustomResource, AwsCustomResourcePolicy, AwsSdkCall, PhysicalResourceId } from 'aws-cdk-lib/custom-resources'
import { RetentionDays } from 'aws-cdk-lib/aws-logs'
import { PolicyStatement, Role, ServicePrincipal } from 'aws-cdk-lib/aws-iam'
import { createHash } from 'crypto'

export interface CdkResourceInitializerProps {
  vpc: ec2.IVpc
  subnetsSelection: ec2.SubnetSelection
  fnSecurityGroups: ec2.ISecurityGroup[]
  fnTimeout: Duration
  fnCode: lambda.DockerImageCode
  fnLogRetention: RetentionDays
  fnMemorySize?: number
  config: any
}

export class CdkResourceInitializer extends Construct {
  public readonly response: string
  public readonly customResource: AwsCustomResource
  public readonly function: lambda.Function

  constructor (scope: Construct, id: string, props: CdkResourceInitializerProps) {
    super(scope, id)

    const stack = Stack.of(this)

    const fnSg = new ec2.SecurityGroup(this, 'ResourceInitializerFnSg', {
      securityGroupName: `${id}ResourceInitializerFnSg`,
      vpc: props.vpc,
      allowAllOutbound: true
    })

    const fn = new lambda.DockerImageFunction(this, 'ResourceInitializerFn', {
      memorySize: props.fnMemorySize || 128,
      functionName: `${id}-ResInit${stack.stackName}`,
      code: props.fnCode,
      vpcSubnets: props.vpc.selectSubnets(props.subnetsSelection),
      vpc: props.vpc,
      securityGroups: [fnSg, ...props.fnSecurityGroups],
      timeout: props.fnTimeout,
      logRetention: props.fnLogRetention
    })

    const payload: string = JSON.stringify({
      params: {
        config: props.config
      }
    })

    const payloadHashPrefix = createHash('md5').update(payload).digest('hex').substring(0, 6)

    const sdkCall: AwsSdkCall = {
      service: 'Lambda',
      action: 'invoke',
      parameters: {
        FunctionName: fn.functionName,
        Payload: payload
      },
      physicalResourceId: PhysicalResourceId.of(`${id}-AwsSdkCall-${fn.currentVersion.version + payloadHashPrefix}`)
    }
    
    // IMPORTANT: the AwsCustomResource construct deploys a singleton AWS Lambda function that is re-used across the same CDK Stack,
    // because it is intended to be re-used, make sure it has permissions to invoke multiple "resource initializer functions" within the same stack and it's timeout is sufficient.
    // @see: https://github.com/aws/aws-cdk/blob/cafe8257b777c2c6f6143553b147873d640c6745/packages/%40aws-cdk/custom-resources/lib/aws-custom-resource/aws-custom-resource.ts#L360
    const customResourceFnRole = new Role(this, 'AwsCustomResourceRole', {
      assumedBy: new ServicePrincipal('lambda.amazonaws.com')
    })
    customResourceFnRole.addToPolicy(
      new PolicyStatement({
        resources: [`arn:aws:lambda:${stack.region}:${stack.account}:function:*-ResInit${stack.stackName}`],
        actions: ['lambda:InvokeFunction']
      })
    )
    this.customResource = new AwsCustomResource(this, 'AwsCustomResource', {
      policy: AwsCustomResourcePolicy.fromSdkCalls({ resources: AwsCustomResourcePolicy.ANY_RESOURCE }),
      onUpdate: sdkCall,
      timeout: Duration.minutes(10),
      role: customResourceFnRole
    })

    this.response = this.customResource.getResponseField('Payload')

    this.function = fn
  }
}
