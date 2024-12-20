# BlockScout Automation

## Overview

This toolkit is designed to streamline the setup and deployment of BlockScout along with all dependent services for new aurora silos. It simplifies the process of deploying a fully functional BlockScout instance, which is an open-source tool for exploring Ethereum-based (EVM) blockchains. The primary method for deployment is through the `install.sh` script, which automates the tasks of cloning necessary repositories, building Docker images, and configuring the environment.

## Getting Started

### Prerequisites

- Docker and Docker Compose installed on your machine.
- Git installed for cloning repositories.
- Make sure 80 port is open and not taken on the server
- Make sure that 8080 and 8081 ports are open(on AWS you need to modify Security Group for that )

### Installation and Deployment
1. Clone the repository:
   ```bash
   git clone https://github.com/aurora-is-near/standalone-blockscout
   ```
2. Navigate to the project directory:
   ```bash
   cd standalone-blockscout
   ```

### Usage
The `build.sh` script provided in this project is designed to build, and optionally push Docker images for the BlockScout frontend and backend services. The script is flexible and allows you to specify which components to build and whether to push the Docker images to a registry. Below are the details on how to use this script effectively.

#### Building images with `build.sh`

Run the script by navigating to the directory containing the script and executing it in the terminal:

```sh
./build.sh [options]
```

The script accepts the following options:

- `--backend`: Build only the backend service.
- `--frontend`: Build only the frontend service.
- `--push`: After building, push the Docker images to a Docker registry.

If no options are provided, the script defaults to building both the frontend and backend services.

#### Environment Variables

This project uses environment variables for configuration. Below is a list of required and optional variables:

##### Required Configuration

- **`NAME`**: The name of your Silo. This is a required configuration.
- **`NAMESPACE`**: Unique identifier for the deployment, used for container naming and directory structure
- **`CHAIN_ID`**: The chain ID of the Silo. This is a required configuration.
- **`NETWORK`**: The network of the Silo, could be `mainnet` or `testnet`. This is a required configuration.
- **`GENESIS`**: A decimal number defining the genesis block number of the Silo. This is a required configuration.
- **`RPC_URL`**: The RPC URL of the Silo. This is a required configuration.
- **`BLOCKSCOUT_PROTOCOL`**: The protocol (secured or unsecured) for Blockscout frontend and backend. This is a required configuration.
- **`RPC_PROTOCOL`**: The protocol (secured or unsecured) for Ethereum JSON RPC. This is a required configuration.
- **`CURRENCY_SYMBOL`**: The currency symbol of the Silo (e.g., ETH). This is a required configuration.
- **`VERIFIER_TYPE`**: Type of smart contract microservice, either `eth_bytecode_db` or `sc_verifier`. This is a required configuration.
- **`CPU_LIMIT`**: CPU limit for the indexer containers (e.g., "1.0"). This is a required configuration.

##### Optional Configuration

- **`EXPLORER_URL`**: The EXPLORER_URL of the Silo. If not provided, `explorer.{RPC_URL}` will be used.
- **`FAVICON_GENERATOR_API_KEY`**: Favorite icon generator API key.
- **`NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`**: Wallet Connect Project ID.
- **`BLOCKSCOUT_PORT`**: Blockscout port. Default is 80.
- **`POSTGRES_PORT`**: Postgres port. Default is 7432.
- **`STATS_SERVICE_PORT`**: Stats service port. Default is 8080.
- **`VISUALIZER_SERVICE_PORT`**: Visualizer service port. Default is 8081.
- **`SMART_CONTRACT_VERIFIER_SERVICE_PORT`**: Smart Contract Verifier service port. Default is 8050.
- **`STATS_API_HOST`**: Stats API host. Overrides the default host constructed from explorer URL and stats service port.
- **`VISUALIZER_API_HOST`**: Visualizer API host. Overrides the default host constructed from explorer URL and visualizer service port.
- **`SSL_CERTIFICATE`**: Path to the SSL certificate.
- **`SSL_CERTIFICATE_KEY`**: Path to the SSL certificate key.
- **`NETWORK_LOGO`**: The URL of the network logo.
- **`NETWORK_LOGO_DARK`**: The URL of the network logo for dark mode.
- **`NETWORK_ICON`**: The URL of the network icon.
- **`REMOTE_HOST`**: SSH host for remote deployment
- **`REMOTE_DIR`**: Remote directory for deployment
- **`BRANCH`**: Git branch to use for deployment (defaults to "master")
- **`SIDECAR_ENABLED`**: Enable sidecar service (defaults to false)
- **`SUPABASE_URL`**: Supabase database URL (required if SIDECAR_ENABLED=true)
- **`SUPABASE_REALTIME_URL`**: Supabase realtime URL (required if SIDECAR_ENABLED=true)
- **`SUPABASE_ANON_KEY`**: Supabase anonymous key (required if SIDECAR_ENABLED=true)

The script will check for these variables and exit with an error message if any required variable is not set.

#### Building and Pushing Docker Images

- When the `--backend` option is used, the script clones the BlockScout repository, pulls the latest changes from the master branch, and builds the Docker image for the backend.
- When the `--frontend` option is used, the script clones the BlockScout frontend repository, pulls the latest changes from the main branch, and builds the Docker image for the frontend.
- If `--push` is also provided, the script will push the built Docker images to the configured Docker registry.

The `docker-compose.yaml` file is dynamically configured using the provided environment variables, ensuring that the Docker containers are correctly set up according to your environment and preferences.

#### Customization

You can modify the `docker-compose-template.yaml` file to suit your deployment needs, such as configuring ports, volumes, and other Docker settings. The script will use this template to create the final `docker-compose.yaml` file.

### Starting the Application with `start.sh`

The `start.sh` script is designed to simplify the process of setting up and running the application. It includes an option to pull the latest Docker images if required. Below are the instructions on how to use this script effectively.

#### Usage

To start the application, navigate to the directory containing the `start.sh` script and execute it. You have the option to force Docker to pull the latest images before starting the application.

1. **Default Start**:
   
   Run the script without any arguments to start the application using locally available Docker images. This is the standard way to start the application if you are not concerned about pulling the latest images from the Docker registry.

   ```sh
   ./start.sh
   ```

2. **Start with Image Pull**:
   
   If you want to ensure that the latest Docker images are pulled from the Docker registry, use the `--pull` argument. This is particularly useful if you have made updates to your Docker images and pushed them to the registry.

   ```sh
   ./start.sh --pull
   ```

   This command instructs Docker to pull the latest images before starting the application.

#### Script Details

- The script first checks for the `--pull` argument. If found, it sets a flag to pull the latest Docker images.
- It then executes `./install.sh` to handle any necessary installations or configurations.
- Finally, it uses `docker-compose` to bring up the application services. The Docker services are started in detached mode (`-d`), and if the `--pull` flag was set, Docker will pull the latest images as specified.

#### Permissions

Ensure that `start.sh` has the necessary execute permissions:

```sh
chmod +x start.sh
```

This script simplifies the process of starting your application, providing an easy and flexible way to manage Docker images and containers.

### Stopping the Application with `stop.sh`

The `stop.sh` script provides a straightforward method to stop all services associated with the application. It gracefully brings down the Docker containers that were started, ensuring a clean and safe shutdown of your application.

#### Usage

To stop the application, navigate to the directory containing the `stop.sh` script and execute it. This script will use Docker Compose to stop and remove the Docker containers defined in your `docker-compose.yaml` file.

1. **Stopping the Application**:
   
   Execute the script to stop all running services associated with the application:

   ```sh
   ./stop.sh
   ```

   This command brings down the Docker containers in an orderly manner, releasing all resources they were using.

#### Permissions

Make sure the `stop.sh` script is executable:

```sh
chmod +x stop.sh
```

Using `stop.sh` is recommended for stopping your application as it ensures that all services are properly terminated, avoiding any potential issues with leftover resources or improperly closed connections.