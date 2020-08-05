![](./images/vmware-logo.png)

![](./images/concourse-title.png)

## Overview

This 2 hour hands-on session will provide developers and operators with hands on experience building delivery pipelines using Concourse. 

## Content

### Introduction
- Workshop Orientation
- Intro to Concourse: link:presentation/concourse.pptx[_Concourse Intro_]

### Labs
- link:labs/pre-reqs.adoc[_Setup Environment Pre-reqs_]
- link:labs/lab01.adoc[_World’s simplest Concourse Task_]
- link:labs/lab02.adoc[_1st Job on Concourse Server_]
- link:labs/lab03.adoc[_Introduce Git Resource_]
- link:labs/lab04.adoc[_Modularize Tasks and Link Multiple Jobs_]
- link:labs/lab05.adoc[_SSH into a Concourse task to debug on server_]
- link:labs/lab06.adoc[_Push app to CF_]

#

## Intro to Concourse

- Concourse is an Open Source Continuous Integration Tool. It has a simple and yet very effective architecture:

   - Command-line interface called **fly**
   - A Server component that runs the web UI and the API called from the command-line. 
   - The Web UI is only used for displaying the state of the pipelines and for triggering pipelines manually. 
   - All other tasks are performed via the fly CLI.
   - Worker machines where pipelines run

- Design Principles:

   - No snowflakes: there is no configuration of concourse server that we can apply on run-time, no gui, etc.
   - Usability in mind (with a single click you get what you need)
   - Isolated builds. There is no longer build pollution because everything runs in a container
   - Scalable. To add more capacity, we add more Worker machines.
   - No plugins but docker images. You bring your own docker image. You don't depend on pre-installed plugins.
   - We don't need to backup concourse. Instead we should find a way to simply redeploy our pipelines again.
   - Infrastructure agnostic (we can deploy it in AWS, vSphere, GCP, Azure, others)

## Workshop Orientation: Guidelines & Conventions

- This self-paced workshop includes presentations, videos, demos and most of all, hands-on labs. 
- The labs are interdependent and must be executed in order.
- The lab environments will only be available during the ~5hrs (a limited window of time) dedicated for the joint start and self-paced completion of the workshop.
- Please use the [Workshop Google Sheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing) to claim a UserID for this workshop. For example, Ralph Meira is user1.
- Update the same [Workshop Google Sheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing)  as you progress through the Labs, by placing an "X" in the appropriate column.
- Each workshop participant will be assigned a Ubuntu VM previously set up for the execution of hands-on Labs. Your Laptop or Desktop will only be used for two purposes: 
     - SSH'ing or PuTTY'ing into the Ubuntu VM 
     - Browsing web pages
- When carrying out hands-on labs, you will be asked to cut-&-paste the commands shown `in boxes like this one` from this GitHub page to your Ubuntu VM Terminal Window. However, when issuing commands, please make sure to alter the UserID to match the one you have claimed, e.g.:
  - `ssh -i fuse.pem ubuntu@user3.pks4u.com` is for `user3` 
  - `ssh -i fuse.pem ubuntu@user15.pks4u.com` is for `user15` 
- In order to simplify the cut-&-paste-&-replace steps described above, once you are operating on your Ubuntu VM Terminal, we will define environment variables that will hold your specific login name as claimed in the [Workshop Google Sheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing). In this way, the cut-&-paste steps will not require you to edit the command line before pressing `return`.
- As you work through the labs, please make every **effort to not just cut-&-paste-&-execute the labs without actually asking yourself a few questions**:
   - Why am I being asked to cut-&-paste-&-execute these commands?
   - What do I think these commands will do (before actually running them)?
   - What is the role of the person who will be executing these commands in the future?

- Throughout this document, when it's time for hands-on labs, you will see the following icon:
     
![](./images/lab.png)

-----------------------------------------------------

## LAB-1: SSH into your Linux Workshop VM environment & Let's get Concourse up and running locally

![](./images/lab.png)

- Let's start by logging into the Workshop environment from your machine (Mac, PC, Laptop, Desktop, Terminal, VDI). You will need to use the following private key: 
   - [fuse.pem](./fuse.pem) if using a Mac.
   - [fuse.ppk](./fuse.ppk) if using a Windows PC.

- In the pre-requisites section of this workshop, you were asked to use `ssh` or `PuTTY` to access the Ubuntu VM that has been assigned to your [UserID](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing). Please go ahead and create a Terminal Session into your VM. The example shown below applies to `user1` if he or she had downloaded the `fuse.pem` key to a Mac. If you need, the `PuTTY` instructions for Windows PC users can be found [here](./PuTTY_and_SSH.md).

```
ssh -i ~/Downloads/fuse.pem ubuntu@user1.pks4u.com 
```

- Once logged in, you can ignore any messages that ask you to perform a `do-release-upgrade`. 

- Please check whether the greeting information matches your UserID. For example, `user1` should see something like this:

```
my_number is 1
openjdk version "1.8.0_252"
OpenJDK Runtime Environment (build 1.8.0_252-8u252-b09-1~18.04-b09)
OpenJDK 64-Bit Server VM (build 25.252-b09, mixed mode)
Your UserID is user1
Your DevopsID is devops1
Your Namespace in the Shared-Cluster is namespace1
Your role in the Shared-Cluster is vmware-role1
```

- If you believe your greeting information to be wrong, please alert the workshop organizers. 

- If all is well, please proceed by executing the following commands. These commands will validate that your VM has all the necessary CLIs and frameworks for this workshop. Your VM may seem a bit slow in the beginning but it will speed up as you progress through the labs.

```
cf login -a api.sys.ourpcf.com -u $user -p password
git version
java -version
mvn -version
dotnet --version
docker --version
docker-compose --version
```

- If any of the commands shown above did not work or produced and error, please alert the workshop organizers.

- Please execute the following command to create a `docker-compose.yml` file that will start Concourse locally on your Workshop VM:

```
cd ~; rm -rf concourse; mkdir concourse; cd ~/concourse
cat << EOF > docker-compose.yml
---
version: "3"

services:
  concourse-db:
    image: postgres
    environment:
      - POSTGRES_DB=concourse
      - POSTGRES_PASSWORD=concourse_pass
      - POSTGRES_USER=concourse_user
      - PGDATA=/database

  concourse:
    image: concourse/concourse:5.6.0
    command: quickstart
    privileged: true
    depends_on: [concourse-db]
    ports: ["8080:8080"]
    environment:
      - CONCOURSE_POSTGRES_HOST=concourse-db
      - CONCOURSE_POSTGRES_USER=concourse_user
      - CONCOURSE_POSTGRES_PASSWORD=concourse_pass
      - CONCOURSE_POSTGRES_DATABASE=concourse
      - CONCOURSE_EXTERNAL_URL
      - CONCOURSE_ADD_LOCAL_USER=admin:admin
      - CONCOURSE_MAIN_TEAM_LOCAL_USER=admin
EOF
```

- Let's start Concourse by executing the following command. Note: the `-d` means `detached`

```
docker-compose up -d
```

- You should see an output similar to the example shown below:

```
Creating network "concourse_default" with the default driver
Pulling concourse-db (postgres:)...
latest: Pulling from library/postgres
bf5952930446: Pull complete
9577476abb00: Pull complete
2bd105512d5c: Pull complete
b1cd21c26e81: Pull complete
34a7c86cf8fc: Pull complete
274e7b0c38d5: Pull complete
3e831b350d37: Pull complete
38fa0d496534: Pull complete
31a8349609a4: Extracting [==============================>                    ]  44.01MB/73.03MB
14e4c2a4b7b7: Download complete
964acfa02beb: Download complete
31b1f20dffc0: Download complete
14771c2930e9: Download complete
2f30edd0ce8a: Pull complete
Digest: sha256:a06e6e6e519b7a329c419f8221edec66cfc45511e8b80e262c12103ba745cf19
Status: Downloaded newer image for postgres:latest
Pulling concourse (concourse/concourse:5.6.0)...
5.6.0: Pulling from concourse/concourse
5667fdb72017: Pull complete
d83811f270d5: Pull complete
ee671aafb583: Pull complete
7fc152dfb3a6: Pull complete
7362f7ffe2bc: Pull complete
9f5f9aabcdb9: Pull complete
Digest: sha256:32ff2e4bf9b4840ae58eb63874d83a25b991db5015b5652b1dac02dd97280d0f
Status: Downloaded newer image for concourse/concourse:5.6.0
Creating concourse_concourse-db_1 ... done
Creating concourse_concourse_1    ... done
```

- Once you get your command prompt back, please use a browser to access your Concourse GUI. The URL will be `userID.pks4u.com:8080` where `userID` is the UserID you claimed in the [Google Spreadsheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing)

![](./images/welcome-to-concourse.png)

- If your company allows it, you can click on either the Apple, the Windows Symbol or the Penguim to download to your PC or Mac the **fly** CLI. We will continue to use the Workshop VM which already has the **fly** CLI installed.

- The **fly** CLI is just a single, self-contained executable file.

- 






**Let's recap:** 
- You ssh'ed into your Workshop VM and verified the versions of certain installed CLIs (Command Line Interface) such as the cf CLI.
- You used `cf login` to point to a TAS platform and to login. You then used `cf push` to  push your first App to TAS: a game of chess.
- Please note that:
  - Your Chess App has a FQDN (fully qualified domain name)
  - Your App is secured by a valid Certificate which enables HTTPS communication
  - Your App was containerized using curated packages and deployed on the cloud in an HA environment
  - As a developer, you did not have to worry about container filesystems and dependencies.
  - Your App code, `index.php`, had no dependencies linked to the PaaS or IaaS you are using. You are completely cloud agnostic.
  - Your App is running on a platform that is 100% up to date with the latest known [CVE](https://cve.mitre.org/) patches
  - You did not have to open any tickets with Infrastructure, Operations, Networking, Security, ... to deploy your App.
  - And yet, access to your Chess App is going through routers, load balancers, firewalls and benefiting from valid certificates. 
  - Your Chess App has also been wired-in for logging (with log consolidation) and APM (Application Performance Monitoring).
  - No wonder developers love TAS.

- Congratulations, you have completed LAB-1.

Please update the [Workshop Google Sheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing) with an "X" in the appropriate column.


-----------------------------------------------------


- Let's get ssh'ed into your Workshop VM. Please use your UserID from the Google Spreadsheet.

```
ssh -i ~/Download/fuse.pem ubuntu@user1.pks4u.com




## Where to go from Here??

- link:https://github.com/azwickey-pivotal/volume-demo[Create a pipeline that uses Semantic Versioning (SemVer) and checks pipeline outputs into git as a git release]
- link:https://github.com/azwickey-pivotal/volume-demo[Cloudfoundry Blue/Green deployment]
- link:https://github.com/azwickey-pivotal/concourse-deploy-gemfire[Create a pipeline that uses BOSH to deploy software]


- You can check how Concourse compares with other CI tools here: http://concourse.ci/concourse-vs.html
