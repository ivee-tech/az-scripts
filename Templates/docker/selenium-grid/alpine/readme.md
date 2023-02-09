### Build base image
Use the `SELENIUM_JAR_URL` env variable
``` PowerShell
$SELENIUM_JAR_URL="http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar"
$SELENIUM_JAR_URL="http://selenium-release.storage.googleapis.com/4.0/selenium-server-standalone-4.0.0-alpha-2.jar"

docker build -t local/alpine-selenium-base:latest --build-arg SELENIUM_JAR_URL=$SELENIUM_JAR_URL ./base 
```

### Build hub image
``` PowerShell
docker build -t local/alpine-selenium-hub:latest ./hub
```

### Build node base image
``` PowerShell
docker build -t local/alpine-selenium-node-base:latest ./node-base
```

### Build node chrome image
``` PowerShell
docker build -t local/alpine-selenium-node-chrome:latest ./node-chrome
```

### Build node firefox image
``` PowerShell
docker build -t local/alpine-selenium-node-firefox:latest ./node-firefox
```

### Run
``` PowerShell
# create docker grid
docker network create grid

# hub
docker run -d -p 4444:4444 --net grid --name selenium-hub local/alpine-selenium-hub

# chrome
docker run -d --net grid -e SELENIUM_HUB_URL=selenium-hub local/alpine-selenium-node-chrome

# firefox
docker run -d --net grid -e SELENIUM_HUB_URL=selenium-hub local/alpine-selenium-node-firefox

```