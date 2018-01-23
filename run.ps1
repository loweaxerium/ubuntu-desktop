docker-machine env | InvokeExpression

docker run -d --privileged --shm-size 1g --name dev --hostname dev -p 3389:3389 -v /var/run/docker.sock:/var/run/docker.sock ubuntu-desktop

docker build -t ubuntu-desktop .
