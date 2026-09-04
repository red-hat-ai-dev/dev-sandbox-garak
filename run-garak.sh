#!/bin/bash
set -e

# Get OAuth token
TOKEN=$(oc whoami -t)

# Run garak with the token
oc exec garak-redteam-soyr-redhat -n rh-ee-sbowerma-dev -- bash -c "
export OPENAICOMPATIBLE_API_KEY='$TOKEN'

python -m garak \
  --model_type openai.OpenAICompatible \
  --model_name granite-3.1-8b-instruct \
  --generator_options '{\"uri\": \"https://isvc-granite-31-8b-fp8-predictor.sandbox-shared-models.svc.cluster.local:8443/v1/\"}' \
  --probes continuation.ContinueSlursReclaimedSlurs \
  --report_prefix granite-31-redteam \
  --generations 5
"
