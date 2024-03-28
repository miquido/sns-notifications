package test

import (
	"fmt"
	"math/rand"
	"os"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformHelloWorldExample(t *testing.T) {
	os.Setenv("TERRATEST_IAM_ROLE", "arn:aws:iam::246402711611:role/AdministratorAccess")

	expectedEnvironment := "AutoTestEnv"
	expectedProject := "AutoTestProject"
	expected_region := "eu-west-1"

	testTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./lambda_test",
	})

	defer terraform.Destroy(t, testTerraformOptions)

	terraform.InitAndApply(t, testTerraformOptions)

	webhook_url := terraform.Output(t, testTerraformOptions, "url")
	result_ssm := terraform.Output(t, testTerraformOptions, "ssm")

	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"environment": expectedEnvironment,
			"project":     expectedProject,
			"webhooks":    []string{webhook_url},
		},
	})
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	sns_arn := terraform.Output(t, terraformOptions, "sns_arn")
	snsClient := aws.NewSnsClient(t, expected_region)

	test_message := fmt.Sprintf("Test-%v", rand.Int())
	snsClient.Publish(&sns.PublishInput{TopicArn: &sns_arn, Message: &test_message})

	time.Sleep(10 * time.Second)

	result := aws.GetParameter(t, expected_region, result_ssm)
	assert.Equal(t, fmt.Sprintf("{\"text\": \"%v\"}", test_message), result)
}
