# 🚀 Writing Your First Terraform Code Using GitHub Copilot

### With the Terraform MCP Server — Microsoft Azure Edition

![VS Code](https://img.shields.io/badge/VS%20Code-1.90%2B-blue?logo=visualstudiocode) ![azurerm](https://img.shields.io/badge/azurerm-v3%2Fv4-purple?logo=terraform) ![Node.js](https://img.shields.io/badge/Node.js-18%2B-green?logo=nodedotjs) ![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-7B42BC?logo=terraform)

> 📅 **Session format:** 20 min presentation · 20 min live demo

---

## 📋 Agenda

| # | Topic | Time |
|---|-------|------|
| 1 | What is GitHub Copilot | 5 min |
| 2 | What is Terraform MCP Server | 5 min |
| 3 | Setting up MCP in VS Code | 5 min |
| 4 | Prompt tips for Azure Terraform | 5 min |
| 5 | Live Demo | 20 min |

---

## Part 1 — GitHub Copilot

**What it is:** GitHub Copilot is an AI pair programmer built into VS Code, powered by OpenAI models. It assists developers by suggesting code completions, generating entire functions, and answering questions in natural language — all without leaving the editor.

**Four modes:**

| Mode | Description |
|------|-------------|
| Ghost text | Inline code suggestions — press **Tab** to accept |
| Copilot Chat | Side-panel chat for questions, generation, and review |
| Inline chat | Open with **Ctrl+I** directly in your editor |
| Agent mode | Autonomous multi-step tasks — requires VS Code 1.90+ |

**Why it matters for Azure IaC:** The `azurerm` provider has 1000+ resources and dozens of nested block structures. Without grounded context, AI models guess at argument names. The Terraform MCP Server gives Copilot the correct argument structure on the first try — no hallucinations, no deprecated fields.

---

## Part 2 — Terraform MCP Server

**What is MCP:** The Model Context Protocol (MCP) is an open standard created by Anthropic that lets AI assistants connect to live, structured data sources. Instead of relying solely on training data, Copilot can query real-time tool servers for accurate, up-to-date information.

**Capabilities:**

| Capability | Description |
|------------|-------------|
| Resource schemas | Live argument names and types from the Terraform registry |
| Provider docs | Up-to-date documentation for every azurerm resource |
| Module metadata | Registry module inputs, outputs, and submodule structure |
| No hallucinations | Answers grounded in real schema, not training guesses |

> 💡 **Key talking point:** The difference between raw ChatGPT and Copilot+MCP is live registry schema. Without MCP, language models frequently invent argument names or use deprecated fields. With MCP, the schema is fetched in real time from the Terraform registry — so what Copilot generates is what Terraform actually accepts.

---

## Part 3 — Setup in VS Code

**Prerequisites:**

```
✅ VS Code 1.90+
✅ GitHub Copilot extension installed and signed in
✅ Node.js 18+ (required to run the MCP server via npx)
✅ Terraform CLI 1.5+
```

**Step-by-step setup:**

1. **Enable MCP in Settings** — Open VS Code Settings (`Ctrl+,`), search for `mcp`, and enable the MCP feature flag
2. **Create `.vscode/mcp.json`** with the Terraform MCP server entry:
   ```json
   {
     "servers": {
       "terraform": {
         "command": "npx",
         "args": ["-y", "@hashicorp/terraform-mcp-server"]
       }
     }
   }
   ```
3. **Reload VS Code** — Press `Ctrl+Shift+P` → type `Reload Window` → press Enter
4. **Verify Tools icon** — Open Copilot Chat (sidebar) and confirm the 🔧 Tools icon appears in the chat input bar
5. **Switch to Agent mode** — Click the mode selector in Copilot Chat and choose **Agent**

---

## Part 4 — Prompt Tips for Azure Terraform

**Tips for effective prompts:**

| Tip | Example |
|-----|---------|
| Always specify the provider version | "Use azurerm provider v3 with ~> 3.0 version pin" |
| Describe intent, not just resource type | "Create a secure storage account with no public access" instead of "Create azurerm_storage_account" |
| Specify the Azure region | "Use southeastasia as the default location" |
| Ask for variables and outputs together | "Add a variable for project_name and output the resource group name" |
| Request tags on every resource | "Apply common tags: environment, owner, managed_by = terraform" |
| Open provider.tf first | Having provider.tf open gives Copilot the provider version context |

### ⚠️ 3 Azure Terraform Gotchas

**1. `features {}` is mandatory even when empty**

The `azurerm` provider will refuse to initialize without the `features {}` block, even if you don't need to customize any features. Always include it:

```hcl
provider "azurerm" {
  features {}
}
```

**2. Storage account names must be lowercase alphanumeric and globally unique**

Azure storage account names must be 3–24 characters, lowercase alphanumeric only — no hyphens, underscores, or uppercase. Use a `locals` block to sanitize the name:

```hcl
locals {
  storage_account_name = substr(lower(replace("${var.project_name}${var.environment}sa", "-", "")), 0, 24)
}
```

**3. Deleting a Resource Group cascades and destroys everything inside — `prevent_destroy` won't save you**

Setting `lifecycle { prevent_destroy = true }` on a Resource Group protects it from being deleted by `terraform destroy`. However, if Azure deletes the Resource Group outside of Terraform (e.g., through the portal), all contained resources are gone immediately. Always maintain backups and use Azure Resource Locks for critical environments.

---

## 🎬 Live Demo

> 🎯 **Goal:** Provision a real Azure environment — Resource Group + Storage Account with security best practices — entirely using GitHub Copilot + Terraform MCP Server

**Demo environment checklist:**
- [ ] `.vscode/mcp.json` is in place and Terraform MCP server is running
- [ ] Empty `terraform/` folder open in VS Code
- [ ] Copilot Chat is in **Agent** mode
- [ ] Terminal panel is visible

---

### Step 1 — Bootstrap the project scaffold

**What to show:** How Copilot generates a complete provider configuration with correct version pinning and the mandatory `features {}` block.

**Copilot prompt:**
```
@terraform Create a new Terraform project scaffold for Microsoft Azure. Include provider.tf using azurerm provider v3 with the required features {} block, variables.tf with subscription_id / location (default: southeastasia) / environment (default: dev), and an empty outputs.tf. Pin the provider version with ~> 3.0.
```

**Expected output — `provider.tf`:**
```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
```

> 💡 **Talking point:** Copilot included `features {}` and pinned the version with `~>` — this comes from the live MCP schema, not a guess. Without MCP, models often omit `features {}` entirely or use `>=` which can break on major version upgrades.

---

### Step 2 — Add a Resource Group

**What to show:** How Copilot reads your existing `variables.tf` to use the correct variable names without being told.

**Copilot prompt:**
```
@terraform Add an azurerm_resource_group to main.tf. Name it using a local prefix combining var.project_name and var.environment. Use var.location. Apply common tags: environment, owner, managed_by = terraform. Add lifecycle prevent_destroy = true.
```

**Expected output — `main.tf`:**
```hcl
resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
```

> 💡 **Talking point:** Copilot read `variables.tf` from the workspace context — it didn't need to be told what variables exist. This is the "workspace awareness" that makes Agent mode so powerful for infrastructure projects.

---

### Step 3 — Add a Secure Storage Account

**What to show:** How MCP provides the exact nested block structure for `network_rules` and `identity` — fields that models frequently get wrong without live schema access.

**Copilot prompt:**
```
@terraform Add an azurerm_storage_account to main.tf. Requirements: Standard LRS, disable public blob access, HTTPS only, TLS 1.2 minimum, network_rules deny all with AzureServices bypass, system-assigned managed identity. Use a local for the name: lower(replace combining project_name and environment). Output the primary blob endpoint in outputs.tf.
```

**Expected output — `main.tf` (storage account block):**
```hcl
resource "azurerm_storage_account" "main" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [azurerm_resource_group.main]
}
```

> 💡 **Talking point:** The nested block structure — `network_rules`, `identity` — came from the live `azurerm` registry schema via MCP. Without MCP, Copilot frequently gets nested block names wrong (e.g., `network_rule` instead of `network_rules`, or missing the `bypass` list entirely). This is the core value of the Terraform MCP Server.

---

### Step 4 — Review and validate

**What to show:** How the same tool that generates code can audit it against the current provider changelog.

**Copilot prompt:**
```
@terraform Review all .tf files in my workspace. Check for deprecated arguments against azurerm v3/v4, confirm required_providers has version constraints, add lifecycle prevent_destroy = true to stateful resources, and suggest any missing production best practices.
```

**Expected output:** Copilot produces a list of suggestions or applies inline fixes such as:
- Confirming `~>` version pins are in place
- Flagging any deprecated arguments (e.g., `storage_account_name` → `name`)
- Suggesting missing `prevent_destroy` on stateful resources
- Recommending explicit `depends_on` for resource group dependencies

> 💡 **Talking point:** The same tool used to generate code can now audit it — MCP checks arguments against the current provider changelog. This closes the loop between code generation and validation in a single workflow.

---

### Step 5 — Run terraform init and plan

**What to show:** The full Terraform workflow succeeding with a clean plan output.

**Terminal commands:**
```bash
terraform init
terraform validate
terraform plan -var="subscription_id=<your-sub-id>"
```

**Expected plan output:**
```
Plan: 2 to add, 0 to change, 0 to destroy.

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" { ... }

  # azurerm_storage_account.main will be created
  + resource "azurerm_storage_account" "main" { ... }
```

> 💡 **Talking point:** Zero to a valid, security-hardened plan using only natural language prompts. The `features {}` block is correct, the storage name is sanitized, public access is disabled, TLS 1.2 is enforced, and network rules deny all by default — all from a few sentences in Copilot Chat.

---

## 📁 Final File Structure

```
terraform/
├── .vscode/
│   └── mcp.json
├── .gitignore
├── provider.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
└── README.md
```

---

## 🧪 Hands-On Lab

Now it's your turn. Follow these exercises using GitHub Copilot + the Terraform MCP Server. Each exercise builds on the previous one.

---

### Exercise 1 — Set up your environment

**Objective:** Get VS Code, Copilot, and the Terraform MCP Server running locally

**Tasks:**
1. Install the GitHub Copilot extension in VS Code if not already installed
2. Create a new folder called `terraform-azure-lab` and open it in VS Code
3. Create `.vscode/mcp.json` with the Terraform MCP server configuration
4. Reload VS Code and confirm the Tools icon appears in Copilot Chat
5. Switch Copilot Chat to Agent mode

**Expected outcome:** Copilot Chat shows the Tools icon and Agent mode is active

⏱️ **Time estimate:** 5 minutes

---

### Exercise 2 — Bootstrap your first Terraform project

**Objective:** Use Copilot to generate a complete project scaffold for Azure

**Tasks:**
1. Open Copilot Chat in Agent mode
2. Use this prompt exactly:
   ```
   @terraform Create a Terraform project scaffold for Azure with provider.tf (azurerm v3, features {} block, southeastasia), variables.tf (subscription_id, location, environment, project_name), and outputs.tf
   ```
3. Review the generated `provider.tf` — confirm `features {}` is present
4. Check that `required_providers` has a version constraint using `~>` not `>=`
5. Run: `terraform init`

**Expected outcome:** `.terraform/` folder created, provider downloaded successfully

**Validation command:** `terraform validate`

⏱️ **Time estimate:** 10 minutes

---

### Exercise 3 — Add a Resource Group with tags

**Objective:** Generate your first Azure resource using a natural language prompt

**Tasks:**
1. Ask Copilot:
   ```
   @terraform Add an azurerm_resource_group to main.tf named using a combination of var.project_name and var.environment. Apply tags: environment, owner = platform-team, managed_by = terraform. Add lifecycle prevent_destroy = true
   ```
2. Review the generated resource — check the name expression uses string interpolation correctly
3. Add a `locals.tf` manually and move the name prefix into a local called `prefix`
4. Ask Copilot to update `main.tf` to reference `local.prefix` instead of the inline expression
5. Run: `terraform plan -var="subscription_id=YOUR_SUB_ID" -var="project_name=mylab"`

**Expected outcome:** Plan shows 1 resource to add — `azurerm_resource_group`

⏱️ **Time estimate:** 10 minutes

---

### Exercise 4 — Add a secure Storage Account

**Objective:** Generate a security-hardened storage account and see MCP provide the correct nested block structure

**Tasks:**
1. Ask Copilot:
   ```
   @terraform Add an azurerm_storage_account to main.tf. Standard LRS, HTTPS only, TLS 1.2, no public blob access, network_rules deny all with AzureServices bypass, system-assigned managed identity. Use a local for the name that is lowercase alphanumeric only.
   ```
2. Review the generated `locals` block — confirm the name uses `lower()` and `replace()` to strip hyphens
3. Check the `network_rules` block has `default_action = "Deny"` not `"Allow"`
4. Check the `identity` block has `type = "SystemAssigned"`
5. Add the storage account `primary_blob_endpoint` as an output in `outputs.tf`
6. Run: `terraform plan -var="subscription_id=YOUR_SUB_ID" -var="project_name=mylab"`

**Expected outcome:** Plan shows 2 resources to add

> ⚠️ **Gotcha:** If the plan fails with a naming error, check the storage account name local — it must be lowercase alphanumeric, no hyphens, max 24 characters.

⏱️ **Time estimate:** 15 minutes

---

### Exercise 5 — Review and harden your config

**Objective:** Use Copilot as a code reviewer to catch issues before they reach CI

**Tasks:**
1. Ask Copilot:
   ```
   @terraform Review all .tf files. Check for deprecated azurerm v3/v4 arguments, missing version pins, and any resources missing prevent_destroy or tags
   ```
2. Review Copilot's suggestions — apply any deprecated argument fixes
3. Manually add a `terraform.tfvars.example` file with placeholder values (not real credentials)
4. Confirm `terraform.tfvars` is listed in `.gitignore`
5. Run: `terraform validate` — should return `"Success! The configuration is valid."`

**Expected outcome:** Clean validate output, no deprecated arguments, all resources tagged

⏱️ **Time estimate:** 10 minutes

---

## 🏆 Bonus — Add an Azure Key Vault

Try this prompt on your own:

```
@terraform Add an azurerm_key_vault to main.tf. Use Standard SKU, enable soft delete with 7 day retention, enable purge protection, restrict network access to deny all by default, and assign the current deployment service principal as Key Vault Administrator using azurerm_role_assignment.
```

**Challenge questions:**
- What additional variable did Copilot add for the `tenant_id`?
- Did the `network_acls` block structure match what you expected?
- What does `purge_protection_enabled = true` mean for your destroy workflow?

---

## 📚 Resources

| Resource | Link |
|----------|------|
| Terraform MCP Server (HashiCorp) | https://github.com/hashicorp/terraform-mcp-server |
| GitHub Copilot in VS Code | https://marketplace.visualstudio.com/items?itemName=GitHub.copilot |
| azurerm Provider Registry | https://registry.terraform.io/providers/hashicorp/azurerm/latest |
| azurerm v3→v4 Upgrade Guide | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide |
| MCP Protocol | https://modelcontextprotocol.io |

---

*Session prepared for internal tech talk · Azure Infrastructure track*
