# Provisionning - Terraform - Openbao

## Prerequisites

- vault-provider 4.8.0
- access to a postgresql database for the remote backend

## Steps

1. Configure kubernetes auth for openbao instance
2. Create a kv per kubernetes workload / namespaces
3. Create a shared kv
4. Create a policy for each kv restricting kv per namespace

## How to use

When I have a new workload / namespace on Kubernetes needing secrets, I just have to add it to namespaces in tfvars and launch the following commands :

```bash
tofu plan
```

```bash
tofu apply
```
