resource "aws_ssm_document" "document_1" {
  name          = "test_document"
  document_type = "Command"

  content = <<DOC
  
  
  {
    "schemaVersion": "2.2",
    "description": "Execution of playbook.",

    "parameters": {
        "check": {
            "allowedValues": [
                "True",
                "False"
            ],
            "default": "False",
            "description": " (Optional) Use the check parameter to perform a dry run of the Ansible execution.",
            "type": "String"
        },
        "extravars": {
            "allowedPattern": "^((^|\\s)\\w+=(\\S+|'.*'))*$",
            "default": "SSM=True",
            "description": "(Optional) Additional variables to pass to Ansible at runtime. Enter a space separated list of key/value pairs. For example: color=red flavor=lime",
            "displayType": "textarea",
            "type": "String"
        },
	"playbook": {
            "default":"", 
            "description": "(Optional) If you don't specify a URL, then you must specify playbook YAML in this field.",
            "displayType": "textarea",
            "type": "String"
        },
        "playbookurl": {
            "allowedPattern": "^\\s*$|^(http|https|s3)://[^']*$",
            "default": "https://playbookssm.s3.ap-south-1.amazonaws.com/playbookssm.yml",
            "description": "(Optional) If you don't specify playbook YAML, then you must specify a URL where the playbook is stored. You can specify the URL in the following formats: http://example.com/playbook.yml  or s3://examplebucket/plabook.url. For security reasons, you can't specify a URL with quotes.",
            "type": "String"
        },
        "timeoutSeconds": {
            "default": "3600",
            "description": "(Optional) The time in seconds for a command to be completed before it is considered to have failed.",
            "type": "String"
        }
    },

    "mainSteps": [
        {
            "action": "aws:runShellScript",
            "inputs": {
                "runCommand": [
                    "#!/bin/bash",
                    "ansible --version",
                    "if [ $? -ne 0 ]; then",
                    " echo \"Ansible is not installed. Please install Ansible and rerun the command\" >&2",
                    " exit 1",
                    "fi",
                    "execdir=$(dirname $0)",
                    "cd $execdir",
                    "if [ -z '{{playbook}}' ] ; then",
                    " if [[ \"{{playbookurl}}\" == http* ]]; then",
                    "   wget '{{playbookurl}}' -O playbook.yml",
                    "   if [ $? -ne 0 ]; then",
                    "       echo \"There was a problem downloading the playbook. Make sure the URL is correct and that the playbook exists.\" >&2",
                    "       exit 1",
                    "   fi",
                    " elif [[ \"{{playbookurl}}\" == s3* ]] ; then",
                    "   aws --version",
                    "   if [ $? -ne 0 ]; then",
                    "       echo \"The AWS CLI is not installed. The CLI is required to process Amazon S3 URLs. Install the AWS CLI and run the command again.\" >&2",
                    "       exit 1",
                    "   fi",
                    "   aws s3 cp '{{playbookurl}}' playbook.yml",
                    "   if [ $? -ne 0 ]; then",
                    "       echo \"Error while downloading the document from S3\" >&2",
                    "       exit 1",
                    "   fi",
                    " else",
                    "   echo \"The playbook URL is not valid. Verify the URL and try again.\"",
                    " fi",
                    "else",
                    " echo '{{playbook}}' > playbook.yml",
                    "fi",
                    "if  [[ \"{{check}}\" == True ]] ; then",
                    "   ansible-playbook -i \"localhost,\" --check -c local -e \"{{extravars}}\" playbook.yml",
                    "else",
                    "   ansible-playbook -i \"localhost,\" -c local -e \"{{extravars}}\" playbook.yml",
                    "fi"
                ],
                "timeoutSeconds": "{{ timeoutSeconds }}"
            },
                    "name": "runShellScript"
        }
    ]

  }


DOC
}



resource "aws_ssm_association" "association_1" {
  name = aws_ssm_document.document_1.name

  targets {
    key    = "InstanceIds"
    values = ["i-0648a37f8f3ac7465"]
  }
}
