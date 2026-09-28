// Minimal CDK app used by scripts/smoke-synth.sh to prove the Java image can synth a real stack.
package smoke;

import software.amazon.awscdk.App;
import software.amazon.awscdk.Duration;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.services.s3.Bucket;
import software.amazon.awscdk.services.sqs.Queue;

public final class SmokeApp {
    public static void main(final String[] args) {
        App app = new App();
        Stack stack = new Stack(app, "SmokeStack");
        Bucket.Builder.create(stack, "Bucket").versioned(true).build();
        Queue.Builder.create(stack, "Queue").visibilityTimeout(Duration.seconds(60)).build();
        app.synth();
    }
}
