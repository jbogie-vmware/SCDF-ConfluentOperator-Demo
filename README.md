# Getting Started with Spring Cloud Data Flow and Kafka

A Spring Cloud Data Flow demo on Kubernetes with Kafka provided by the Confluent Operator and VMware Tanzu Kubernetes Grid.  

## Environment Requirements

### TKGI or TKG  

**TKGI:**  
To demo the full stack refer to this repo to setup a Confluent Operator environment running on TKGI [jbogie-vmware/tkgi-confluent-operator](https://github.com/jbogie-vmware/tkgi-confluent-operator).

**TKG:**  
COMING SOON

### Spring Cloud Data Flow

To walkthrough SCDF's streaming, batch, analytics, and observability features, the following components will be provisioned in the Kubernetes cluster.

1. Spring Cloud Data Flow
2. Spring Cloud Skipper
3. Prometheus
4. Grafana
5. Apache Kafka
6. MariaDB 

## Demo Applications

1. [`trucks`](https://github.com/jbogie-vmware/SCDF-ConfluentOperator-Demo/tree/master/thumbinator) — generates trucks in random interval
2. [`brake-temperture`](https://github.com/jbogie-vmware/SCDF-ConfluentOperator-Demo/tree/master/brake-temperature) — computes moving average of truck's brake temperature in 10s interval
3. [`brake-logs`](https://github.com/jbogie-vmware/SCDF-ConfluentOperator-Demo/tree/master/brake-logs) — prints the truck data
4. [`thumbinator`](https://github.com/jbogie-vmware/SCDF-ConfluentOperator-Demo/tree/master/thumbinator) — a task/batch-job that can create thumbnails from images


The demo on the Spring Cloud Data Flow's [Bitnami chart](https://github.com/bitnami/charts/tree/master/bitnami/spring-cloud-dataflow). Students will have to run the `scripts/deploy-scdf.sh` script that is available at [jbogie-vmware/SCDF-ConfluentOperator-Demo](https://github.com/jbogie-vmware/SCDF-ConfluentOperator-Demo).

## Agenda

```sequence
Strigo->Lab: Start the Lab in Strigo

Note left of Prepare: You'll do this *once*
Lab->Prepare: Start minikube
Lab->Prepare: Deploy SCDF stack
Lab->Prepare: Build applications
Lab->Prepare: Generate docker images

Prepare-->Lab: Stuck? Cleanup and repeat

Prepare->Streaming Lab: Build an IoT streaming data pipeline
Prepare->Streaming Lab: Deploy a stream from SCDF to K8s; verify results
Prepare->Streaming Lab: Monitor performance using Prometheus & Grafana

Streaming Lab-->Prepare: Stuck? Cleanup and repeat; ask questions

Prepare->Batch Lab: Build and design a batch data pipeline
Prepare->Batch Lab: Launch the batch-job from SCDF to K8s; verify results
Prepare->Batch Lab: Schedule the batch-job in SCDF to K8s; verify results
Prepare->Batch Lab: Monitor performance using Prometheus & Grafana

Batch Lab-->Prepare: Stuck? Cleanup and repeat; ask questions

```

## Labs
To get started with the labs, first, you will have to prepare the environment.

When you log in to Strigo with your access token, you will have to click the "My Lab" button on the left-nav to prepare the lab VM.

![My Lab](https://i.imgur.com/kglWS7X.png)

> After you login to the VM, test the environment by running the `scripts/test-env.sh` script — see example below.

```bash
[ec2-user@ip ]$ cd SpringOne2020
[ec2-user@ip SpringOne2020]$ sh scripts/test-env.sh 
docker is ready
minikube is ready
helm is ready
kubectl is ready
k9s is ready
java is ready
mvn is ready
```

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

#### Build Applications
Now that we have had a look at the applications, let's build them.

```bash
[ec2-user@ip-172-31-19-111 ~]$ cd SpringOne2020

[ec2-user@ip-172-31-19-111 SpringOne2020]$ git pull
Already up to date.

[ec2-user@ip-172-31-19-111 SpringOne2020]$ ls -ltr
total 28
-rw-rw-r-- 1 ec2-user ec2-user  6608 Aug 12 20:17 mvnw.cmd
-rwxrwxr-x 1 ec2-user ec2-user 10070 Aug 12 20:17 mvnw
drwxrwxr-x 2 ec2-user ec2-user    47 Aug 14 20:16 scripts
-rw-rw-r-- 1 ec2-user ec2-user  3520 Aug 17 16:18 README.md
-rw-rw-r-- 1 ec2-user ec2-user  2609 Aug 17 19:02 pom.xml
drwxrwxr-x 5 ec2-user ec2-user   104 Aug 17 19:06 trucks
drwxrwxr-x 5 ec2-user ec2-user   104 Aug 17 19:06 brake-temperature
drwxrwxr-x 5 ec2-user ec2-user   104 Aug 17 19:06 brake-logs
drwxrwxr-x 5 ec2-user ec2-user   104 Aug 17 19:07 thumbinator
```

The build attempts to create container images for these applications using the `jib` plugin. 

To configure your local environment to re-use the Docker daemon running inside the Minikube instance, we will run the `eval $(minikube docker-env)` before building the code and generating the docker images.

```bash
[ec2-user@ip-172-31-19-111 SpringOne2020]$ eval $(minikube docker-env)
```

Run the Maven build and generate Docker images using `mvn clean install com.google.cloud.tools:jib-maven-plugin:dockerBuild -DskipTests` command.

```bash
[ec2-user@ip-172-31-19-111 SpringOne2020]$ mvn clean install com.google.cloud.tools:jib-maven-plugin:dockerBuild -DskipTests

[INFO] Scanning for projects...
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Build Order:
[INFO] 
[INFO] labs                                                               [pom]
[INFO] trucks                                                             [jar]
[INFO] brake-temperature                                                  [jar]
[INFO] brake-logs                                                         [jar]
[INFO] thumbinator                                                        [jar]

...
...

[INFO] Container entrypoint set to [java, -cp, /app/resources:/app/classes:/app/libs/*, com.springone.trucks.TrucksApplication]
[INFO] 
[INFO] Built image to Docker daemon as dev.local/trucks, dev.local/trucks:0.0.1-SNAPSHOT
[INFO] Executing tasks:
[INFO] [==============================] 100.0% complete

...
...

[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for labs 0.0.1-SNAPSHOT:
[INFO] 
[INFO] labs ............................................... SUCCESS [  6.388 s]
[INFO] trucks ............................................. SUCCESS [ 42.855 s]
[INFO] brake-temperature .................................. SUCCESS [ 10.615 s]
[INFO] brake-logs ......................................... SUCCESS [  4.851 s]
[INFO] thumbinator ........................................ SUCCESS [  5.697 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  01:12 min
[INFO] Finished at: 2020-08-19T18:36:29Z
[INFO] ------------------------------------------------------------------------
```

Verify application images in the local registry under the `dev.local` repository.

```bash
[ec2-user@ip-172-31-19-111 SpringOne2020]$ docker images | grep dev.local
dev.local/thumbinator                     0.0.1-SNAPSHOT          a2f62650b367        50 years ago        233MB
dev.local/thumbinator                     latest                  a2f62650b367        50 years ago        233MB
dev.local/brake-logs                      0.0.1-SNAPSHOT          e914bf6237ab        50 years ago        250MB
dev.local/brake-logs                      latest                  e914bf6237ab        50 years ago        250MB
dev.local/trucks                          0.0.1-SNAPSHOT          f1da7c4eb7aa        50 years ago        250MB
dev.local/trucks                          latest                  f1da7c4eb7aa        50 years ago        250MB
dev.local/brake-temperature               0.0.1-SNAPSHOT          61e84d293eb9        50 years ago        264MB
dev.local/brake-temperature               latest                  61e84d293eb9        50 years ago        264MB
```

#### IoT — Real-time Truck's Brake Temperature Analysis

If you haven't already prepared the environment, please review [Lab-1-Prepare-Environment](https://hackmd.io/@sabbyanandan/B1bDf74fv#Lab-1-Prepare-Environment). 

Secondly, this lab assumes that you have [locally built the applications](https://hackmd.io/@sabbyanandan/B1bDf74fv#Build-Applications) and that the container images are available in the Docker daemon running inside the single-node Minikube cluster.

*Use-case: Imagine there are 100s of freight-trucks on the road and that you're interested in finding out the fleet's performance in real-time. To narrow it down further, imagine if you want to understand the truck's peak performance, given the current load it is carrying. A vital factor to consider is the brake condition, which would have significant wear and tear depending on the freight. It could even be dangerous if it goes unnoticed.*

Given that background, we will deploy a streaming data pipeline in SCDF with three applications.

1. [`trucks`](https://github.com/sabbyanandan/SpringOne2020/tree/master/thumbinator) — generates truck data in a random interval
2. [`brake-temperture`](https://github.com/sabbyanandan/SpringOne2020/tree/master/brake-temperature) — computes moving average of a truck's brake temperature in 10s interval
3. [`brake-logs`](https://github.com/sabbyanandan/SpringOne2020/tree/master/brake-logs) — logs the output in real-time

> Applications rely-on and use Spring Cloud Stream's [Apache Kafka binder implementation](https://cloud.spring.io/spring-cloud-static/spring-cloud-stream-binder-kafka/3.0.6.RELEASE/reference/html/spring-cloud-stream-binder-kafka.html#_apache_kafka_binder). However, the real-time computations inside the `brake-temperature` application uses the Spring Cloud Stream's [Kafka Streams binder](https://cloud.spring.io/spring-cloud-static/spring-cloud-stream-binder-kafka/3.0.6.RELEASE/reference/html/spring-cloud-stream-binder-kafka.html#_kafka_streams_binder).

#### Review Applications
The source code for `trucks`, `brake-temperature`, and `brake-logs` are under the `SpringOne2020` directory. You can open the code in IDE as described at [Explore-Application-Code](https://hackmd.io/@sabbyanandan/B1bDf74fv#Explore-Application-Code-optional) section. 


Given the lab's time constraints, we will attempt only to build and deploy the applications instead of extending or customizing the behavior. If you manage to run the lab quickly, feel free to crack at any customizations, and redeploy as you find appropriate.

#### Deploy Stream
1. Let's open SCDF and register the three new applications that are already available in the Docker registry.

    The coordinates for the 3 applications are:
    ```properties
    source.trucks=docker:dev.local/trucks:0.0.1-SNAPSHOT
    processor.brake-temperature=docker:dev.local/brake-temperature:0.0.1-SNAPSHOT
    sink.brake-log=docker:dev.local/brake-logs:0.0.1-SNAPSHOT
    ```
    
    > If in case you aren't able to locally build the applications, you can register the applications from Docker Hub.
    
    >```properties
    >source.trucks=docker:sabby/trucks:0.0.1-SNAPSHOT
    >processor.brake-temperature=docker:sabby/brake-temperature:0.0.1-SNAPSHOT
    >sink.brake-log=docker:sabby/brake-logs:0.0.1-SNAPSHOT

    Navigate to "Application(s)" section and select "Bulk import application" as the option. On the right-frame, copy+paste the three application coordinates to import the applications to SCDF's application registry.

    ![Bulk register stream apps](https://i.imgur.com/rk78efy.png)

    ![Register Apps](https://i.imgur.com/becR6tm.png)
    
2. Now that we have the applications registered, it is time to create and deploy a stream.

    Click the "Streams" link from the left-navigation and open the "Create Stream(s)" page. Copy the following streaming DSL command into the DSL text area in the dashboard. Alternatively, you can drag +drop the apps in the canvas and interactively configure the desired properties.
    
    ```dsl
    truck-performance = trucks --spring.cloud.stream.function.bindings.generateTruck-out-0=output | brake-temperature --spring.cloud.stream.function.bindings.processBrakeTemperature-in-0=input --spring.cloud.stream.function.bindings.processBrakeTemperature-out-0=output | brake-log --spring.cloud.stream.function.bindings.log-in-0=input
    ```
    > In case you're wondering about `--spring.cloud.stream.function...` in-line properties, and what they mean, you can learn more about Spring Cloud Stream's function bindings and the naming conventions from the [reference guide](https://cloud.spring.io/spring-cloud-static/spring-cloud-stream/3.0.6.RELEASE/reference/html/spring-cloud-stream.html#_functional_binding_names).
    
    ![Build Stream](https://i.imgur.com/kXH1tSu.png)

    
    Click "Create Stream(s)" button and deploy the `truck-performance` stream from the list page.
    
    ![Create Stream](https://i.imgur.com/Kwcbknn.png)

    SCDF is now in the process of programmatically creating the Kubernetes deployment manifests for the three applications and deploying them onto Kubernetes. You can switch to the "Terminal" tab and review the new pods from the `k9s` output.
    
    ![Deploying Stream Pods](https://i.imgur.com/BrvLcDw.jpg)

    > The applications take ~1-2 mins to start and for the liveness/readiness probes to be running correctly.
    
3. Let's review the results by tailing the logs of `truck-performance-brake-log-v1-***` application. Alternatively, you can open the logs from SCDF's dashboard, too.
    
    ![Truck Logs](https://i.imgur.com/AMK8H2f.jpg)
    
    You will notice the computed moving-average in the logs, in real-time. See below an example that includes the average brake temperature for the truck with the ID="JH4KA8170MC002642".
    
    ```json
    {
      "average": 14.967257499694824,
      "count": 3,
      "end": 1597875620000,
      "id": "JH4KA8170MC002642",
      "start": 1597875610000,
      "totalValue": 44.90177
    }
    ```

#### Monitor Stream Performance
Now that the real-time streaming data pipeline is running in Kubernetes, we will next review the steps to monitor the streaming applications using Prometheus and Grafana.

All the heavy-lifting of configuring Prometheus, Grafana, and preparing the applications for metrics scrapping is already handled automatically by SCDF.

Click the `Grafana Dashboard` tab to navigate to the Grafana GUI. For the login, you need to find the admin password from the Kubernetes secrets. To retrieve and decode the password, run the following in the terminal window.

```command
kubectl -n monitoring get secret graf-grafana-admin -o jsonpath={.data.GF_SECURITY_ADMIN_PASSWORD} | base64 --decode
```

Example:
```cli
[ec2-user@ip-172-31-30-179 ~]$ kubectl -n monitoring get secret graf-grafana-admin -o jsonpath={.data.GF_SECURITY_ADMIN_PASSWORD} | base64 --decode
MaHOlr9Vxv
```

In my case, I am using `admin/MaHOlr9Vxv` as the credentials to log-in to Grafana dashboard.

> The user is `admin`, but the password would be a randomly generated token for every student. You will have to run the above `kubectl` command to retrieve it. The password will be different for *every* student.

The SCDF-specific metrics dashboards are preloaded in the Grafanaa service running in your Kubernetes cluster. First time when you login, you will have to go to the "Manage" section to find the dashboards.

![Grafana 1](https://i.imgur.com/fICQ2gZ.png)

Click the "Applications" dashboard to view the real-time performance of the streaming applications.

![Grafana 2](https://i.imgur.com/HAQs2dD.png)

That's it! You have completed lab #2. :boom: :rocket:

### Lab 3: Batch-style Data Pipelines

If you haven't already prepared the environment, please review [Lab-1-Prepare-Environment](https://hackmd.io/@sabbyanandan/B1bDf74fv#Lab-1-Prepare-Environment).

This lab assumes that you have already [built the applications](https://hackmd.io/@sabbyanandan/B1bDf74fv#Build-Applications) and that the container images are available in the Docker daemon running inside the single-node Minikube cluster.

#### Cloud-native ETL Batch Job
This lab aims to highlight how short-lived and ephemeral-style batch applications can be orchestrated, scheduled, and monitored using Spring Cloud Data Flow.

To demonstrate the features, we will build a Task application ([`thumbinator`](https://github.com/sabbyanandan/SpringOne2020/tree/master/thumbinator)) that includes two batch-jobs internally.

*The first job includes 3-steps to simulate extract, transform, and the loading of data — an ETL job.*

```java
    @Bean
    public Job extractImage() {
        // extract an image
    }
    
    @Bean
    public Job transformImage() {
        // create a thumbnail for the image
    }
    
    @Bean
    public Job loadImage() {
        // load the thumbnail to a different directory
    }
```
*The second job is going to query and print the result.*

```java
    @Bean
    public Job statusImage() {
        // print the size of the original and the thumbnail images
    }
```
> To keep it simple and to repeat the lab easily, this workshop includes multiple jobs inside the *same* application. However, you can choose to create new Task applications for each of the jobs instead, which would allow you to evolve them with bug-fixes and improvements independently, so you can continuously deliver them.

#### Review Application Code
In your Strigo VM, you can follow the [Explore-Application-Code](https://hackmd.io/@sabbyanandan/B1bDf74fv#Explore-Application-Code-optional) steps to review the code of `thumbinator` application.

#### Build and Launch Tasks
Click the "SCDF Dashboard" tab in Strigo to launch SCDF's dashboard. 

1. First, you will have to register the locally built application in SCDF's application registry.

    The Docker coordinate for the `thumbinator` applications is:
    
    ```properties
    task.thumbinator=docker:dev.local/thumbinator:0.0.1-SNAPSHOT
    ```
    
    > If in case you aren't able to locally build the application, you can register the application from Docker Hub.
    
    >```properties
    >task.thumbinator=docker:sabby/thumbinator:0.0.1-SNAPSHOT
    
    ![Register Task App](https://i.imgur.com/teM9hOT.png)

2. Open "Tasks" -> "Create Task(s)"

    ![Build Task](https://i.imgur.com/qGZU2a4.png)

    Give a name to the task definition and create the task.
    
3. Let's launch the task. Click the "play" button from the task list page to manually launch the task with the default parameters and arguments.

    ![Task Launch 1](https://i.imgur.com/PX8Utea.png)
    
    ![Task Launch 1](https://i.imgur.com/BzP0RO6.png)
    
    Look for a newly launched task pod in the `k9s` terminal.

    ![Task Pod](https://i.imgur.com/6kpZdEs.png)

4. Verify the results by tailing the logs of the task pod running in Kubernetes. Switch to `k9s` terminal and look for the "pod" with the name that you assigned to the task. You will find the results from both the jobs in the log.

    ![Task Logs](https://i.imgur.com/nlnU3kE.jpg)

#### Schedule Tasks
In SCDF, there's an out-of-the-box option to schedule task/batch-jobs to launch at a recurring cadence. To do that, SCDF builds on the primitives of `cronjob` spec in Kubernetes.

From the task list page, select the dropdown to choose "Schedule Task".

![Schedule Task](https://i.imgur.com/2F9en0d.png)

Give your schedule a name and schedule the task to launch every minute with the `*/1 * * * *` cron-expression.

![Schedule Cron](https://i.imgur.com/Sj96q1A.png)

Switch back to `k9s` terminal and verify the scheduled creation of pods automatically launching once every minute.

![Scheduled Pods](https://i.imgur.com/g54KDaP.png)

Alternatively, you can also use the `kubectl` command to query the `cronjob` and `job` resources that are running in the Kubernetes cluster.

```bash
[ec2-user@ip-100 ~]$ kubectl get cronjob
NAME             SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
sch-thumbnails   */1 * * * *   False     1        54s             4m27s

[ec2-user@ip-100 ~]$ kubectl get job
NAME                        COMPLETIONS   DURATION   AGE
sch-thumbnails-1597961580   1/1           39s        3m57s
sch-thumbnails-1597961640   1/1           49s        2m57s
sch-thumbnails-1597961700   1/1           40s        117s
sch-thumbnails-1597961760   0/1           57s        57s
```

Let's also verify the task execution details from SCDF's dashboard.

![Task Exec 1](https://i.imgur.com/V30KzCq.png)

![Task Exec 2](https://i.imgur.com/7YfFf5Z.png)

#### Monitor ETL Job

Similar to the monitoring steps discussed in the [event-streaming](https://hackmd.io/@sabbyanandan/B1bDf74fv#Monitor-Stream-Performance) lab, the task monitoring with Prometheus and Grafana is preloaded, and the metrics dashboard is prepared to monitor the tasks running in the Kubernetes cluster.

Go to "Grafana Dashboard" -> "Tasks".

![Task Grafana](https://i.imgur.com/D2sB8IA.png)

Kudos to you for completing lab-3! :trophy: :smile: 

## Appendix
* Source code is at: [sabbyanandan/SpringOne2020](https://github.com/sabbyanandan/SpringOne2020)
* Slides: [SpeakerDeck](https://speakerdeck.com/sabbyanandan/getting-started-with-spring-cloud-data-flow)

:::info
* [Spring Cloud Data Flow Documentation](https://dataflow.spring.io/)
* [Spring Cloud Data Flow Reference Guide](https://docs.spring.io/spring-cloud-dataflow/docs/current/reference/htmlsingle/#getting-started)
* [Spring Cloud Data Flow Samples](https://github.com/spring-cloud/spring-cloud-dataflow-samples)
:::

###### tags: `event streaming` `batch processing` `stateful streams` `predictive analytics` `cloud-native` `microservices` 
