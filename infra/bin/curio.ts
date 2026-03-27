#!/usr/bin/env node
import * as cdk from "aws-cdk-lib";
import { CurioStack } from "../lib/curio-stack";

const app = new cdk.App();

new CurioStack(app, "CurioStack", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION ?? "eu-west-1",
  },
});
