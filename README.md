![](./images/vmware-logo.png)

![](./images/concourse-title.png)

## Overview

This 2 hour hands-on session will provide developers and operators with hands on experience building delivery pipelines using Concourse. The session includes presentations and hands on labs.

## Content

### Presentation 
- Intro to Concourse: link:presentation/concourse.pptx[_Concourse Intro_]

### Labs
- link:labs/pre-reqs.adoc[_Setup Environment Pre-reqs_]
- link:labs/lab01.adoc[_World’s simplest Concourse Task_]
- link:labs/lab02.adoc[_1st Job on Concourse Server_]
- link:labs/lab03.adoc[_Introduce Git Resource_]
- link:labs/lab04.adoc[_Modularize Tasks and Link Multiple Jobs_]
- link:labs/lab05.adoc[_SSH into a Concourse task to debug on server_]
- link:labs/lab06.adoc[_Push app to CF_]

## Where to go from Here??
- link:https://github.com/azwickey-pivotal/volume-demo[Create a pipeline that uses Semantic Versioning (SemVer) and checks pipeline outputs into git as a git release]
- link:https://github.com/azwickey-pivotal/volume-demo[Cloudfoundry Blue/Green deployment]
- link:https://github.com/azwickey-pivotal/concourse-deploy-gemfire[Create a pipeline that uses BOSH to deploy software]

#

## Intro to Concourse

- Concourse is an Open Source Continuous Integration Tool. 
- It has a simple and yet very effective architecture:

   - Command-line interface called fly
   - A Server component that runs the web UI and the API called from the command-line. The Web UI is only used for displaying the state of the pipelines and for triggering pipelines manually. All other tasks are performed via the fly CLI.
   - Worker machines where pipelines run

Design Principles:

No snowflakes: there is no configuration of concourse server that we can apply on run-time, no gui, etc.
Usability in mind (with a single click you get what you need)
Isolated builds. There is no longer build pollution because everything runs in a container
Scalable. To add more capacity, we add more Worker machines.
No plugins but docker images. You bring your own docker image. You dont depend on pre-installed plugins.
We dont need to backup concourse. Instead we should find a way to simply redeploy our pipelines again.
Infrastructure agnostic (we can deploy it in AWS, vSphere, GCP, Azure, others)


You can check how Concourse compares with other CI tools here: http://concourse.ci/concourse-vs.html
