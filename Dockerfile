FROM java:8-jdk

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_UC https://updates.jenkins-ci.org
ENV COPY_REFERENCE_FILE_LOG /var/log/copy_reference_file.log

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

RUN sed -i 's/httpredir/ftp.us/' /etc/apt/sources.list
RUN apt-get update && apt-get install -y wget git curl zip && rm -rf /var/lib/apt/lists/*

# Jenkins is ran with user `jenkins`, uid = 1000
# If you bind mount a volume from host/vloume from a data container, 
# ensure you use same uid
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins

# Jenkins home directoy is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

#ENV JENKINS_VERSION 1.596.2
#ENV JENKINS_SHA 96ee85602a41d68c164fb54d4796be5d1d9cc5d0

# could use ADD but this one does not check Last-Modified header 
# see https://github.com/docker/docker/issues/8331
#RUN curl -fL http://mirrors.jenkins-ci.org/war-stable/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war \
#  && echo "$JENKINS_SHA /usr/share/jenkins/jenkins.war" | sha1sum -c -

ADD http://mirrors.jenkins-ci.org/war/latest/jenkins.war /usr/share/jenkins/jenkins.war
RUN touch $COPY_REFERENCE_FILE_LOG \
    && chown -R jenkins.jenkins \
        "$COPY_REFERENCE_FILE_LOG" \
        "$JENKINS_HOME" \
        /usr/share/jenkins/ref \
        /usr/share/jenkins/jenkins.war
#RUN chown -R jenkins "$JENKINS_HOME" /usr/share/jenkins/ref

USER jenkins

COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugin.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
