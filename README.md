# Garak Red Team Testing for Granite 3.1-8B

Red team testing setup for Granite 3.1-8B model using NVIDIA's garak vulnerability scanner.

## Architecture

```
garak pod → OAuth proxy pod (port 8000) → Granite endpoint (with OAuth)
```

The Granite endpoint requires OAuth authentication. Garak's `OpenAICompatible` generator doesn't support custom URIs (hardcoded to `localhost:8000`), so we:
1. Deploy an OAuth proxy that forwards requests to Granite with authentication
2. Patch garak to use the proxy service instead of localhost

## Setup

### 1. Deploy garak pod

```bash
oc apply -f garak-pod.yaml
oc wait --for=condition=Ready pod/garak-redteam --timeout=300s
```

### 2. Run tests

```bash
./run-garak.sh
```

This script:
- Detects your current namespace automatically
- Deploys the OAuth proxy with your current token
- Patches garak to use the proxy
- Runs a red team test

## Available Probes

List all probes:
```bash
oc exec garak-redteam -- python -m garak --list_probes
```

Common categories:
- `continuation` - Harmful content continuation (slurs, etc.)
- `dan` - Jailbreak attempts (DAN, DUDE, etc.)
- `encoding` - Encoding-based bypasses
- `promptinject` - Prompt injection attacks
- `goodside` - Riley Goodside's adversarial prompts
- `malwaregen` - Malware generation attempts

## Custom Tests

Run specific probes:
```bash
oc exec garak-redteam -- bash -c "
export OPENAICOMPATIBLE_API_KEY='dummy'
python -m garak \
  --model_type openai.OpenAICompatible \
  --model_name isvc-granite-31-8b-fp8 \
  --probes dan,encoding,promptinject \
  --report_prefix custom-test \
  --generations 10
"
```

## Retrieve Results

```bash
NAMESPACE=$(oc project -q)

# List reports
oc exec garak-redteam -- ls -lh ~/.local/share/garak/garak_runs/

# Copy report locally
oc cp $NAMESPACE/garak-redteam:/opt/app-root/src/.local/share/garak/garak_runs/granite-31-redteam.report.jsonl ./report.jsonl

# View HTML report
oc exec garak-redteam -- cat ~/.local/share/garak/garak_runs/granite-31-redteam.report.html > report.html
open report.html
```

## Cleanup

```bash
oc delete pod garak-redteam granite-oauth-proxy
oc delete service granite-oauth-proxy
```
