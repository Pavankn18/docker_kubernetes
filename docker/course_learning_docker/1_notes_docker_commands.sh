#### Docker commands
docker ps -a
docker images
docker run image_tag/image_id
	docker run -it ubuntu:latest bash # -it = interractive terminal
	docker run --rm --it ubuntu sleep 5 # --rm will remove the container after container exit
	docker run --name test_name -d ubuntu bash -c "ls ; sleep 5" #--name assign name test_name to container created
	# two containers cannot have same name.
	docker run -it -e secret=mysecret ubuntu bash # -e adds environmen variables
docker ps --format $FORMAT

# file system changes wont persist across running containers
docker ps -l # inspect status/exit codes etc for last container

docker commit <container_id># Saves containers current fs state as image
#Above command will split docker image id. Container need not be running, last run container_ids can also be used

docker tag <image_id> <tag_name> # Assign id to image
docker commit <container_name> <tag_name>
	docker commit my_container sample_container:v1.2

# docker container stays for the duration of main process.

docker run -d -ti ubuntu bash 
#  -d will detach container from terminal, docker continues to run in background
# contrl+ p, control+q - will detach current container created by running docker command

docker exec -ti <container_id/name>  <command>

docker attach <container_id/name> # attaches terminal to running docker container.

docker logs <container_id/name> # get logs of container - container need not be running

docker kill <container> # Kills the container by force
docker stop <container> # Issues stop signal allowing 10sec delay before falling back to docker kill
docker rm <container> # remove stopped container

docker run --memory <max-memory> --cpu-shares <cpu-share> image-name command
#Limits cpu and memory
docker run --cpu-quota <max_cpu_percent> image command
#Sets max limit on cpu usage, like 10%

# Lessons from instructors experience
# Dont fetch dependencies when container starts
# Dont leave important work in unnamed container.


#### port mapping and networking
nc -lp 45678 | nc -lp 54679 ## listen to 45678 and redirect that traffic to 45679
nc localhost 45678 # this opens a port and data can be recieved or sent by typeing int he terminal

docker run --rm -it -p 45678:45678 -p 45679:45679 ubuntu bash # -p <docker_port>:<host_port>
# In mac host.docker.internal points to host machine for the container, for windows it might work
# On windows one can also use host ip or dns to refer to host for the docker.
# e.g. nc host.docker.internal 45678

docker run -p 45678 -p45679 --name echo-server ubuntu bash 
# -p <docker_port> allows docker to choose available port on server
docker port <container> # displays port mapping: docker_port/protocol -> host:port
	docker port echo-server # 45678/tcp -> 0.0.0.0:32777

#docker works with both tcp and udp; use nc -ulp <port>  to listen on port over udp protocol

docker network ls # display existing networks
docker network create learning # create network learning

docker run -it --net learning --name catserver ubuntu bash #catserver is on learning netowrk
# names are important when working with networks, as this allows server to referenced by name as dns.
ping catserver # this will ping catserver if run from docker containers in learning network
docker network connect catsonlynetowrk catserver # connect catserver to catsonlynetwok network

#Legacy linking has below fetures
# If B links to A, A cannot link to B, B will have access to env variables on B
# Appropriate startup order is required.
# Restart sometime breaks links

docker run --rm -it --link catserver --name dogserver ubuntu bash 
# create dogserver is linked to cat server


##Images
docker image # list images
docker pull # pull an image - this will pull the image from regestry
docker rmi <image> #remove image with name/id <image>


##Volumes
# there are two types - 1) persistent 2) Ephimeral
docker run -it -v /path/on/host:/path/on/docker/container ubuntu bash 
#attach /path/on/host to /path/on/docker/container
#Above syntax can be used to share a file too, just makes sure file exist when running the command
#  Else docker will asume the path to be a folder

docker run -it -v /bookmarked/data --name s1 ubuntu bash
#Bookmarkd /bookmarked/data inside the container, this will get overridden by -v hostpath:dockerpath
docker run -it --volumes-from s1 ubuntu bash
# this will import bookmarked volumes from container s1

##Registery
docker search ubuntu # this will search ubuntu on regestry.
docker login # Login to conneted reges	-Qtry - default is hub.docker.command
docker push <image>

# Good practice
# Clean up your images regularly - to make sure image is available on regestry
# verify trust







#### Building custom docker images
docker build -t <image_tag_for_buily_image> . # use Dockerfile and rsources from current folder

# Exmple syntax:
FROM alpine:latest as tmp
MAINTAINER firstName lastName <email@s.com>
ADD run.sh /run.sh # copies file run.sh from local to /run.sh
ADD proj.tar.gz /install/  #extracts proj.tar.gz to /install/
RUN ls -l | wc -l > /filecount.txt #runs the give command in container

FROM alpine #this will create new base image instead one from last step
COPY --from=tmp /filecount.txt /files.txt #copies /filecount.txt from tmp to /files.txt on current container
ADD https://x.com/file /project/ # downloads file from the url to /project/
ENV db_host=db.prod.com # sets db_host for remainder of steps and in running container
EXPOSE 8080 # exposes port 8080
VOLUME ["/host/path", "/container/path/"] #mountes /host/path on host to container at /container/path
#Avoid using shared folders/files
VOLUME ["/shared-data"] # Creates ephimeral volume/bookmark
WORKDIR /opt # this will change pwd to /opt for rest of the steps and on final container.
USER arthur # runs rest of the commands as user arthur
ENTRYPOINT ["ls"] # arguments during docker run will be added to the command in ENTRYPOINT
CMD ["ls", "-l"] # what is mostly used, if there are arguments, command get replaced

# CMD and ENTRYPOINT has two forms from used above is called exec form
# shell form will give full shell command, e.g., CMD nano notes.txt
# exec form is slightly efficient since it directly invokes the program not surrounded by shell




####Docker uses 
# cgourps to contain process, namespaces to container network and copy-on-write fs to build images
# all above were used for long time, now docker makes it easier.
# client and server need not run on the same server.

#Layers of network Ethernet -> IP layer -> routing -> ports

#Docker uses bridges to create virtual network - |||ler to switches -> control ethernet layer
# apt instal bridge-utiles; bridge show; #shows bridges - each network on docker has a bridge
docker run it --net=host alpine bash # --net=host turns off network protection for host.

#exposing the ports creats port forwarding as below
# ip-tables is used for firewall rules to create NAT
docker run -ti --rm --net=host --privileged=true ubuntu bash
# --privileged=true give docker container control over host
sudo iptables -n -L -t nat # to inspect port forwading i.e., routing for docker

#namespaces privides network isolations in linux - used for isolating containers networking

#Evry process in linux comes from process init
docker inspect --format '{{.State.Pid}}' hello #gives main process pid for container hello

#Unix storage -> Storage devices -> Logical storage devices -> fs
#FUSE filesystems programs can pretend to be filse 
#COWs -> copy-on-write: layers of files, on write creates copy of original with new content.
#It is possible to run out of layers, if host created docker has storage devies which allows
# more fs layers than where the container will run
#VFS, you can mount a device or other part of fs on a given path.
mount -o bind other-work work #binds other-work to work dir, content of work are not deleted
unmount work # removes other-work mount uncovering contents of preexisted work

docker save -o my-images.tar.gz dabian:sid busybox ubuntu:14.04 #Saves listed 3 images to .gz file
docker load -i my-images.tar.gz # loads images stored on files

