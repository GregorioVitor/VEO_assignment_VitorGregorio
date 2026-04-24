# VEO_assignment_VitorGregorio

## Prerequisites
The first step of this project was to establish a stable and isolated environment. I chose to use Docker for dependency management, ensuring that the pipeline runs consistently across different systems without library conflicts.

### Docker Installation
Install Docker:
~~~
sudo apt update
sudo apt install docker.io -y
~~~
To avoid using sudo for every command, add your user to the docker group:
~~~
sudo usermod -aG docker $USER
newgrp docker
~~~
In some environments, Docker may have trouble resolving external resources. To ensure smooth image downloads and database updates (like CheckV), configure the Docker daemon:
Edit or create the configuration file:
~~~
sudo nano /etc/docker/daemon.json
~~~
Add the following text:
~~~
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
~~~
## Build with 
* Nextflow - Workflow management.
* Docker - Containerization.
* Flye - De novo assembly.
* CheckV - Viral completeness assessment.


## Usage

~~~
nextflow run VEO_pipeline.nf --input input_file.gz --threads t --output output_folder
~~~
