import * as cdk from "aws-cdk-lib";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as ecr from "aws-cdk-lib/aws-ecr";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as cloudfront from "aws-cdk-lib/aws-cloudfront";
import * as origins from "aws-cdk-lib/aws-cloudfront-origins";
import * as secretsmanager from "aws-cdk-lib/aws-secretsmanager";
import { Construct } from "constructs";

export class CurioStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // --- ECR Repository ---

    const repo = new ecr.Repository(this, "CurioRepo", {
      repositoryName: "curio",
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      lifecycleRules: [{ maxImageCount: 10 }],
    });

    // --- DynamoDB Tables ---

    const reviewsTable = new dynamodb.Table(this, "ReviewsTable", {
      tableName: "curio-reviews",
      partitionKey: { name: "media_key", type: dynamodb.AttributeType.STRING },
      sortKey: { name: "did", type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    reviewsTable.addGlobalSecondaryIndex({
      indexName: "RecentIndex",
      partitionKey: { name: "gsi1pk", type: dynamodb.AttributeType.STRING },
      sortKey: { name: "gsi1sk", type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    reviewsTable.addGlobalSecondaryIndex({
      indexName: "UserIndex",
      partitionKey: { name: "gsi2pk", type: dynamodb.AttributeType.STRING },
      sortKey: { name: "gsi2sk", type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    const oauthTable = new dynamodb.Table(this, "OAuthTable", {
      tableName: "curio-oauth",
      partitionKey: { name: "pk", type: dynamodb.AttributeType.STRING },
      sortKey: { name: "sk", type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // --- Secrets ---

    const tmdbSecret = secretsmanager.Secret.fromSecretNameV2(
      this,
      "TmdbSecret",
      "curio/tmdb-api-key"
    );

    // --- Lambda Function ---

    const imageTag = process.env.IMAGE_TAG ?? "latest";

    const fn = new lambda.DockerImageFunction(this, "CurioFn", {
      functionName: "curio",
      code: lambda.DockerImageCode.fromEcr(repo, { tagOrDigest: imageTag }),
      memorySize: 512,
      timeout: cdk.Duration.seconds(30),
      architecture: lambda.Architecture.ARM_64,
      environment: {
        PORT: "8080",
        NODE_ENV: "production",
        REVIEW_TABLE: reviewsTable.tableName,
        OAUTH_TABLE: oauthTable.tableName,
        TMDB_API_KEY: tmdbSecret.secretValue.unsafeUnwrap(),
        AWS_LWA_INVOKE_MODE: "response_stream",
      },
    });

    reviewsTable.grantReadWriteData(fn);
    oauthTable.grantReadWriteData(fn);
    tmdbSecret.grantRead(fn);

    // --- Lambda Function URL ---

    const fnUrl = fn.addFunctionUrl({
      authType: lambda.FunctionUrlAuthType.NONE,
      invokeMode: lambda.InvokeMode.RESPONSE_STREAM,
    });

    // --- CloudFront Distribution ---

    const distribution = new cloudfront.Distribution(this, "CurioCdn", {
      defaultBehavior: {
        origin: new origins.FunctionUrlOrigin(fnUrl),
        viewerProtocolPolicy:
          cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
        originRequestPolicy:
          cloudfront.OriginRequestPolicy.ALL_VIEWER_EXCEPT_HOST_HEADER,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
      },
      additionalBehaviors: {
        "/assets/*": {
          origin: new origins.FunctionUrlOrigin(fnUrl),
          viewerProtocolPolicy:
            cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        },
      },
    });

    // Update Lambda with the CloudFront PUBLIC_URL
    fn.addEnvironment(
      "PUBLIC_URL",
      `https://${distribution.distributionDomainName}`
    );

    // --- Outputs ---

    new cdk.CfnOutput(this, "CloudFrontUrl", {
      value: `https://${distribution.distributionDomainName}`,
    });

    new cdk.CfnOutput(this, "EcrRepoUri", {
      value: repo.repositoryUri,
    });

    new cdk.CfnOutput(this, "FunctionUrl", {
      value: fnUrl.url,
    });
  }
}
