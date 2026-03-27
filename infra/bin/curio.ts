#!/usr/bin/env node
import * as cdk from "aws-cdk-lib";
import { CertificateStack } from "../lib/certificate-stack";
import { CurioStack } from "../lib/curio-stack";

const app = new cdk.App();

const account = process.env.CDK_DEFAULT_ACCOUNT;
const region = process.env.CDK_DEFAULT_REGION ?? "eu-west-1";

const certStack = new CertificateStack(app, "CurioCertificateStack", {
  env: { account, region: "us-east-1" },
  crossRegionReferences: true,
});

new CurioStack(app, "CurioStack", {
  env: { account, region },
  crossRegionReferences: true,
  certificate: certStack.certificate,
  hostedZoneId: certStack.hostedZoneId,
  hostedZoneName: certStack.hostedZoneName,
});
