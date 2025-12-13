# Flask CI/CD Pipeline with Jenkins, Docker, and Trivy

This repository demonstrates a simple **Flask "Hello World"
application** with a complete **CI/CD pipeline** implemented using
**Jenkins**, **Docker**, and **Trivy** for container security scanning.

The project covers: - Local development and testing - Containerization
with Docker - Automated CI/CD using a Jenkins Declarative Pipeline -
Container image vulnerability scanning with Trivy

------------------------------------------------------------------------

## Project Structure

    .
    ├── hello.py               # Flask application
    ├── test_hello.py          # Pytest unit test
    ├── requirements.txt       # Python dependencies
    ├── Dockerfile             # Docker image definition
    ├── Jenkinsfile            # Jenkins Declarative Pipeline
    └── README.md              # Project documentation

------------------------------------------------------------------------

## 1. Running the Application Locally

### Prerequisites

-   Python 3.10 or later
-   pip

### Steps

Create and activate a virtual environment:

``` bash
python3 -m venv .venv
source .venv/bin/activate
```

Install dependencies:

``` bash
pip install -r requirements.txt
```

Run the Flask application:

``` bash
python hello.py
```

Access the application in your browser:

    http://127.0.0.1:5000

Expected output:

    Hello World!

### Run Tests Locally

``` bash
pytest
```

------------------------------------------------------------------------

## 2. Build and Run the Docker Image

### Build the Docker Image

``` bash
docker build -t flask-hello:local .
```

### Run the Container

``` bash
docker run --rm -p 5000:5000 flask-hello:local
```

Access the application at:

    http://localhost:5000

The container runs the application using **Gunicorn**, a
production-grade WSGI server.

------------------------------------------------------------------------

## 3. Jenkins CI/CD Pipeline Overview

The CI/CD pipeline is defined in the `Jenkinsfile` using **Declarative
Pipeline syntax**.

### Pipeline Stages and Requirement Mapping
| Jenkins Stage          | Description                                  | Requirement Covered         |
|-----------------------|----------------------------------------------|------------------------------|
| Checkout              | Clones the Git repository                    | Source control integration   |
| Build (Python deps)   | Creates virtualenv and installs dependencies | Application build            |
| Test                  | Runs unit tests using pytest                 | Automated testing            |
| Docker Build          | Builds Docker image                          | Containerization             |
| Security Scan (Trivy) | Scans image for vulnerabilities              | Security scanning            |
| Post Actions          | Cleanup images and workspace                 | CI hygiene                   |
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 4. Trivy Security Scan

### How the Scan Works

-   Trivy is executed **as a Docker container**
-   The Docker socket is mounted to allow image inspection
-   The scan runs after the Docker image is built

Example command used in the pipeline:

``` bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest \
  image --severity HIGH,CRITICAL --exit-code 1 flask-hello:<tag>
```

### Security Policy

-   **HIGH** and **CRITICAL** vulnerabilities → ❌ Pipeline fails
-   **LOW** and **MEDIUM** vulnerabilities → ⚠️ Reported but pipeline
    continues
-   A full Trivy scan report is archived as a Jenkins build artifact

This policy reflects common industry CI/CD security gating practices.

------------------------------------------------------------------------

## 5. Notes & Best Practices

-   Docker-in-Docker is avoided; instead, the Docker socket is mounted
-   Trivy is containerized to keep Jenkins agents lightweight
-   Tests must exist; pytest exits with a non-zero code if no tests are
    found
-   Docker images and Jenkins workspace are cleaned after each run

------------------------------------------------------------------------
