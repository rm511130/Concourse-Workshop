![](./images/vmware-logo.png)
![](./images/concourse-title.png)

## Overview

This 2 hour hands-on session will provide developers and operators with hands on experience building delivery pipelines using Concourse. 

## Content

### Introduction
- Workshop Orientation
- Intro to [Concourse](./presentation/concourse.pptx)

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
   
- [Concourse documentation (e.g. release notes)](https://docs.pivotal.io/p-concourse/v5/rn/)

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
      - CONCOURSE_EXTERNAL_URL=http://$user.pks4u.com:8080
      - CONCOURSE_ADD_LOCAL_USER=admin:admin
      - CONCOURSE_MAIN_TEAM_LOCAL_USER=admin
EOF
```

- Let's start Concourse by executing the following command. Note: the `-d` means `detached`, so once the `docker-compose` command has a Postgres database up and running, as well as the Concourse server components, you should get your Linux prompt back.

```
docker-compose up -d
```

- You should see an output similar to the example shown below. Note: we will be using a bigger, shared Concourse server in subsequent labs, this first Lab is trying to show you that getting started is not difficult at all.

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

- Once you get your command prompt back, please execute the following command to validate that both Concourse and its Postgres database are running:
```
docker ps
```
- The output from the `docker ps` command should look similar to the example shown below. If this is not the case, please alert the Workshop Organizers.
```
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                    NAMES
5f35bf31b282        concourse/concourse:5.6.0   "dumb-init /usr/loca…"   7 seconds ago       Up 5 seconds        0.0.0.0:8080->8080/tcp   concourse_concourse_1
6fa9a7987b4d        postgres                    "docker-entrypoint.s…"   9 seconds ago       Up 6 seconds        5432/tcp                 concourse_concourse-db_1
```

- Use a browser to access your Concourse GUI. The URL will be `userID.pks4u.com:8080` where `userID` is the UserID you claimed in the [Google Spreadsheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing)

![](./images/welcome-to-concourse.png)

- In the future, you can click on either the Apple, the Windows symbol or the Penguim to download the **fly** CLI to your PC or Mac. 
- Note that the Apple, the Windows symbol and the Penguim are also shown on the bottom of your Concourse Web GUI.
- If you do download the **fly** CLI, just remember to place it in a directory that is your `PATH` and to make it executable with, for example, a `chmod +x` commmand. 

- We will continue to use the Workshop VM which already has the **fly** CLI installed. 

- Using the Concourse Web GUI, you can click on the login link, and then log-in as `admin` with password `admin`. Keep your browser open, we will come back to it later, but you may see something interesting things happening on the Concourse Web GUI, as we execute this Lab.

- Back to your Workshop VM, please execute the following commands to target your Concourse CI/CD server:

```
fly --target workshop login --concourse-url http://$user.pks4u.com:8080 -u admin -p admin
```

- If your **fly** CLI is out of synch with your Concourse Server, you can always execute the following command. Please execute the following command:

```
fly --target workshop sync
```

- Now please execute the following command to get acquainted with the **fly** options:

```
fly --help
```

- You should see the following results:

```
Usage:
  fly [OPTIONS] <command>

Application Options:
  -t, --target=              Concourse target name
  -v, --version              Print the version of Fly and exit
      --verbose              Print API requests and responses
      --print-table-headers  Print table headers even for redirected output

Help Options:
  -h, --help                 Show this help message

Available commands:
  abort-build          Abort a build (aliases: ab)
  active-users         List the active users since a date or for the past 2 months (aliases: au)
  builds               List builds data (aliases: bs)
  check-resource       Check a resource (aliases: cr)
  check-resource-type  Check a resource-type (aliases: crt)
  checklist            Print a Checkfile of the given pipeline (aliases: cl)
  clear-task-cache     Clears cache from a task container (aliases: ctc)
  completion           generate shell completion code
  containers           Print the active containers (aliases: cs)
  curl                 curl the api (aliases: c)
  delete-target        Delete target (aliases: dtg)
  destroy-pipeline     Destroy a pipeline (aliases: dp)
  destroy-team         Destroy a team and delete all of its data (aliases: dt)
  edit-target          Edit a target (aliases: etg)
  execute              Execute a one-off build using local bits (aliases: e)
  expose-pipeline      Make a pipeline publicly viewable (aliases: ep)
  format-pipeline      Format a pipeline config (aliases: fp)
  get-pipeline         Get a pipeline's current configuration (aliases: gp)
  get-team             Show team configuration (aliases: gt)
  help                 Print this help message
  hide-pipeline        Hide a pipeline from the public (aliases: hp)
  hijack               Execute a command in a container (aliases: intercept, i)
  jobs                 List the jobs in the pipelines (aliases: js)
  land-worker          Land a worker (aliases: lw)
  login                Authenticate with the target (aliases: l)
  logout               Release authentication with the target (aliases: o)
  order-pipelines      Orders pipelines (aliases: op)
  pause-job            Pause a job (aliases: pj)
  pause-pipeline       Pause a pipeline (aliases: pp)
  pin-resource         Pin a version to a resource (aliases: pr)
  pipelines            List the configured pipelines (aliases: ps)
  prune-worker         Prune a stalled, landing, landed, or retiring worker (aliases: pw)
  rename-pipeline      Rename a pipeline (aliases: rp)
  rename-team          Rename a team (aliases: rt)
  resource-versions    List the versions of a resource (aliases: rvs)
  resources            List the resources in the pipeline (aliases: rs)
  set-pipeline         Create or update a pipeline's configuration (aliases: sp)
  set-team             Create or modify a team to have the given credentials (aliases: st)
  status               Login status
  sync                 Download and replace the current fly from the target (aliases: s)
  targets              List saved targets (aliases: ts)
  teams                List the configured teams (aliases: t)
  trigger-job          Start a job in a pipeline (aliases: tj)
  unpause-job          Unpause a job (aliases: uj)
  unpause-pipeline     Un-pause a pipeline (aliases: up)
  unpin-resource       Unpin a resource (aliases: ur)
  userinfo             User information
  validate-pipeline    Validate a pipeline config (aliases: vp)
  volumes              List the active volumes (aliases: vs)
  watch                Stream a build's output (aliases: w)
  workers              List the registered workers (aliases: ws)
  ```

- Now please execute the following command to understand where your access token is being stored:

```
cat ~/.flyrc
```

- You should see results similar to the example shown below:

```
targets:
  workshop:
    api: http://user1.pks4u.com:8080
    team: main
    token:
      type: Bearer
      value: eyJhbGciOiJSUzI1NiIsImtpZCI6IiIsInR5cCI6IkpXVCJ9.eyJjc3JmIjoiZTVmZTU2NTI4MjQ3MTk3NzcwOGJiMzk3MzgzN2M3Y2NhNTBmNmY5OGNhNTc0MzczNzk1MTM5ZGE1MzkwOGY5ZSIsImVtYWlsIjoiYWRtaW4iLCJleHAiOjE1OTY3Mzk5ODIsImlzX2FkbWluIjp0cnVlLCJuYW1lIjoiIiwic3ViIjoiQ2dWaFpHMXBiaElGYkc5allXdyIsInRlYW1zIjp7Im1haW4iOlsib3duZXIiXX0sInVzZXJfaWQiOiJhZG1pbiIsInVzZXJfbmFtZSI6ImFkbWluIn0.YjqncbHSaJkm-TjVpvLDyHSRcztSD3zBQZjzLpFXQPA6jtnG_lFEiM1J_l9FKFCWXr9geaEbBR3DCf2fBSMqouI2-uA_EhOaODxU1Ta6VuDUTwWOvj5BXg4tiQ5D7xW2u90nx9T84IqEGp_Oeq1B9J5pTd7ugG06nEwydMe-mT_i9aEJIYtmmRKECO1v-9_8DcqgfSLU6mH0kyyP_HUFSAOXwqlLVAcb8M4lqaPOqeJTCUahhw8C4YZDCWsCs3aM1hVNIuYMfojO7JuHod1cSdROeMAWzS2FTn4HNZNCe_Xh8FWXy9HLFRymYwHjUYI0CMiBH3Qmmn_XmQ6lITll-A
```

- Now let's create a `lab01.yml` file that will define you very 1st Concourse [Task](https://concourse-ci.org/tasks.html). Please execute the following command:

```
cat << EOF > lab01.yml
platform: linux
image_resource:
  type: docker-image
  source: {repository: ubuntu}
run:
  path: echo
  args: ["Hello, $user's first pipeline!"]
EOF
```

- Let's check the contents of `lab01.yml`. Please execute the following command:

```
cat lab01.yml
```

- Now let's execute your very 1st Concourse task. We're not calling it your very 1st Concourse Pipeline because it's literally a simple task. Please execute the following command:

```
fly -t workshop execute -c lab01.yml
```

- You should see results similar to the example shown below, or a shorter version of it:

```
uploading concourse done
executing build 1 at http://user1.pks4u.com:8080/builds/1 
initializing
waiting for docker to come up...
Pulling ubuntu@sha256:60f560e52264ed1cb7829a0d59b1ee7740d7580e0eb293aca2d722136edb1e24...
sha256:60f560e52264ed1cb7829a0d59b1ee7740d7580e0eb293aca2d722136edb1e24: Pulling from library/ubuntu
3ff22d22a855: Pulling fs layer
e7cb79d19722: Pulling fs layer
323d0d660b6a: Pulling fs layer
b7f616834fd0: Pulling fs layer
b7f616834fd0: Waiting
e7cb79d19722: Verifying Checksum
e7cb79d19722: Download complete
323d0d660b6a: Verifying Checksum
323d0d660b6a: Download complete
b7f616834fd0: Verifying Checksum
b7f616834fd0: Download complete
3ff22d22a855: Download complete
3ff22d22a855: Pull complete
e7cb79d19722: Pull complete
323d0d660b6a: Pull complete
b7f616834fd0: Pull complete
Digest: sha256:60f560e52264ed1cb7829a0d59b1ee7740d7580e0eb293aca2d722136edb1e24
Status: Downloaded newer image for ubuntu@sha256:60f560e52264ed1cb7829a0d59b1ee7740d7580e0eb293aca2d722136edb1e24

Successfully pulled ubuntu@sha256:60f560e52264ed1cb7829a0d59b1ee7740d7580e0eb293aca2d722136edb1e24.

running echo Hello, user1's first pipeline!
Hello, user1's first pipeline!
succeeded
```

- So what did `fly -t workshop execute -c lab01.yml` actually do?
   - downloaded an Ubuntu docker image resource 
   - spun-up a container with the Ubuntu docker image
   - used the Ubuntu container to execute an `echo` command where the arguments for the `echo` command where the phrase that was shown in the output logs   
   
- And if you execute the same command again, what will you see? Let's give it a try:

```
fly -t workshop execute -c lab01.yml
```

- The results should look something like this:

```
uploading concourse done
executing build 2 at http://user1.pks4u.com:8080/builds/2 
initializing
running echo Hello, user1's first pipeline!
Hello, user1's first pipeline!
succeeded
```

- Note:
    - The pulling of the Ubuntu docker image was not repeated. The image was already cached locally on the Concourse Server.
    - The execution time was faster
    - Concourse is keeping track of the build number
    - You obtained the exact same results: i.e. the echo of the `Hello` phrase.

- Go back to your Concourse Web GUI and refresh the screen. You should see nothing new. No pipelines have been created just yet.
    

**Let's recap:** 
- You ssh'ed into your Workshop VM and verified the versions of certain installed CLIs (Command Line Interface) such as the cf CLI.
- You installed Concourse on your Workshop VM using docker-compose
- You used the **fly** CLI
- You create one of the simplest Concourse tasks possible.
- You haven't yet created your first pipeline.

- Congratulations, you have completed LAB-1.

Please update the [Workshop Google Sheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing) with an "X" in the appropriate column.


-----------------------------------------------------
## LAB-2: Concourse Jobs, Tasks and Pipelines

![](./images/lab.png)

- Let's create `lab02.yml` using the following command. In this step we are creating a job within a pipeline, rather than running a one-off task:

```
cat << ABC > lab02.yml
jobs:
- name: hello
  plan:
  - task: howdy
    config:
      platform: linux
      image_resource:
        type: docker-image
        source: {repository: ubuntu}
      run:
        path: echo
        args: ["Hello, this is $user's first pipeline!"]
ABC
```

- Let's check the contents of `lab02.yml`. Please execute the following command:

```
cat lab02.yml
```

- To deploy this pipeline to your Concourse server, please use the following fly command. This is called _setting the pipeline_. Please note that every workshop participant has his/her own Concourse server, so we don't need to worry about creating unique pipeline names. There's no risk of pipeline name collision. When you execute the following command you will be asked `apply configuration? [yN]:`, please answer `Y`.

```
fly -t workshop set-pipeline -p pipeline-lab02 -c lab02.yml
```

- You should see results that look something like the example shown below:

```
jobs:
  job hello has been added:
+ name: hello
+ plan:
+ - config:
+     container_limits: {}
+     image_resource:
+       source:
+         repository: ubuntu
+       type: docker-image
+     platform: linux
+     run:
+       args:
+       - Hello, this is user1's first pipeline!
+       path: echo
+   task: howdy
  
apply configuration? [yN]: y
pipeline created!
you can view your pipeline here: http://user1.pks4u.com:8080/teams/main/pipelines/pipeline-lab02

the pipeline is currently paused. to unpause, either:
  - run the unpause-pipeline command:
    fly -t workshop unpause-pipeline -p pipeline-lab02
  - click play next to the pipeline in the web ui
```

- Let's unpause and trigger the execution of the pipeline using your Workshop VM and the **fly** CLI. Please execute the following commands:

```
fly -t workshop unpause-pipeline -p pipeline-lab02
fly -t workshop trigger-job -j pipeline-lab02/hello
watch -n 1 fly -t workshop builds
```

- Once you see that your job `pipeline-lab02/hello` has a status of `succeeded`, you can use `CTRL-C` to exit the `watch` command.

- To see the output from the job we just ran, please execute the following command:

```
fly -t workshop watch -j pipeline-lab02/hello
```

- You should see the following output:
```
initializing
running echo Hello, this is user1's first pipeline!
Hello, this is user1's first pipeline!
succeeded
```

- Let's do it all over again, but this time using the Concourse Web GUI. Please execute the following command on your Workshop VM to destroy the existing `pipeline-lab02`:

```
fly -t workshop destroy-pipeline -p pipeline-lab02 -n
```

- Note that the `-n` supresses the `are you sure? [yN]:` question.

- Open your Concourse Web GUI which, you may recall, is at `http://userID.pks4u.com:8080` and, if needed, login as `admin` with password `admin`. You should see the following page:

![](./images/ci-1.png)

- Using your Workshop VM, please execute the following command:

```
fly -t workshop set-pipeline -p pipeline-lab02 -c lab02.yml -n
```

- Now take a look at your Concourse Web GUI and you should see the following:

![](./images/ci-2b.png)

- Click on the `play` button, as shown above, and you should see the following:

![](./images/ci-3.png)

- Click on the `hello` job tile, as shown above, and you should see the following:

![](./images/ci-4.png)

- Click on the `plus` button, as shown above, to trigger a build of the `hello` job. 

- The 48-seconds animation below exemplifies all the steps described until now, as well as what happens after you click on the `plus` button:

![](./images/ci-5.gif)

- Using the Concourse Web GUI, please click on the `+` button again to see the `hello` job be re-executed.

- Now execute the following commands using your Workshop VM to see the builds:

```
fly -t workshop builds
```
- You should see an output similar to the one shown below:

```
id  pipeline/job          build  status     start                     end                       duration  team
5   pipeline-lab02/hello  2      succeeded  2020-08-06@01:06:29+0000  2020-08-06@01:06:43+0000  14s       main
4   pipeline-lab02/hello  1      succeeded  2020-08-06@01:05:49+0000  2020-08-06@01:06:02+0000  13s       main
2   one-off               n/a    succeeded  2020-08-06@01:02:02+0000  2020-08-06@01:02:06+0000  4s        main
1   one-off               n/a    succeeded  2020-08-06@01:01:35+0000  2020-08-06@01:01:56+0000  21s       main
```

- Note that the sequence of `id` numbers skips the number `3` because we executed a `fly -t workshop destroy-pipeline -p pipeline-lab02 -n` command a few steps ago.

- You can view specific `STDOUT` for any `job` and specific `build number` using the `-b` option, as shown below:

```
fly -t workshop watch -j pipeline-lab02/hello -t -b 1
fly -t workshop watch -j pipeline-lab02/hello -t -b 2
```

**Let's recap:** 
- You used the **fly** CLI to set the pipeline using the `lab02.yml` file.
- The `lab02.yml` file contained a `job` and a `task`.
- You `unpaused` the pipeline and triggered the `hello` job using the **fly** CLI and using the Concourse Web GUI.
- You saw the output from the `job` using the **fly** CLI and using the Concourse Web GUI.
- You saw the 1st and 2nd builds from the Concourse Web GUI and the **fly** CLI perspectives.

- Congratulations, you have completed LAB-2.

Please update the [Workshop Google Sheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing) with an "X" in the appropriate column.


-----------------------------------------------------
## LAB-3: Concourse Resources, Jobs, Tasks and Pipelines

![](./images/lab.png)

- Let's create `lab03.yml` using the following commands:

```
cat << XYZ > lab03.yml
resources:
- name: git-assets
  type: git
  source:
    branch: master
    uri: https://github.com/rm511130/Concourse-Workshop

jobs:
- name: hello
  plan:
  - get: git-assets
    trigger: true
  - task: howdy
    config:
      platform: linux
      image_resource:
        type: docker-image
        source: {repository: ubuntu}
      run:
        path: echo
        args: ["Hello, $user's first pipeline!"]
XYZ
```

- Let's check the contents of `lab03.yml`. Please execute the following command:

```
cat lab03.yml
```

- Now let's update the pipeline we used in Lab #2 instead of creating a new pipeline. Please execute the following command:

```
fly -t workshop set-pipeline -p pipeline-lab02 -c lab03.yml -n
```

- Look at the output from the command above. It highlights and color codes the changes made to the pipeline:

![](./images/pipeline-changes.png)

- Let's take a look at the Concourse Web GUI. You should see the following:

![](./images/ci-lab03.png)

- Note that your pipeline has now changed to include the `git-assets` resource, which is an input to your pipeline. 

- Your pipeline will now trigger automatically anytime the git repository changes. This is because we marked the `get task` in the pipeline to be triggered. 

- Ask the Workshop Organizer to commit a change to the git repo. When you click on the `hello` job you should now see the output of both a `git clone` and execution of the task that outputs a simple message to `STDOUT`.

![](./images/triggered.png)

- During the triggered execution of the pipeline, you may also have seen that the main screen of your Concourse Web GUI was changing to show the active job:

![](./images/ci-running.png)

- Please click on the `git-assets` you will see the changes made to the git repo:

![](./images/ci-git-repo-changes.png)



**Let's recap:** 
- You have now experimented with git triggered pipelines.
- You've also seen that the **fly** CLI provides you a report of the changes made to a pipeline.
- You've also seen how easy it is to find out what exact change triggered the pipeline.

- Congratulations, you have completed LAB-3.

Please update the [Workshop Google Sheet](https://docs.google.com/spreadsheets/d/16qIXY-L5ZA9phX4IUgRiXeT2Gjhj5MrpORAI8jPiSAA/edit?usp=sharing) with an "X" in the appropriate column.


-----------------------------------------------------
## LAB-4: Modularize Tasks and Link Multiple Jobs 

![](./images/lab.png)

- It is very common within an application's git repository to place all concourse artifacts in a _ci_ folder.  Within that folder individual tasks are modularized. Each task has its own `yml` file and refers to shell-scripts for actual task execution.

```
App Git Repo Root:
├── App source code....
│   ├── Some code artifacts...
├── ci
│   ├── pipeline.yml
│   ├── credentials.yml
│   ├── tasks
│   │   ├── modular-task.yml
│   │   ├── modular-task.sh
```

- We will mimic that structure as we build out our pipeline. Please create the `ci` and `ci/tasks` directory structure using the following commands:

```
mkdir -p ~/concourse/ci/tasks
```

- Let's create modularized tasks for the steps to build our application. First create the `yml` task file `mvn-test.yml` under the `ci/tasks` directory using the following command:

```
cat << ZZZ > ~/concourse/ci/tasks/mvn-test.yml
---
platform: linux

image_resource:
  type: docker-image
  source:
    repository: jamesdbloom/docker-java8-maven
    tag: "latest"

inputs:
- name: git-assets

run:
  path: git-assets/ci/tasks/test.sh
ZZZ
```

- Note that this task references to script `test.sh` for the actual execution logic. Let's create that file using the following commands:

```
cat << EOF > ~/concourse/ci/tasks/test.sh
#!/bin/bash

set -xe

cd git-assets
mvn test
EOF
```

- Create similar artifacts for the packaging stage of your application build by executing the following command:

```
cat << EOF > ~/concourse/ci/tasks/mvn-package.yml
---
platform: linux

image_resource:
  type: docker-image
  source:
    repository: jamesdbloom/docker-java8-maven
    tag: "latest"

inputs:
- name: git-assets

outputs:
- name: app-output

run:
  path: git-assets/ci/tasks/package.sh
EOF
```

- And execute the following command to create `package.sh`:

```
cat << EOF > ~/concourse/ci/tasks/package.sh
#!/bin/bash

set -xe

cd git-assets
mvn package
cp target/concourse-demo-*.jar ../app-output/concourse-demo.jar
EOF
```

- Let's make sure the shell-scripts are all executable by executing the following command:

```
chmod +x ~/concourse/ci/tasks/*.sh
```

- Now let's modify what was `lab03.yml` into your main `pipeline.yml`. It will reside in the the `ci directory` and include the `2` new tasks. These tasks will represent completely new jobs in your pipeline. These will test and package the java code included in your repository.  You will be replacing your `howdy` job. Your final `pipeline.yml` file can be created using the following command:

```
cat << EOF > ~/concourse/ci/pipeline.yml
resources:
- name: git-assets
  type: git
  source:
    branch: master
    uri: https://github.com/rm511130/Concourse-Workshop

jobs:
- name: unit-test
  public: true
  plan:
  - get: git-assets
    trigger: true
  - task: mvn-test
    file: git-assets/ci/tasks/mvn-test.yml
- name: deploy
  public: true
  plan:
  - get: git-assets
    trigger: true
    passed:
      - unit-test
  - task: mvn-package
    file: git-assets/ci/tasks/mvn-package.yml
EOF
```

- Now add your new concourse pipeline with the following set-pipeline command:

```
fly -t workshop set-pipeline -p pipeline-lab04 -c ~/concourse/ci/pipeline.yml
```

- Looking at the Concourse Web GUI, you should see that your pipeline now has steps (or jobs).  
      1) Unit test your code and 
      2) Package/Deploy your code.  
         Step #2 will only kickoff if Step #1 is successful

- Our last step would normally be to check all our new pipeline code into git. This should be everything in the `ci` folder. 
- Once we commit our build is automatically triggered. 
- The commands to check all our new pipeline code into git are as follows, but we don't need to execute them during this Lab because the correct changes and files are already in place:

```
$ git add ci/pipeline.yml ci/tasks
$ git commit -m "added concourse task assets"
$ git push
```














## Where to go from Here??

- link:https://github.com/azwickey-pivotal/volume-demo[Create a pipeline that uses Semantic Versioning (SemVer) and checks pipeline outputs into git as a git release]
- link:https://github.com/azwickey-pivotal/volume-demo[Cloudfoundry Blue/Green deployment]
- link:https://github.com/azwickey-pivotal/concourse-deploy-gemfire[Create a pipeline that uses BOSH to deploy software]


- You can check how Concourse compares with other CI tools here: http://concourse.ci/concourse-vs.html
