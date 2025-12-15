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

    stage("Build Python dependencies") {
      steps {
        sh '''
          set -euxo pipefail
          python3 --version
          python3 -m venv .venv
          . .venv/bin/activate
          python -m pip install --upgrade pip
          pip install -r requirements.txt
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

      docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy:latest \
        image --no-progress --severity HIGH,CRITICAL --exit-code 1 "${FULL_IMAGE}"

      docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy:latest \
        image --no-progress "${FULL_IMAGE}" | tee trivy-report.txt
    '''
  }
  post {
    always {
      archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
    }
  }
}
  }
}
