package test

import (
    "os"
	"testing"
    "fmt"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformHelloWorldExample(t *testing.T) {
    os.Setenv("TERRATEST_IAM_ROLE", "arn:aws:iam::246402711611:role/AdministratorAccess")

    expectedEnvironment := "AutoTestEnv"
    expectedProject := "AutoTestProject"
    expectedWebhooks := []string{"test_hook_1", "test_hook_2"}

	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"environment":        expectedEnvironment,
			"project": expectedProject,
			"webhooks":            expectedWebhooks,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
    hook_1 := fmt.Sprintf("/%v/%v/webhooks/0", expectedProject, expectedEnvironment)
    hook_2 := fmt.Sprintf("/%v/%v/webhooks/1", expectedProject, expectedEnvironment)


	hook_1_param := aws.GetParameter(t, "eu-west-1", hook_1)
	hook_2_param := aws.GetParameter(t, "eu-west-1", hook_2)

	assert.Equal(t, "test_hook_1", hook_1_param)
	assert.Equal(t, "test_hook_2", hook_2_param)
}
