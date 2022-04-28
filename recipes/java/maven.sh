#!/usr/bin/env bash

maven() {
    if [[ ! -f ${DOWNLOAD}/maven-${MAVEN_VERSION}.tar.gz ]]; then
        download ${MAVEN_URL} maven-${MAVEN_VERSION}.tar.gz ${DOWNLOAD}
    fi
    check_sum ${MAVEN_SHA} ${DOWNLOAD}/maven-${MAVEN_VERSION}.tar.gz
    run mkdir --parents "$target"/opt/maven
    run tar -xzf ${DOWNLOAD}/maven-${MAVEN_VERSION}.tar.gz --strip-components=1 --directory "$target"/opt/maven
    
    # https://maven.apache.org/configure.html
    echo -e '\n### MAVEN ###' >> "$target"/root/.bashrc
    echo 'export MAVEN_HOME=/opt/maven' >> "$target"/root/.bashrc
    echo 'export PATH=$PATH:$MAVEN_HOME/bin:$PATH' >> "$target"/root/.bashrc
    echo 'export MAVEN_OPTS="-Xms256m -Xmx1024m"' >> "$target"/root/.bashrc
}