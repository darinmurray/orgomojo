---
applyTo: "**/deploy.yml,**/Dockerfile,**/*.rb"
---
# Kamal Deployment Guidelines

## Configuration Best Practices
- Use `config/deploy.yml` for all Kamal-specific configuration
- Set meaningful application and service names
- Configure environment variables using Kamal's built-in management
- Use secure methods for handling credentials in production
- Implement appropriate health checks for containers

## Essential Kamal Commands
- `kamal setup`: Initialize server environment and deploy application
- `kamal deploy`: Deploy new version of the application (rolling deploy)
- `kamal accessory reboot [NAME]`: Reboot specific accessory service
- `kamal envify`: Compile the env files from credentials (before deploy)
- `kamal rollback`: Revert to previous deployment version
- `kamal lock/unlock`: Control deployment access (prevent deployments)
- `kamal redeploy`: Force full redeploy even when image hasn't changed
- `kamal restart`: Restart application containers without new deployment
- `kamal app exec`: Execute command in app container (e.g., `kamal exec 'bin/rails c'`)
- `kamal app logs`: View application logs


## Deploy.yml Configuration
```yaml
# Core configuration 
service: app_name  # Name of the primary application service
image: user/app    # Docker image name in registry
registry:
  username: registry_user  # Docker registry username
  password:
    - KAMAL_REGISTRY_PASSWORD  # Environment variable for registry password
servers:
  web:              # Server group name
    - xxx.xxx.xxx.1 # List of server IP addresses
    - xxx.xxx.xxx.2
  worker:           # Additional server group (for background jobs)
    - xxx.xxx.xxx.3

# Environment configuration
env:
  clear:            # Non-sensitive env vars
    RAILS_ENV: production
  secret:           # Sensitive env vars loaded from .env
    - DATABASE_URL
    - RAILS_MASTER_KEY

# Container configuration
registry:
  server: registry.digitalocean.com  # Docker registry server
labels:             # Docker container labels
  traefik.enable: "false"
  traefik.http.routers.app.rule: "Host(`example.com`)"

# Accessories configuration
accessories:
  db:             # Accessory service name (e.g., SQLite)
    image: rubylang/ruby:latest
    host: db.internal
    env:
      clear:
        SQLITE_ENVIRONMENT: production
    volumes:
      - /data/sqlite:/app/db/sqlite
  redis:          # Additional accessory (e.g., Redis)
    image: redis:7.0
    host: redis.internal
    port: 6379

# Health check configuration
healthcheck:
  path: /up        # HTTP path for health checking
  port: 3000       # Port to check
  max_attempts: 10 # Maximum attempts before failing deployment
  interval: 120     # Time between health checks
```

## Docker Configuration
- Keep Dockerfiles clean and optimized for production
- Use multi-stage builds to minimize image size
- Install only necessary dependencies in production images
- Set appropriate environment variables in Dockerfile
- Configure proper user permissions for security
- Setup SQLite for production environments

## Deployment Workflow
- Use Kamal's rolling deployments to minimize downtime
- Implement proper database migration strategies
- Configure appropriate scaling based on resource requirements
- Set up monitoring and logging solutions
- Implement proper backup strategies for data persistence
- Manage secrets through Kamal's built-in encryption system

## Advanced Kamal Features
- Use traefik for built-in load balancing and SSL termination
- Implement custom health checks through healthcheck path
- Configure volume mounts for persistent data
- Set up multiple server groups for different roles (web, worker)
- Use builder settings for optimized Docker builds
- Implement deployment hooks for custom scripts

## Multi-Service Configuration
- Configure web application services
- Set up Solid Queue worker services
- Implement proper service dependencies
- Configure appropriate resource allocation per service
- Set up logging and monitoring for all services
- Use accessories for databases and other supporting services