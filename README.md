# SPADE Cloud Platform

A comprehensive docker-compose deployment configuration for the SPADE (Secure Platform for Advanced Data Exchange) Cloud platform. This platform provides a complete infrastructure for secure data collaboration, identity management, and PKI services.

## Overview

SPADE Cloud is a modular platform consisting of core SPADE services and industry-standard external components for authentication and certificate management. All services are containerized and orchestrated using Docker Compose with Traefik as the reverse proxy.

## Services

### SPADE Core Services

#### **Data Broker UI**
Web interface for data discovery and access management. Provides users with a friendly interface to browse, search, and request access to data resources within the SPADE ecosystem.

- **Technology**: Angular-based SPA
- **Port**: 4200 (internal)
- **Access**: Via Traefik at configured domain
- **Configuration**: Uses environment variables from `.env`

#### **Entrypoint**
Main API gateway for the SPADE platform. Handles authentication, authorization, and routing for all SPADE services.

- **Technology**: Node.js/Express
- **Port**: 3000 (internal)
- **Access**: Via Traefik at configured domain
- **Environment Variables**:
  - Database connection details
  - Authentication settings
  - Service endpoints
- **Dependencies**: Requires Keycloak for authentication

#### **Catalogue**
Core data catalogue service managing metadata, schemas, and access policies for data resources. Implements the SPADE data model and provides APIs for data discovery and management.

- **Technology**: Node.js using PostgreSQL
- **Port**: 4000 (internal)
- **Database**: PostgreSQL 17 (auto-initialized)
- **Access**: Via Traefik at configured domain
- **Environment Variables**:
  - `DB_HOST`: Database hostname (set to `catalogue_db`)
  - `DB_PORT`: Database port (5432)
  - `DB_NAME`: Database name
  - `DB_USER`: Database username
  - `DB_PASSWORD`: Database password
  - Additional variables in `.env` file
- **Persistent Data**: Stored in `catalogue_db_data` volume

#### **PKI Service**
SPADE-specific PKI management service that integrates with EJBCA to provide certificate lifecycle management for SPADE participants.

- **Technology**: Custom PKI management layer
- **Port**: 8080 (internal)
- **Access**: Via Traefik at configured domain
- **Configuration**: 
  - Requires `config.json` in `PKI_DATA_PATH`
  - Configure EJBCA integration settings
  - Define certificate profiles and policies
- **Dependencies**: EJBCA must be running
- **Volume**: `PKI_DATA_PATH` for persistent configuration

### External Services

#### **Keycloak** (Identity & Access Management)
Industry-standard open-source IAM solution providing authentication and authorization services.

- **Version**: Bitnami Keycloak 22
- **Database**: PostgreSQL 15.5 (auto-initialized)
- **Admin Access**: Use credentials from `KEYCLOAK_ADMIN_USER` and `KEYCLOAK_ADMIN_PASSWORD`
- **Documentation**: [Keycloak Official Documentation](https://www.keycloak.org/documentation)
- **Configuration**: Set database and admin credentials in `.env`
- **Custom Themes**: Optional - uncomment volume mount in `docker-compose.yml`

#### **EJBCA** (PKI Certificate Authority)
Enterprise-grade open-source PKI solution for certificate issuance and management.

- **Version**: Keyfactor EJBCA CE 9.1.1
- **Database**: MariaDB (auto-initialized)
- **Documentation**: [EJBCA Official Documentation](https://doc.primekey.com/ejbca)
- **Proxy**: Optional Apache HTTP proxy for external access
- **Configuration**: 
  - Database credentials in `.env`
  - For proxy: Provide `httpd.conf` and SSL certificates
- **Note**: Can be commented out if not using PKI features

## Prerequisites

- **Docker Engine** 20.10 or higher
- **Docker Compose** v2.0 or higher
- **Traefik** reverse proxy running with:
  - SSL certificate resolver configured (named `myresolver`)
  - External network connectivity
  - Access to configured domains
- **DNS Configuration**: Domain names must resolve to your server
- **Operating System**: Linux (tested on Ubuntu 20.04+)

## Deployment

### 1. Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd spade-cloud

# Copy environment template
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` and set:

```bash
# Required for all services
DATABROKER_DOMAIN=databroker.yourdomain.com
ENTRYPOINT_DOMAIN=spade.yourdomain.com
CATALOGUE_DOMAIN=catalogue.yourdomain.com
KEYCLOAK_DOMAIN=auth.yourdomain.com

# Docker images (use your registry)
DATABROKER_UI_IMAGE=your-registry.com/databroker-ui:latest
ENTRYPOINT_IMAGE=your-registry.com/spade-entrypoint:latest
CATALOGUE_IMAGE=your-registry.com/spade-catalogue:latest

# Database credentials (generate strong passwords)
CATALOGUE_DB_USER=catalogue_admin
CATALOGUE_DB_PASSWORD=<strong-password>
CATALOGUE_DB_NAME=catalogue

KEYCLOAK_DB_USER=keycloak_admin
KEYCLOAK_DB_PASSWORD=<strong-password>
KEYCLOAK_DB_NAME=keycloak

KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=<strong-admin-password>

# PKI services (required)
PKI_DOMAIN=pki.yourdomain.com
PKI_IMAGE=your-registry.com/spade-pki:latest
PKI_DATA_PATH=./pki/data

EJBCA_DB_USER=ejbca_admin
EJBCA_DB_PASSWORD=<strong-password>
EJBCA_DB_ROOT_PASSWORD=<strong-root-password>
```

### 3. Configure PKI

PKI services are required for SPADE platform operation. Configure the PKI service:

```bash
# Copy the example PKI configuration
cp pki_data/config.json pki/data/config.json

# Edit the configuration with your values
nano pki/data/config.json
```

Update the following in `config.json`:
- `ccHost`: Your catalogue domain
- `issuerDN`: Your certificate authority distinguished name
- `certificateProfileName`, `endEntityProfileName`, `certificateAuthorityName`: Match your EJBCA setup
- `apiSecret`: Generate a secure base64-encoded secret
- `keystorePassword`, `truststorePassword`: Set strong passwords
- Ensure keystore files in PKCS#12 format (`superadmin.p12`, `truststore.p12`) are present in the PKI data directory

### 4. Configure EJBCA Proxy (Optional)

The EJBCA proxy is optional and provides external HTTP/HTTPS access to EJBCA.

```bash
mkdir -p ejbca/pem
# Place your httpd.conf and SSL certificates in respective directories
```

### 5. Start Services

**Option A: Start all services**
```bash
docker compose up -d
```

**Option B: Start services incrementally (recommended for first deployment)**
```bash
# Start databases first
docker compose up -d catalogue_db keycloak_db ejbca_db

# Wait for databases to initialize (check with docker compose logs)
docker compose logs -f catalogue_db keycloak_db ejbca_db

# Start core SPADE services
docker compose up -d catalogue entrypoint data-broker_ui

# Start Keycloak
docker compose up -d keycloak

# Start PKI services (required)
docker compose up -d ejbca pki
```

### 6. Verify Deployment

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f

# Test service access
curl -k https://catalogue.yourdomain.com/health
curl -k https://auth.yourdomain.com/health
curl -k https://pki.yourdomain.com/health
```

### 7. Initial Configuration

#### Keycloak Setup
1. Access Keycloak admin console: `https://auth.yourdomain.com`
2. Login with `KEYCLOAK_ADMIN_USER` / `KEYCLOAK_ADMIN_PASSWORD`
3. Create realm for SPADE
4. Configure clients for SPADE services
5. See: [Keycloak Getting Started Guide](https://www.keycloak.org/getting-started)

#### EJBCA Setup (if using)
EJBCA setup and configuration is complex and requires extensive PKI knowledge. Refer to the [EJBCA Installation Guide](https://doc.primekey.com/ejbca/ejbca-installation) for detailed instructions.

#### Catalogue Service
The catalogue service will initialize its database schema automatically on first startup. No manual configuration required.

## Service Architecture

```
Internet
   ↓
Traefik (SSL/TLS Termination & Routing)
   ↓
   ├─→ Data Broker UI (Frontend)
   ├─→ Entrypoint (API Gateway)
   ├─→ Catalogue (Core Service) ─→ PostgreSQL
   ├─→ Keycloak (IAM) ─→ PostgreSQL
   └─→ PKI Service ─→ EJBCA ─→ MariaDB
```

All services communicate via the internal `spade_network` Docker bridge network.

## Maintenance

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f catalogue

# Last 100 lines
docker compose logs --tail=100 catalogue
```

### Update Services
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Or update specific service
docker compose up -d catalogue
```

## License

This project (SPADE Cloud Platform) is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

### Third-Party Components

- **Keycloak**: Licensed under [Apache License 2.0](https://github.com/keycloak/keycloak/blob/main/LICENSE.txt)
- **EJBCA**: Licensed under [LGPL v2.1](https://www.primekey.com/products/software-licensing/)
- **PostgreSQL**: Licensed under [PostgreSQL License](https://www.postgresql.org/about/licence/) (permissive open-source license)
- **MariaDB**: Licensed under [GPL v2](https://mariadb.com/kb/en/mariadb-license/)
- **Traefik**: Licensed under [MIT License](https://github.com/traefik/traefik/blob/master/LICENSE.md)

## Support

For issues specific to:
- **SPADE services**: Contact bAvenir support at [support@bavenir.com](mailto:support@bavenir.com)
- **Keycloak**: See [Keycloak Community](https://www.keycloak.org/community)
- **EJBCA**: See [EJBCA Support](https://www.primekey.com/support/)
- **Docker/Infrastructure**: Check Docker and Traefik documentation