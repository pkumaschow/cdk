# Minimal CDK app used by scripts/smoke-synth.sh to prove the image can synth a real stack.
import aws_cdk as cdk
from aws_cdk import aws_s3 as s3
from aws_cdk import aws_sqs as sqs

app = cdk.App()
stack = cdk.Stack(app, "SmokeStack")
s3.Bucket(stack, "Bucket", versioned=True)
sqs.Queue(stack, "Queue", visibility_timeout=cdk.Duration.seconds(60))
app.synth()
