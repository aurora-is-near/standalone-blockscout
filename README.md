# BlockScout Automation

## Overview

This toolkit is designed to streamline the setup and deployment of BlockScout along with all dependent services for new aurora silos. It simplifies the process of deploying a fully functional BlockScout instance, which is an open-source tool for exploring Ethereum-based (EVM) blockchains. The primary method for deployment is through the `install.sh` script, which automates the tasks of cloning necessary repositories, building Docker images, and configuring the environment.

## Getting Started

### Prerequisites

- Docker and Docker Compose installed on your machine.
- Git installed for cloning repositories.

### Installation and Deployment

1. **Execute the Installation Script**

   The `install.sh` script is the central part of the setup process. It performs several critical steps:
   - Clones the necessary BlockScout and frontend repositories.
   - Builds Docker images for the backend and frontend services.
   - Checks for required environment variables and applies them to configure `docker-compose.yaml`.

   To start the installation, ensure that you have the necessary environment variables set in your system. These include configurations for database access, blockchain node endpoints, and other service-specific settings.

   Execute the script from your terminal:

   ```sh
   ./install.sh
   ```

2. **Review the Installation Process**

   - The script will prompt you if any required environment variables are missing or need confirmation.
   - It automatically modifies the `docker-compose.yaml` based on your environment variables to match your specific deployment needs.

3. **Service Startup**

   After configuring the environment and building the images, the script will use Docker Compose to start the BlockScout and its dependent services:

   ```sh
   docker-compose up --build
   ```

   This command builds (if necessary) and starts all the services defined in your `docker-compose.yaml`. The `--build` flag ensures that the latest versions of your custom Docker images are used.

