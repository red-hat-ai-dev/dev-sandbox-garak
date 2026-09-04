# Garak Red Team Testing for Granite 3.1-8B

## Setup

Deploy the garak pod:
```bash
oc apply -f garak-pod.yaml
```

Wait for pod to be ready (takes ~2 minutes to install garak):
```bash
oc wait --for=condition=Ready pod/garak-redteam -n (your namespace) --timeout=300s
```

## Run Tests

Use the provided script:
```bash
./run-garak.sh
```

Or manually:
```bash
TOKEN=$(oc whoami -t)

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
```

## Available Probes

List all available probes:
```bash
oc exec garak-redteam -n (your namespace) -- python -m garak --list_probes
```

Common probe categories:
- `continuation` - Harmful content continuation
- `dan` - Jailbreak attempts
- `encoding` - Encoding-based bypasses
- `promptinject` - Prompt injection attacks

## Retrieve Results

```bash
# List reports
oc exec garak-redteam -n (your namespace) -- ls -lh ~/.local/share/garak/garak_runs/

# Copy report locally
oc cp rh-ee-sbowerma-dev/garak-redteam-soyr-redhat:/opt/app-root/src/.local/share/garak/garak_runs/granite-31-redteam.report.jsonl ./granite-31-redteam.report.jsonl
```

## Cleanup

```bash
oc delete pod garak-redteam -n (your namespace)
```
