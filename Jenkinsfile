pipeline {
  agent { label 'docker-python' }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    IMAGE_NAME = "flask-hello"
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    FULL_IMAGE = "${env.IMAGE_NAME}:${env.IMAGE_TAG}"
  }

  stages {
    stage("Checkout") {
      steps {
        checkout scm
      }
    }

    stage("Build (Python deps)") {
      steps {
        sh '''
          set -euxo pipefail
          python3 --version
          python3 -m venv .venv
          . .venv/bin/activate
          python -m pip install --upgrade pip
          pip install -r requirements.txt -r requirements-dev.txt
        '''
      }
    }

    stage("Test") {
      steps {
        sh '''
          set -euxo pipefail
          . .venv/bin/activate
          pytest -q --maxfail=1 --disable-warnings
        '''
      }
    }

    stage("Docker Build") {
      steps {
        sh '''
          set -euxo pipefail
          docker version
          docker build -t "${FULL_IMAGE}" .
        '''
      }
    }

    stage("Security Scan (Trivy)") {
      steps {
        sh '''
          set -euxo pipefail

          # Install trivy if not present (common on Debian/Ubuntu Jenkins agents)
          if ! command -v trivy >/dev/null 2>&1; then
            echo "Installing Trivy..."
            sudo apt-get update -y
            sudo apt-get install -y wget gnupg lsb-release

            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
              | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg

            echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
              | sudo tee /etc/apt/sources.list.d/trivy.list

            sudo apt-get update -y
            sudo apt-get install -y trivy
          fi

          # Fail pipeline on HIGH/CRITICAL vulns
          trivy image --no-progress --severity HIGH,CRITICAL --exit-code 1 "${FULL_IMAGE}"

          # Optional: generate a report artifact
          trivy image --no-progress --severity LOW,MEDIUM,HIGH,CRITICAL "${FULL_IMAGE}" | tee trivy-report.txt
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
        }
      }
    }
  }

  post {
    always {
      sh '''
        set +e
        docker rmi "${FULL_IMAGE}" >/dev/null 2>&1 || true
      '''
      cleanWs()
    }
  }
}
