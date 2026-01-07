# Diag Factory Test System

This project provides a complete solution for automating the diagnostic testing of Linux servers in a factory environment using Jenkins, Python, and REST APIs.

## Components

- **Jenkins**: Orchestrates the testing pipeline.
- **Diag Agent**: A Flask-based REST API service running on each target server.
- **Python Controller**: Handles communication between Jenkins and the Diag Agent.
- **Diagnostic Scripts**: Individual test scripts for CPU, Memory, Network, and Storage.

## Setup Instructions

### Prerequisites

- Jenkins Server with necessary plugins installed.
- Target Servers with SSH access and Docker or Python3 installed.

### Installation Steps

1. Clone this repository to your Jenkins server and target servers.
2. Set up the Diag Agent on each target server using `scripts/setup_agent.sh`.
3. Configure the Jenkins job using the provided `Jenkinsfile`.

## License

MIT License