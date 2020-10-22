### Lab 1: Prepare Environment
The first lab starts with setting up a single-node Kubernetes cluster using Minikube. Let's review the steps involved.

#### Set up Kubernetes
Start a single-node Minikube cluster with the `minikube start --vm-driver=docker --kubernetes-version v1.17.0 --memory=10240 --cpus=4` command.

```
[ec2-user@ip-100 ~]$ minikube start --vm-driver=docker --kubernetes-version v1.17.0 --memory=10240 --cpus=4

* minikube v1.12.2 on Amazon 2 (xen/amd64)
* Using the docker driver based on user configuration
* Starting control plane node minikube in cluster minikube
* minikube 1.12.3 is available! Download it: https://github.com/kubernetes/minikube/releases/tag/v1.12.3
* To disable this notice, run: 'minikube config set WantUpdateNotification false'
* Creating docker container (CPUs=4, Memory=10240MB) ...
* Preparing Kubernetes v1.17.0 on Docker 19.03.8 ...
* Verifying Kubernetes components...
* Enabled addons: default-storageclass, storage-provisioner
* Done! kubectl is now configured to use "minikube"
```

> We are using the Docker driver to install Kubernetes into an existing Docker daemon in the VM. This also simplifies the setup because we don't need to worry about extra virtualization to be enabled.

Verify that Minikube is successfully started: `minikube status`.
```
ec2-user@ip-100 ~]$ minikube status

minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Runningkubeconfig: Configured
```
Confirm that the Minikube container is running.
```
[ec2-user@ip-100 ~]$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                                     
                                                 NAMES
539c113531ae        gcr.io/k8s-minikube/kicbase:v0.0.11   "/usr/local/bin/entr…"   9 minutes ago       Up 9 minutes        127.0.0.1:32771->22/tcp, 127.0.0.1:32770->2376/tcp, 127.0.
0.1:32769->5000/tcp, 127.0.0.1:32768->8443/tcp   minikube
```

This command roughly takes about 2-3mins to complete. If for any reason, you notice startup errors, likely, the Docker daemon is still starting in the VM, so re-run the same start command once again. The cluster will start eventually.

#### Set up Spring Cloud Data Flow
It is now time to deploy SCDF! To get started, you will run the `scripts/deploy-scdf.sh` script.

```
[ec2-user@ip-172-31-19-111 ~]$ sh SpringOne2020/scripts/deploy-scdf.sh 

Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈ Happy Helming!⎈ 
Error from server (NotFound): namespaces "monitoring" not found
A namespace called monitoring for prometheus should exist, creating it
A namespace called monitoring exists in the cluster
Error: release: not found
Install bitnami/prometheus-operator prometheus_release_name=prom prometheus_namespace=monitoring
....
....
....
```
This command will take ~5-6mins to finish. Behind the scenes, the script uses Bitnami's Prometheus and Grafana operator to provision the monitoring stack. With that foundation up and running, the script runs SCDF's [Bitnami chart](https://github.com/bitnami/charts/tree/master/bitnami/spring-cloud-dataflow) to deploy the following.

- MariaDB
- Apache Kafka + Zookeeper
- Spring Cloud Data Flow
- Spring Cloud Skipper

While all this is starting, open a terminal session in a new tab and run the [`k9s`](https://k9scli.io/) command to verify the current deployment status.

```
[ec2-user@ip-172-31-19-111 ~]$ k9s
```

![Review SCDF components](https://i.imgur.com/FVsZLQ2.jpg)

#### Verify Environment
When the script completes successfully, you will see the following output.

```bash
[ec2-user@ip-172-31-19-111 ~]$ sh SpringOne2020/scripts/deploy-scdf.sh 
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
...
...
...

### Stack succesfully deployed ###

Connect to Data Flow
    $ helm status scdf
Grafana password
    $ kubectl -n monitoring get secret graf-grafana-admin -o jsonpath={.data.GF_SECURITY_ADMIN_PASSWORD} | base64 --decode
Forward grafana
    $ kubectl port-forward -n monitoring svc/graf-grafana 3000:3000
```

Likewise, you can verify what version of the [Spring Cloud Data Flow's Bitnami helm chart](https://github.com/bitnami/charts/tree/master/bitnami/spring-cloud-dataflow) is currently in use.

```bash
[ec2-user@ip-100 SpringOne2020]$ helm list
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
scdf    default         1               2020-08-20 21:19:45.728756477 +0000 UTC deployed        spring-cloud-dataflow-0.6.1     2.6.0      
```

Before we start the next lab, though, let's verify that SCDF is up and running. We will apply port-forwarding rules for the following pods so that we can test the newly deployed components.

1. ***SCDF***: click `shift+f` on the `scdf-spring-cloud-dataflow-server-***` pod to open the port-forward window in `k9s`; change the "Address" to `0.0.0.0`.
2. ***Grafana***: click `shift+f` on the `graf-grafana-b6bf96c9c-***` pod to open the port-forward window in `k9s`; change the "Address" to `0.0.0.0`.
3. ***Prometheus***: click `shift+f` on the `prometheus-prom-prometheus-operator-prometheus-**` pod to open the port-forward window in `k9s`; change the "Address" to `0.0.0.0`.

Example:
![Port forwarding SCDF](https://i.imgur.com/kDNrRes.jpg)

Now that the stack is ready and the port-forwarding rules are active, we can access SCDF's dashboard by clicking the "SCDF Dashboard" tab in the Strigo platform. If the page doesn't load, hit the "refresh page" button inside the tab.

![SCDF Dashboard](https://i.imgur.com/VZ0MAez.png)

Alternatively, you can review SCDF's Shell access. To do that, switch to the terminal tab, and run the following.

```bash
[ec2-user@ip-172-31-19-111 ~]$ cd scdf-shell

[ec2-user@ip-172-31-19-111 scdf-shell]$ java -jar spring-cloud-dataflow-shell-2.6.0.jar --dataflow.uri=http://localhost:8080
```
![SCDF shell](https://i.imgur.com/cVzZ5WM.png)

> This command might take a few seconds to start. Hang tight. You will see the `dataflow:>` prompt.

Congrats! You have completed lab #1. :slightly_smiling_face: 

### Lab 2: Event Streaming Data Pipelines
This lab will review how to build and deploy event-streaming applications using Spring Cloud Data Flow. Let's begin with reviewing the applications we will use in this lab.

#### Explore Application Code (optional)
To open VS Code, from the terminal window, you will have to start the `code-server` process inside the Strigo lab VM.

```bash
[ec2-user@ip-172-31-19-111 ]$ cd code
[ec2-user@ip-172-31-19-111 code]$ bin/code-server &
[1] 103335
[ec2-user@ip-172-31-19-111 code]$ info  Using config file ~/.config/code-server/config.yaml
info  Using user-data-dir ~/.local/share/code-server
info  code-server 3.4.1 48f7c2724827e526eeaa6c2c151c520f48a61259
info  HTTP server listening on http://0.0.0.0:1111
info    - No authentication
info    - Not serving HTTPS
```
> The `code-server` process takes a ~5-10 seconds to start. You can verify whether the port `1111` is running with `sudo lsof -i -P -n | grep 1111` command in the terminal.

When the `code-server` process is running, click the "IDE" tab in Strigo to open VS Code. Go to `home/ec2-user/SpringOne2020` folder to review the applications we will be using for the labs.

> If the window doesn't load, please click the "refresh page" button inside the "IDE" tab.

![VS Code 1](https://i.imgur.com/9jVNjeO.png)

![VS Code 2](https://i.imgur.com/9GKGWWy.png)