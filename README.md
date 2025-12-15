# Flask CI/CD Pipeline with Jenkins, Docker, and Trivy

This repository demonstrates a simple **Flask “Hello World” application** with an end-to-end **CI/CD pipeline** implemented using **Jenkins**, **Docker**, and **Trivy** for container security scanning.

It is designed to be:
- Easy to run locally
- Easy to containerize
- Easy to onboard into a **local Jenkins setup**
- Representative of real-world CI/CD best practices

---

## Project Structure

```text
.
├── hello.py            # Flask application
├── test_hello.py       # Pytest unit test
├── requirements.txt    # Python dependencies
├── Dockerfile          # Docker image definition
├── Jenkinsfile         # Jenkins Declarative Pipeline
└── README.md           # Documentation
```

---

## 1. Run the Application Locally (Without Docker)

### Prerequisites
- Python 3.10+
- pip

### Steps

Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the Flask app:

```bash
python hello.py
```

Access the application:

```
http://127.0.0.1:5001
```
---

## 2. Build and Run the Application with Docker

### Build the Docker Image

```bash
docker build -t flask-hello:local .
```

### Run the Container

```bash

docker run -d -p 5001:5001 flask-hello:local
```

Access the application, built via Docker now:

```
http://localhost:5001
```

---

## 3. Local Jenkins Setup (Controller)

### Start Jenkins (Controller)

```bash
docker pull jenkins/jenkins:lts
docker volume create jenkins_home

docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

Get the initial admin password:

```bash
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open Jenkins UI:

```
http://localhost:8080
```

Install **Suggested Plugins** and create an admin user.

---

## 4. Jenkins Agent Setup (Docker-Capable)

This Jenkins agent is a custom inbound Docker-based agent that provides Python build tooling and the Docker CLI, allowing Jenkins pipelines to build, test, containerize, and security-scan applications by interacting with the host Docker daemon through the Docker socket.

Create a file `Dockerfile.jenkins-agent` in your local computer:

```dockerfile
FROM jenkins/inbound-agent:latest-jdk17

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release git \
    python3 python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

USER jenkins
```

Build the agent image:

```bash
docker build -t jenkins-agent-docker-python -f Dockerfile.jenkins-agent .
```

---

## 5. Register and Run Jenkins Agent(from Jenkins UI)

In Jenkins UI → Manage Jenkins → Nodes
- New Node
- Name: `docker-python-agent`
- Type: Permanent Agent
- Remote root directory : /home/jenkins
- Labels: `docker-python`
- Launch method: **Launch agent by connecting it to the controller**
- Save
- Jenkins will show you a command with a secret like:

  -secret <LONG_SECRET>

**Copy that secret and use as 'JENKINS_SECRET' value in the below docker run command.**

Run the agent container:

```bash
docker run -d --name docker-python-agent \
  --user root \
  -e JENKINS_URL=http://host.docker.internal:8080 \
  -e JENKINS_AGENT_NAME=docker-python-agent \
  -e JENKINS_SECRET=<PASTE_SECRET> \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-agent-docker-python
```

---

## 6. Onboard This Git Repo into Jenkins

### Required Plugins
- Pipeline
- Git
- GitHub (optional)
- Pipeline: Stage View
- Workspace Cleanup

### Create a Pipeline Job

**Pipeline Job**
- Definition: Pipeline script from SCM
- SCM: Git
- Repo: `https://github.com/sangeethaguhan/flask-pipeline.git`
- Branch: `*/main`
- Script Path: `Jenkinsfile`

---

## 7. Jenkins Pipeline Stages

| Jenkins Stage            | Description                                  | Requirement Covered        |
|--------------------------|----------------------------------------------|----------------------------|
| Checkout                 | Clones the Git repository                    | Source control integration |
| Build (Python deps)      | Creates virtualenv and installs dependencies | Application build          |
| Test                     | Runs unit tests using pytest                 | Automated testing          |
| Docker Build             | Builds Docker image                          | Containerization           |
| Security Scan (Trivy)    | Scans image for vulnerabilities              | Security scanning          |
| Post Actions             | Cleanup images and workspace                 | CI hygiene                 |

---

## 8. Trivy Security Scanning

- Trivy runs as a container
- Docker socket is mounted
- Scan runs after image build

Policy:
- **HIGH / CRITICAL** → Pipeline fails
- **LOW / MEDIUM** → Report only

---

## 9. Verification
Make sure your Flask app is running on port 5001
If running locally (host Python)

In hello.py:

```if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
```

Then start it on your host:

```python hello.py```


Now test again in local laptop:

```curl http://localhost:5001```


Then from inside Jenkins agent:

```docker exec -it docker-python-agent bash -lc "curl -v http://host.docker.internal:5001"```

** Curl call from inside docker container **
```root@85b4e4d423fd:/home/jenkins# docker exec -it docker-python-agent bash -lc "curl -v http://host.docker.internal:5001"
* Host host.docker.internal:5001 was resolved.
* IPv6: fdc4:f303:9324::254
* IPv4: 192.168.65.254
*   Trying [fdc4:f303:9324::254]:5001...
* Immediate connect fail for fdc4:f303:9324::254: Network is unreachable
*   Trying 192.168.65.254:5001...
* Connected to host.docker.internal (192.168.65.254) port 5001
* using HTTP/1.x
> GET / HTTP/1.1
> Host: host.docker.internal:5001
> User-Agent: curl/8.14.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Server: Werkzeug/3.1.4 Python/3.12.2
< Date: Mon, 15 Dec 2025 06:19:47 GMT
< Content-Type: text/html; charset=utf-8
< Content-Length: 40
< Connection: close
< 
* shutting down connection #0
Hello World, this is Palo Alto Networks!root@85b4e4d423fd:/home/jenkins# ```
