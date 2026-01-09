# Cloud SQL Easy Setup for Development Purposes
This tool helps you link a billing account and spin up a Cloud SQL for PostgreSQL instance (with all other API & network dependencies) using your active Google Cloud credentials.

## Clone the Repo
   
It will open a new tab (make sure you are in the right email account), clone the repository, and enter the directory automatically.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/flazer99/easy-cloud-sql-setup.git&cloudshell_open_in_editor=README.md)


## Run
   
In the Cloud Shell Terminal at the bottom, type the following and hit Enter:

#### sh run.sh


## Access UI!

Once the script prints "Starting Server on Port 8080"...

Click the link that you see in the terminal **or**

Click the Web Preview button (looks like an eye 👁️) in the Cloud Shell toolbar.

Select "Preview on port 8080".


## Alternative manual commands for above steps:

1. Run commands in your Cloud Shell Terminal one by one:

```bash
git clone https://github.com/flazer99/easy-cloud-sql-setup.git

cd easy-cloud-sql-setup

sh run.sh
```

2. Access UI!


#### ⚠️⚠️⚠️ Requirements

**Permissions**: You must have Owner or Editor permissions on the Google Cloud Project you intend to deploy to.

**Project**: The project must be created before running this tool (the tool handles billing linking, but not project creation).
