pipeline {
    agent any

    environment {
        AWS_REGION     = 'ap-southeast-2'
        AWS_ACCOUNT_ID = '951066974787'
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Source') {
            steps {
                git branch: 'main', url: 'https://github.com/anupam66kumar/shopNow.git'
            }
        }

        stage('ECR Login') {
            steps {
                sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}'
            }
        }

        stage('Build & Push Backend') {
            steps {
                dir('backend') {
                    sh """
                        docker build -t ${ECR_REGISTRY}/project4-shopnow/backend:${IMAGE_TAG} -t ${ECR_REGISTRY}/project4-shopnow/backend:latest .
                        docker push ${ECR_REGISTRY}/project4-shopnow/backend:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/project4-shopnow/backend:latest
                    """
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                dir('frontend') {
                    sh """
                        docker build --build-arg USER_NAME=project4 -t ${ECR_REGISTRY}/project4-shopnow/frontend:${IMAGE_TAG} -t ${ECR_REGISTRY}/project4-shopnow/frontend:latest .
                        docker push ${ECR_REGISTRY}/project4-shopnow/frontend:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/project4-shopnow/frontend:latest
                    """
                }
            }
        }

        stage('Build & Push Admin') {
            steps {
                dir('admin') {
                    sh """
                        docker build --build-arg USER_NAME=project4 -t ${ECR_REGISTRY}/project4-shopnow/admin:${IMAGE_TAG} -t ${ECR_REGISTRY}/project4-shopnow/admin:latest .
                        docker push ${ECR_REGISTRY}/project4-shopnow/admin:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/project4-shopnow/admin:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    kubectl apply -f k8s/namespace/
                    kubectl apply -f k8s/database/
                    kubectl apply -f k8s/backend/
                    kubectl apply -f k8s/frontend/
                    kubectl apply -f k8s/admin/
                    kubectl apply -f k8s/ingress/
                    kubectl rollout restart deployment backend frontend admin -n shopnow-demo
                """
            }
        }

        stage('Verify Deployment Health') {
            steps {
                sh """
                    kubectl rollout status deployment/backend -n shopnow-demo --timeout=120s
                    kubectl rollout status deployment/frontend -n shopnow-demo --timeout=120s
                    kubectl rollout status deployment/admin -n shopnow-demo --timeout=120s
                    kubectl get pods -n shopnow-demo -o wide
                    kubectl get ing -n shopnow-demo
                """
            }
        }
    }

    post {
        always {
            sh "docker image prune -f"
        }
    }
}
