# What is Phalcon?

![phalcon](https://static.phalconphp.com/www/images/phalcon1.png)

Phalcon is an open source, full stack framework for PHP written as a C-extension, optimized for high performance.   
You don’t need to learn or use the C language, since the functionality is exposed as PHP classes ready for you to use.   
Phalcon also is loosely coupled, allowing you to use its objects as glue components based on the needs of your application.  
Phalcon is not only about performance, our goal is to make it robust, rich in features and easy to use!  

https://phalconphp.com/

# What is this image?
This image is which designed to launch Phalcon applications.
* Phalcon version: 3.0.0
* PHP: 7.0.11
* Apache: 2.4.20
* OS: CentOS-7.2.1511

# Run your app
Your Phalcon app has to be mounted in the container in the /var/www/html/public directory.  
Should you want to publish your app port to the host, you must use the -p argument.  
Here is an example of a docker run command:
```shell
docker run -d -p 80:80 -p 443:443 \
  -v {/path/to/your/app}:/var/www/html:rw \
  {image-name} --name {container-name}
```
You can also package your app, in order to do that, create a Dockerfile like it:   
```docker
FROM matsnow/php7-phalcon:latest
MAINTERNER <your@email.com>
```

# Create your app
You may create a new Phalcon app.   
You attach this container and execute follow command.
```shell
docker exec -it {container-name} /bin/bash
su www
cd /var/www/html
phalcon create-project {your-app-name}
```
