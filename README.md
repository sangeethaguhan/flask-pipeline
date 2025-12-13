# Flask CI/CD Pipeline with Jenkins, Docker, and Trivy

This repository demonstrates a simple **Flask “Hello World” application** with a complete **CI/CD pipeline** implemented using **Jenkins**, **Docker**, and **Trivy** for container security scanning.

The project covers:
- Local development and testing
- Containerization with Docker
- Automated CI/CD using a Jenkins Declarative Pipeline
- Container image vulnerability scanning with Trivy

---

## Project Structure

.
├── hello.py # Flask application
├── test_hello.py # Pytest unit test
├── requirements.txt # Python dependencies
├── Dockerfile # Docker image definition
├── Jenkinsfile # Jenkins Declarative Pipeline
└── README.md # Project documentation

yaml
Copy code

---

## 1. Running the Application Locally

### Prerequisites
- Python 3.10+
- pip

### Steps

Create and activate a virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate
Install dependencies:

bash
Copy code
pip install -r requirements.txt
Run the Flask app:

bash
Copy code
python hello.py
Access the application in your browser:

cpp
Copy code
http://127.0.0.1:5000
You should see:

nginx
Copy code
Hello World!
Run Tests Locally
bash
Copy code
pytest
2. Build and Run the Docker Image
Build the Docker Image
bash
Copy code
docker build -t flask-hello:local .
Run the Container
bash
Copy code
docker run --rm -p 5000:5000 flask-hello:local
Access the app at:

arduino
Copy code
http://localhost:5000
The container uses Gunicorn as the production WSGI server.

3. Jenkins CI/CD Pipeline Overview
The Jenkins pipeline is defined in Jenkinsfile using Declarative Pipeline syntax.

Pipeline Stages and Requirement Mapping
Jenkins Stage	Purpose	Requirement Mapping
Checkout	Clones the Git repository	Source control integration
Build (Python deps)	Creates a virtualenv and installs dependencies	Application build
Test	Runs unit tests using pytest	Automated testing
Docker Build	Builds the Docker image	Containerization
Security Scan (Trivy)	Scans Docker image for vulnerabilities	Security scanning
Post Actions	Cleanup images and workspace	CI hygiene

4. Trivy Security Scan
How the Scan Works
Trivy is executed as a container, not installed on the agent

The Docker socket is mounted to allow image scanning

The built image is scanned after the Docker build stage

Example command used in the pipeline:

bash
Copy code
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest \
  image --severity HIGH,CRITICAL --exit-code 1 flask-hello:<tag>
Security Policy
HIGH and CRITICAL vulnerabilities → ❌ Fail the pipeline

LOW and MEDIUM vulnerabilities → ⚠️ Reported but do not fail

A full vulnerability report is archived as a Jenkins build artifact

This policy reflects common industry CI/CD security gates.

5. Notes & Best Practices
Docker-in-Docker is avoided; instead, the Docker socket is mounted

Trivy is containerized to keep the Jenkins agent lightweight

Tests must exist; pytest exits with a non-zero code if no tests are found

The pipeline cleans up Docker images and workspace after each run

