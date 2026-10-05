# **CAPSTONE PROJECT (Project 4\)**

# 

# **ShopNow: Production MERN Microservices Deployment on AWS EKS**

GITHUB REPO: [https\://github.com/anupam66kumar/shopNow.git](https://github.com/anupam66kumar/shopNow.git) 

An end-to-end DevOps Capstone project demonstrating the automated provisioning, configuration, containerization, deployment, and observability of an enterprise-grade, multi-tier e-commerce platform (**ShopNow**) on Amazon Elastic Kubernetes Service (EKS).

## 

[ShopNow: Production MERN Microservices Deployment on AWS EKS](#heading=)

1. [Project Overview](#heading=)  
   1. [Key Objectives](#heading=)  
2. [System Architecture](#heading=)  
3. [Repository Directory Structure](#heading=)  
4. [Tech Stack & Engineering Trade-Offs](#heading=)  
5. [CI/CD Automation Pipeline](#heading=)  
6. [Step-by-Step Deployment Runbook](#heading=)
   [Prerequisites](#heading=)
   1. [Step 1: Infrastructure Deployment (Terraform)](#heading=)  
   2. [Step 2: Configuration Management (Ansible)](#heading=)  
   3. [Step 3: Application Rollout (Kubernetes)](#heading=)  
7. [Observability & Monitoring](#heading=)  
   1. [Accessing the Grafana Dashboard](#heading=)  
8. [Resilience & Autoscaling Testing](#heading=)  
   1. [Test 1: Pod Self-Healing Verification](#heading=)  
   2. [Test 2: Horizontal Pod Autoscaler (HPA) Verification](#heading=)  
9. [Root Cause Analysis (RCA) & Troubleshooting](#heading=)  
   1. [1\. Docker Daemon Socket Permission Denied](#heading=)  
   2. [2\. MongoDB Volume Stuck in Pending](#heading=)  
   3. [3\. Backend Boot Failure & Mongoose Server Selection Timeout](#heading=)  
   4. [4\. Cross-Subnet / Cross-Node Ingress Timeout](#heading=)  
   5. [5\. Single-Page Application (SPA) Sub-path 404s](#heading=)  
10. [Resource Teardown](#heading=)

> 

## 

## **1\. Project Overview**

The objective of this project is to build an automated, zero-touch deployment lifecycle for the **ShopNow** application. The solution replaces monolithic server setups with a resilient microservices architecture running on AWS EKS, managed via GitOps/Declarative CI/CD pipelines, and monitored with Prometheus and Grafana.

### 

### **1.1 Key Objectives**

* **Infrastructure as Code (IaC):** Modular Terraform code to provision a multi-AZ VPC, EKS Cluster, and EC2 Spot worker node groups.  
* **Configuration Management:** Ansible playbooks for cluster controller bootstrap (NGINX Ingress Controller, Metrics Server, EBS CSI Driver).  
* **Automated CI/CD:** Multi-stage Jenkins declarative pipelines triggered by GitHub Webhooks to test, build, push container images to private Amazon ECR, and roll out deployments.  
* **Stateful Persistence:** Kubernetes StatefulSet for MongoDB backed by AWS EBS gp3 dynamic provisioning.  
* **Ingress Routing & Path Rewriting:** Path-based micro-frontend routing directing external traffic to Storefront, Admin Dashboard, and REST API services through a single AWS Load Balancer.  
* **Full-Stack Observability:** Telemetry and alert monitoring utilizing the kube-prometheus-stack with live Grafana dashboards.

## 

## **2\. System Architecture**

<img width="4096" height="8732" alt="e6ab63e5-e53e-4c2d-9c61-142636199c92" src="https://github.com/user-attachments/assets/c41988d1-cf59-473e-a356-066b99723794" />


## 

## **3\. Repository Directory Structure**

<img width="3644" height="4932" alt="2dff7559-8370-492c-bf45-1917f1b6d69a" src="https://github.com/user-attachments/assets/0403ba10-a649-44fa-86dc-eaabe6966dc9" />


## 

## **4\. Tech Stack & Engineering Trade-Offs**

| Component | Selected Technology | Alternative Considered | Engineering Rationale |
| :---- | :---- | :---- | :---- |
| **Cloud Provider** | AWS (Asia Pacific \- Sydney) | GCP / Azure | Deep integration with EKS, AWS ECR, and fine-grained IAM Role policies for CSI drivers. |
| **Orchestration** | AWS EKS (v1.30) | Self-managed Kubernetes | Eliminates control-plane management overhead; native integration with AWS VPC CNI. |
| **Worker Nodes** | EC2 Spot Instances (t3.medium) | On-Demand Instances | Achieves up to 70% cost reduction during development while testing stateless failover resilience. |
| **Node AMI** | Amazon Linux 2023 (AL2023) | Amazon Linux 2 (AL2) | AL2 bootstrap scripts are deprecated in Kubernetes 1.30+. AL2023 uses standardized systemd initialization. |
| **Stateful DB** | StatefulSet \+ EBS CSI (gp3) | AWS RDS / DocumentDB | Demonstrates native Kubernetes volume persistence and dynamically provisioned PVC life-cycles. |
| **Web Routing** | NGINX Ingress Controller | AWS ALB Ingress Controller | Lightweight, supports rapid local regex rewriting rules (rewrite-target: /\$2), and avoids multi-ALB billing. |
| **CI/CD** | Jenkins Declarative Pipelines | GitHub Actions | Complete on-premise pipeline ownership, local Docker socket execution, and direct IAM node role integration. |
| **Observability** | Prometheus Operator \+ Grafana | AWS CloudWatch Container Insights | Open-source, vendor-neutral metric scraping with zero per-metric AWS CloudWatch ingestion fees. |

## 

## **5\. CI/CD Automation Pipeline**

The deployment process follows a 3-tier chained architecture:

<img width="734" height="693" alt="carbon (4)" src="https://github.com/user-attachments/assets/29459a5e-a0a0-4b4e-95a0-280d0aa8e234" />

##

##
\[SCREENSHOT: Jenkins Pipelines\]  

<img width="1920" height="1080" alt="Screenshot from 2026-10-02 21-13-21" src="https://github.com/user-attachments/assets/e6a6f299-7ae0-46b3-a844-4533e3817532" />

## 

## **6\. Step-by-Step Deployment Runbook**

### 

### **Prerequisites**

* AWS CLI installed and configured with appropriate IAM Administrator credentials.  
* Terraform v1.5+ and Ansible v2.15+ installed.  
* Docker and kubectl matching Kubernetes v1.30.

### 

\[SCREENSHOT: Jenkins master EC2 Deployed\]  
<img width="1598" height="551" alt="Screenshot from 2026-10-02 19-36-08" src="https://github.com/user-attachments/assets/069b2df6-a3a8-487a-9f94-ec98d2b57742" />


### **6.1 Step 1: Infrastructure Deployment (Terraform)**

1. Navigate to the terraform directory:  
>    Bash  
>    cd terraform  
>    terraform init  
>    terraform plan \-var-file="terraform.tfvars"

2. Provision the AWS resources:  
>    Bash  
>    terraform apply \-var-file="terraform.tfvars" \-auto-approve

3. Update local cluster credentials:  
>    Bash  
>    aws eks update-kubeconfig \--region ap-southeast-2 \--name project4-shopnow-eks  
>    kubectl get nodes \-o wide

### **6.2 Step 2: Configuration Management (Ansible)**

1. Run the Ansible playbook to bootstrap cluster controllers:  
>    Bash  
>    cd ../ansible  
>    ansible-playbook \-i inventory/hosts.ini playbook.yml

2. Verify ingress controller and storage class readiness:  
>    Bash  
>    kubectl get sc  
>    kubectl get pods \-n ingress-nginx  
>    kubectl get svc \-n ingress-nginx

### 

### **6.3 Step 3: Application Rollout (Kubernetes)**

1. Create the application namespace:  
>    Bash  
>    kubectl apply \-f k8s/namespace/

2. Deploy the MongoDB StatefulSet:  
>    Bash  
>    kubectl apply \-f k8s/database/  
>    kubectl rollout status statefulset/mongo \-n shopnow-demo \--timeout=180s

3. Initialize the database authentication credentials:  
>    Bash  
>    kubectl \-n shopnow-demo exec \-it mongo-0 \-- mongosh \--eval "  
>    use admin;  
>    db.createUser({  
>      user: 'shopuser',  
>      pwd: 'ShopNowPass123',  
>      roles: \[  
>        { role: 'readWrite', db: 'shopnow' },  
>        { role: 'dbAdmin', db: 'shopnow' }  
>      \]  
>    });  
>    "

4. Deploy the microservices and ingress rules:  
>    Bash  
>    kubectl apply \-f k8s/backend/  
>    kubectl apply \-f k8s/frontend/  
>    kubectl apply \-f k8s/admin/  
>    kubectl apply \-f k8s/ingress/

5. Confirm rollout status across all deployments:  
>    Bash  
>    kubectl rollout status deployment/backend \-n shopnow-demo \--timeout=120s  
>    kubectl rollout status deployment/frontend \-n shopnow-demo \--timeout=120s  
>    kubectl rollout status deployment/admin \-n shopnow-demo \--timeout=120s

\[SCREENSHOT: EKS Cluster Deployed\]  
<img width="1284" height="3672" alt="project4-shop eks cluster" src="https://github.com/user-attachments/assets/1f7f3828-4518-4bc5-8142-83482a9465d8" />


\[SCREENSHOT: EKS Nodes on EC2\]  
<img width="1920" height="1080" alt="Screenshot from 2026-10-02 21-47-39" src="https://github.com/user-attachments/assets/8fb962e3-b6af-44a3-8fd8-d7e3c3be9508" />


\[SCREENSHOT: Customer Panel of ShopNow App\]  
<img width="1920" height="1080" alt="Screenshot from 2026-10-02 20-47-42" src="https://github.com/user-attachments/assets/ff95c960-16ef-41ec-9bf6-2f108dfabcf7" />


## 

\[SCREENSHOT: Admin Panel of ShopNow App\]  
<img width="1920" height="1080" alt="Screenshot from 2026-10-02 20-47-59" src="https://github.com/user-attachments/assets/5cd783a2-9f8a-4708-86e1-0e273178ab34" />


## 

## **7\. Observability & Monitoring**

The monitoring stack is deployed via Helm using the kube-prometheus-stack chart.

>    Bash  
>    \# 1\. Add Prometheus Helm Repository  
>    helm repo add prometheus-community https\://prometheus-community.github.io/helm-charts  
>    helm repo update

>    \# 2\. Deploy the Stack with custom resource limits and LoadBalancer access  
>    helm install monitoring prometheus-community/kube-prometheus-stack \\  
>      \--namespace monitoring \--create-namespace \\  
>      \--set grafana.service.type=LoadBalancer \\  
>      \--set grafana.adminPassword="AdminPassword123\!" \\  
>      \--set grafana.resources.requests.cpu=100m \\  
>      \--set grafana.resources.requests.memory=256Mi

### **7.1 Accessing the Grafana Dashboard**

1. Retrieve the Load Balancer DNS:  
>    Bash  
>    kubectl get svc monitoring-grafana \-n monitoring \-o jsonpath='{.status.loadBalancer.ingress\[0\].hostname}'

2. Open the URL in your browser:  
   * **Username:** admin  
   * **Password:** AdminPassword123\!

3. Select Dashboard: **Kubernetes / Compute Resources / Namespace (Pods)** $\rightarrow$ Select shopnow-demo to view real-time CPU, memory, network, and quota metrics.

>   
\[SCREENSHOT: Grafana Dashboard showing CPU and Memory Utilization for the nodes in Shop-Now-Demo Namespace using Prometheus as DataSource\]  
<img width="1920" height="1080" alt="Screenshot from 2026-10-02 21-12-06" src="https://github.com/user-attachments/assets/bf3f1611-42f9-49ed-ba35-5ae5811525d3" />
> 

##

## **8\. Resilience & Autoscaling Testing**

### **8.1 Test 1: Pod Self-Healing Verification**

Confirm that Kubernetes automatically reconciles desired state if a pod crashes or is terminated:

>    Bash  
>    \# Delete an active backend pod  
>    kubectl delete pod \-n shopnow-demo \-l app=backend \--now | head \-n 1

>    \# Watch replacement replica provision immediately  
>    kubectl get pods \-n shopnow-demo \-l app=backend \-w

### **8.2 Test 2: Horizontal Pod Autoscaler (HPA) Verification**

Generate simulated HTTP traffic to trigger CPU thresholds (\$\>75\\%\$ utilization):

>    Bash  
>    \# In Terminal 1: Watch the HPA state  
>    kubectl get hpa backend-hpa \-n shopnow-demo \-w
>    
>    \# In Terminal 2: Run a multi-threaded load generator  
>    kubectl run load-generator \--image=curlimages/curl \--rm \-it \--restart=Never \-- /bin/sh \-c '  
>    for i in \$(seq 1 15); do  
>      (while true; do  
>        curl \-s http\://backend-service.shopnow-demo.svc.cluster.local:5000/api/products \> /dev/null  
>        curl \-s http\://backend-service.shopnow-demo.svc.cluster.local:5000/api/health \> /dev/null  
>      done) &  
>    done  
>    wait  
>    '

* **Observed Result:** 

*Replica count automatically scaled from 2 to 4 pods once CPU target spiked past 75%. Upon stopping the load generator, replicas cooled down back to 2\.*

\[SCREENSHOT: HPA and LoadTest\]  
<img width="1833" height="801" alt="Screenshot from 2026-10-02 21-19-43" src="https://github.com/user-attachments/assets/19264601-4fcf-4c78-bc7d-189d7dc047ee" />
<img width="1833" height="919" alt="Screenshot from 2026-10-02 21-26-02" src="https://github.com/user-attachments/assets/acdbc310-1c0d-4794-811c-d61024578693" />
<img width="1833" height="524" alt="Screenshot from 2026-10-02 21-27-00" src="https://github.com/user-attachments/assets/ddc8aae6-7dd7-4922-ace4-e45c1360df7c" />


## 

## **9\. Root Cause Analysis (RCA) & Troubleshooting**

During the lifecycle of this deployment, several technical bottlenecks were diagnosed and resolved:

### 

### **9.1. Docker Daemon Socket Permission Denied**

* **Symptom:** Pipeline failure during docker build (permission denied while trying to connect to the docker API at unix:///var/run/docker.sock).  
* **Root Cause:** The jenkins system user was not an active member of the host's docker UNIX group.  
* **Resolution:** Executed sudo usermod \-aG docker jenkins, set socket permissions with sudo chmod 666 /var/run/docker.sock, and restarted docker and jenkins services.

### 

### **9.2. MongoDB Volume Stuck in Pending**

* **Symptom:** Pod mongo-0 remained in Pending indefinitely; PVC showed Pending.  
* **Root Cause:** The EKS Spot worker node IAM role lacked AWS permissions to call EC2 volume attachment APIs.  
* **Resolution:** Attached the AWS-managed policy AmazonEBSCSIDriverPolicy to the worker node IAM role and restarted ebs-csi-controller.

### 

### **9.3. Backend Boot Failure & Mongoose Server Selection Timeout**

* **Symptom:** Backend pods repeatedly entered CrashLoopBackOff (Exit Code 137).  
* **Root Cause:**  
  * The code expected the environment variable MONGODB\_URI, while the manifest declared MONGO\_URI. The app fell back to localhost:27017 instead of mongo:27017.  
    * The liveness probe was checking /health, while the Express route was defined under /api/health.  
* **Resolution:** Standardized k8s/backend/backend.yaml to export both MONGODB\_URI and MONGO\_URI pointing to mongodb://mongo:27017/shopnow, and updated container probes to query /api/health.

### 

### **9.4. Cross-Subnet / Cross-Node Ingress Timeout**

* **Symptom:** Ingress returned 504 Gateway Time-out when routing to pods located on different worker nodes (connect() failed 110: Operation timed out).  
* **Root Cause:** The EKS Node Security Group lacked ingress rules allowing cross-node overlay traffic between worker instances residing in different subnets/availability zones.  
* **Resolution:** Added a security group rule allowing all traffic (-1) where the source group was the Node Security Group itself, and permitted the VPC CIDR 10.0.0.0/16.

### 

### **9.5. Single-Page Application (SPA) Sub-path 404s**

* **Symptom:** Accessing /project4 yielded a blank white page; static assets under /project4/static/js/... threw 404s.  
* **Root Cause:** React was built with PUBLIC\_URL=/project4, but the ingress controller lacked regex path stripping.  
* **Resolution:** Updated k8s/ingress/ingress.yaml to include regex capture groups path: /project4(/|$)(.*)alongsideannotationnginx.ingress.kubernetes.io/rewrite-target:/$2\.

## 

## **10\. Resource Teardown**

To avoid incurring ongoing AWS charges after completing the evaluation:

1. **Delete Kubernetes & Helm Resources:**  
>    Bash  
>    helm uninstall monitoring \-n monitoring  
>    kubectl delete namespace shopnow-demo monitoring

2. **Destroy AWS Infrastructure via Terraform:**  
>    Bash  
>    cd terraform  
>    terraform destroy \-var-file="terraform.tfvars" \-auto-approve

3. **Terminate Jenkins Master:** Stop or terminate the Jenkins EC2 instance from the AWS EC2 Management Console.
