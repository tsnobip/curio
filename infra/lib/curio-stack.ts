import * as cdk from "aws-cdk-lib";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as ecr from "aws-cdk-lib/aws-ecr";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as cloudfront from "aws-cdk-lib/aws-cloudfront";
import * as origins from "aws-cdk-lib/aws-cloudfront-origins";
import * as secretsmanager from "aws-cdk-lib/aws-secretsmanager";
import * as route53 from "aws-cdk-lib/aws-route53";
import * as route53Targets from "aws-cdk-lib/aws-route53-targets";
import * as acm from "aws-cdk-lib/aws-certificatemanager";
import { Construct } from "constructs";

const DOMAIN_NAME = "curio.social";

interface CurioStackProps extends cdk.StackProps {
  certificate: acm.ICertificate;
  hostedZoneId: string;
  hostedZoneName: string;
}

export class CurioStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: CurioStackProps) {
    super(scope, id, props);

    // --- ECR Repository (must exist before deploy — CI ensures it, see deploy workflow) ---

    const repo = ecr.Repository.fromRepositoryName(this, "CurioRepo", "curio");

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

    // --- DNS & Certificate ---

    const hostedZone = route53.HostedZone.fromHostedZoneAttributes(
      this,
      "HostedZone",
      {
        hostedZoneId: props.hostedZoneId,
        zoneName: props.hostedZoneName,
      }
    );

    const certificate = props.certificate;

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
        PUBLIC_URL: `https://${DOMAIN_NAME}`,
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
      domainNames: [DOMAIN_NAME],
      certificate,
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

    // --- DNS Record ---

    new route53.ARecord(this, "DnsRecord", {
      zone: hostedZone,
      target: route53.RecordTarget.fromAlias(
        new route53Targets.CloudFrontTarget(distribution)
      ),
    });

    // --- Outputs ---

    new cdk.CfnOutput(this, "SiteUrl", {
      value: `https://${DOMAIN_NAME}`,
    });

    new cdk.CfnOutput(this, "EcrRepoUri", {
      value: repo.repositoryUri,
    });
  }
}
