import * as cdk from "aws-cdk-lib";
import * as acm from "aws-cdk-lib/aws-certificatemanager";
import * as route53 from "aws-cdk-lib/aws-route53";
import { Construct } from "constructs";

const DOMAIN_NAME = "curio.social";

export class CertificateStack extends cdk.Stack {
  public readonly certificate: acm.ICertificate;
  public readonly hostedZoneId: string;
  public readonly hostedZoneName: string;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const hostedZone = route53.HostedZone.fromLookup(this, "HostedZone", {
      domainName: DOMAIN_NAME,
    });

    this.certificate = new acm.Certificate(this, "Certificate", {
      domainName: DOMAIN_NAME,
      validation: acm.CertificateValidation.fromDns(hostedZone),
    });

    this.hostedZoneId = hostedZone.hostedZoneId;
    this.hostedZoneName = hostedZone.zoneName;
  }
}
