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

Before running the script, ensure the following environment variables are set, as they are required for the configuration:

- `NAME`: The name of your application.
- `RPC_URL`: The RPC URL for the blockchain network.
- `CHAIN_ID`: The chain ID of the blockchain network.
- `SILO_GENESIS`: The genesis block information.
- `EXPLORER_URL` (optional): The URL of the explorer. If not set, it defaults to `explorer.$RPC_URL`.
- `FAVICON_GENERATOR_API_KEY` (optional): API key for the favicon generator.
- `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID` (optional): Project ID for WalletConnect.

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