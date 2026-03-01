# Using the Coolify Terraform Provider

This guide shows you how to use this Terraform provider in your projects.

## Quick Start

### Option 1: Local Development Build (Fastest - Use Now!)

This method lets you use the provider immediately without waiting for the GitHub release.

1. **Install the provider locally:**

   ```bash
   cd /Users/patrik/src/work/patrikwm/terraform-provider-coolify
   make install
   ```

2. **Configure Terraform dev override** by creating or editing `~/.terraformrc`:

   ```hcl
   provider_installation {
     dev_overrides {
       "patrikwm/coolify" = "/Users/patrik/go/bin"
     }

     # For all other providers, install them directly from their registries
     direct {}
   }
   ```

3. **Create a test project:**

   ```bash
   mkdir -p ~/my-coolify-test
   cd ~/my-coolify-test
   ```

4. **Create `main.tf`:**

   ```hcl
   terraform {
     required_providers {
       coolify = {
         source = "patrikwm/coolify"
       }
     }
   }

   provider "coolify" {
     endpoint = "https://your-coolify.domain.com/api/v1"
     # Token is read from COOLIFY_TOKEN environment variable
   }

   # Example: List all projects
   data "coolify_projects" "all" {}

   output "projects" {
     value = data.coolify_projects.all.projects
   }
   ```

5. **Set your Coolify token:**

   ```bash
   export COOLIFY_TOKEN="your-coolify-api-token"
   ```

6. **Run Terraform:**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

   **Note:** Terraform will show a warning about dev overrides - this is normal!

---

### Option 2: Direct from GitHub Release (After Release is Published)

Once your GitHub Actions workflow completes and you publish the release, you can use it directly:

1. **Create your Terraform configuration:**

   ```hcl
   terraform {
     required_providers {
       coolify = {
         source  = "github.com/patrikwm/coolify"
         version = "~> 0.1.0"
       }
     }
   }

   provider "coolify" {
     endpoint = "https://your-coolify.domain.com/api/v1"
   }
   ```

2. **Manual provider installation:**

   ```bash
   VERSION="0.1.0"
   OS="darwin"      # or linux, windows
   ARCH="arm64"     # or amd64

   # Create directory
   mkdir -p ~/.terraform.d/plugins/github.com/patrikwm/coolify/${VERSION}/${OS}_${ARCH}
   cd ~/.terraform.d/plugins/github.com/patrikwm/coolify/${VERSION}/${OS}_${ARCH}

   # Download from release (once published)
   curl -LO https://github.com/patrikwm/terraform-provider-coolify/releases/download/v${VERSION}/terraform-provider-coolify_${VERSION}_${OS}_${ARCH}.zip

   # Extract
   unzip terraform-provider-coolify_${VERSION}_${OS}_${ARCH}.zip
   chmod +x terraform-provider-coolify_v${VERSION}
   ```

3. **Remove dev override** from `~/.terraformrc` if you set it up earlier

4. **Use in your project:**

   ```bash
   export COOLIFY_TOKEN="your-token"
   terraform init
   terraform plan
   ```

---

### Option 3: Terraform Registry (Coming Soon)

To publish to the official Terraform Registry:

1. Go to: https://registry.terraform.io
2. Sign in with GitHub
3. Click "Publish" → "Provider"
4. Select `patrikwm/terraform-provider-coolify`
5. The registry will automatically sync with your GitHub releases

Once published, users can reference it directly:

```hcl
terraform {
  required_providers {
    coolify = {
      source  = "patrikwm/coolify"
      version = "~> 0.1.0"
    }
  }
}
```

---

## Complete Examples

### Example 1: Create a Server with SSH Key

```hcl
terraform {
  required_providers {
    coolify = {
      source = "patrikwm/coolify"
    }
  }
}

provider "coolify" {
  endpoint = "https://coolify.example.com/api/v1"
  # Token from COOLIFY_TOKEN environment variable
}

# Generate SSH key
resource "tls_private_key" "server_key" {
  algorithm = "ED25519"
}

# Register key in Coolify
resource "coolify_private_key" "server_key" {
  name        = "My Server Key"
  description = "Managed by Terraform"
  private_key = tls_private_key.server_key.private_key_pem
}

# Create server
resource "coolify_server" "my_server" {
  name             = "Production Server"
  description      = "Managed by Terraform"
  ip               = "192.168.1.100"
  port             = 22
  user             = "root"
  private_key_uuid = coolify_private_key.server_key.uuid

  # Wait for server validation
  wait_for_validation = true

  timeouts {
    create = "10m"
  }
}

output "server_uuid" {
  value = coolify_server.my_server.uuid
}
```

### Example 2: Deploy a Database Service

```hcl
# Get existing project
data "coolify_project" "main" {
  uuid = "your-project-uuid"
}

# Create MySQL database
resource "coolify_mysql_database" "app_db" {
  name         = "app-database"
  description  = "Application Database"
  project_uuid = data.coolify_project.main.uuid
  server_uuid  = "your-server-uuid"

  mysql_root_password = var.db_root_password
  mysql_database      = "myapp"
  mysql_user          = "appuser"
  mysql_password      = var.db_password
}

# Configure service environment variables
resource "coolify_service_envs" "db_config" {
  service_uuid = coolify_mysql_database.app_db.service_uuid

  envs = {
    MYSQL_MAX_CONNECTIONS = "200"
    MYSQL_INNODB_BUFFER_POOL_SIZE = "256M"
  }

  # Automatically redeploy when config changes
  redeploy_on_change = true

  # Wait for service to be healthy after deployment
  wait_for_deployment = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

output "database_connection" {
  value = "mysql://${coolify_mysql_database.app_db.mysql_user}@${coolify_mysql_database.app_db.mysql_host}:${coolify_mysql_database.app_db.mysql_port}/${coolify_mysql_database.app_db.mysql_database}"
  sensitive = true
}
```

### Example 3: Query Existing Resources

```hcl
# List all projects
data "coolify_projects" "all" {}

# Get specific project
data "coolify_project" "prod" {
  uuid = "your-project-uuid"
}

# List all servers
data "coolify_servers" "all" {}

# Get applications in a project
data "coolify_applications" "prod_apps" {
  project_uuid = data.coolify_project.prod.uuid
}

# Output
output "all_projects" {
  value = [
    for p in data.coolify_projects.all.projects : {
      name = p.name
      uuid = p.uuid
    }
  ]
}

output "production_apps" {
  value = length(data.coolify_applications.prod_apps.applications)
}
```

---

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `COOLIFY_TOKEN` | Your Coolify API token | Yes |
| `COOLIFY_ENDPOINT` | Coolify API endpoint (can also be set in provider block) | No |

### Getting Your API Token

1. Log in to your Coolify dashboard
2. Go to **Settings** → **API Tokens**
3. Click **Create New Token**
4. Give it **Root Access**
5. Copy the token and export it:

   ```bash
   export COOLIFY_TOKEN="your-token-here"
   ```

Or add to your `~/.bashrc` or `~/.zshrc`:

   ```bash
   echo 'export COOLIFY_TOKEN="your-token-here"' >> ~/.zshrc
   source ~/.zshrc
   ```

---

## Enhanced Features in This Fork

This fork includes operational automation features not in the upstream:

### 1. Server Validation Waiter

Automatically wait for server validation instead of manual clicks:

```hcl
resource "coolify_server" "example" {
  # ... server config ...

  wait_for_validation = true  # Waits until server is validated

  timeouts {
    create = "10m"  # Configurable timeout
  }
}
```

### 2. Service Deployment Waiter

Ensure services are healthy before Terraform completes:

```hcl
resource "coolify_service" "app" {
  # ... service config ...

  wait_for_deployment = true  # Waits until service is running

  timeouts {
    create = "15m"
  }
}
```

### 3. Auto-Redeploy on Config Change

Automatically restart services when environment variables change:

```hcl
resource "coolify_service_envs" "config" {
  service_uuid = coolify_service.app.uuid

  envs = {
    API_KEY = "new-value"
  }

  redeploy_on_change = true  # Auto-redeploys service
  wait_for_deployment = true # Waits for new deployment to be healthy
}
```

### 4. Environment Resource

Full CRUD support for project environments:

```hcl
resource "coolify_environment" "staging" {
  name         = "staging"
  project_uuid = coolify_project.main.uuid
}
```

---

## Troubleshooting

### "Provider not found"

If using local development:
1. Make sure you ran `make install`
2. Check that `~/.terraformrc` has the dev_overrides configured
3. Verify the provider is in `~/go/bin`: `ls -la ~/go/bin/terraform-provider-coolify`

### "Failed to query available provider packages"

The provider isn't in Terraform Registry yet. Use Option 1 (local dev) or Option 2 (manual install from GitHub release).

### Testing Your Setup

Quick test to verify everything works:

```bash
cat > test.tf <<'EOF'
terraform {
  required_providers {
    coolify = {
      source = "patrikwm/coolify"
    }
  }
}

provider "coolify" {
  endpoint = "https://your-coolify.example.com/api/v1"
}

data "coolify_projects" "test" {}

output "project_count" {
  value = length(data.coolify_projects.test.projects)
}
EOF

export COOLIFY_TOKEN="your-token"
terraform init
terraform plan
```

---

## Next Steps

1. **Check release status:** https://github.com/patrikwm/terraform-provider-coolify/actions
2. **View releases:** https://github.com/patrikwm/terraform-provider-coolify/releases
3. **Documentation:** See the `docs/` directory for full resource/data source docs
4. **Examples:** Check the `examples/` directory for more use cases

## Support

- **Issues:** https://github.com/patrikwm/terraform-provider-coolify/issues
- **Discussions:** https://github.com/patrikwm/terraform-provider-coolify/discussions
- **Upstream:** Based on https://github.com/SierraJC/terraform-provider-coolify
