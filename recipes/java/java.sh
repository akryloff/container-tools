#!/usr/bin/env bash

java() {
    if [[ ! -f ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz ]]; then
        download ${JDK_URL} jdk-${JDK_VERSION}.tar.gz ${DOWNLOAD}
    fi
    info "Проверяем контрольную сумму"
    check_sum ${JDK_SHA} ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz
    run tar -xzf ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz --directory "$target"/opt
    run mv "$target"/opt/jdk-${JDK_VERSION} "$target"/opt/jdk

    info "Чтобы уменьшить размер Java Runtime, будут удалены опциональные файлы и директории"
    run find "$target"/opt/jdk/bin -type f ! -path "./*"/java-rmi.cgi -exec strip --strip-all {} \;
    run find "$target"/opt/jdk -name "*.so*" -exec strip --strip-all {} \;
    run find "$target"/opt/jdk -name jexec -exec strip --strip-all {} \;
    run find "$target"/opt/jdk -name "*.debuginfo" -exec rm --force {} \;
    run find "$target"/opt/jdk -name "*src*zip" -exec rm --force {} \;

    info "Удаляем исполняемые файлы"
    run rm --recursive --force "$target"/opt/jdk/bin/appletviewer
    run rm --recursive --force "$target"/opt/jdk/bin/extcheck
    run rm --recursive --force "$target"/opt/jdk/bin/idlj
    run rm --recursive --force "$target"/opt/jdk/bin/jarsigner
    run rm --recursive --force "$target"/opt/jdk/bin/javah
    run rm --recursive --force "$target"/opt/jdk/bin/javap
    run rm --recursive --force "$target"/opt/jdk/bin/jconsole
    run rm --recursive --force "$target"/opt/jdk/bin/jdmpview
    run rm --recursive --force "$target"/opt/jdk/bin/jdb
    run rm --recursive --force "$target"/opt/jdk/bin/jhat
    run rm --recursive --force "$target"/opt/jdk/bin/jjs
    run rm --recursive --force "$target"/opt/jdk/bin/jmap
    run rm --recursive --force "$target"/opt/jdk/bin/jrunscript
    run rm --recursive --force "$target"/opt/jdk/bin/jstack
    run rm --recursive --force "$target"/opt/jdk/bin/jstat
    run rm --recursive --force "$target"/opt/jdk/bin/jstatd
    run rm --recursive --force "$target"/opt/jdk/bin/native2ascii
    run rm --recursive --force "$target"/opt/jdk/bin/orbd
    run rm --recursive --force "$target"/opt/jdk/bin/policytool
    run rm --recursive --force "$target"/opt/jdk/bin/rmic
    run rm --recursive --force "$target"/opt/jdk/bin/tnameserv
    run rm --recursive --force "$target"/opt/jdk/bin/schemagen
    run rm --recursive --force "$target"/opt/jdk/bin/serialver
    run rm --recursive --force "$target"/opt/jdk/bin/servertool
    run rm --recursive --force "$target"/opt/jdk/bin/tnameserv
    run rm --recursive --force "$target"/opt/jdk/bin/traceformat
    run rm --recursive --force "$target"/opt/jdk/bin/wsgen
    run rm --recursive --force "$target"/opt/jdk/bin/wsimport
    run rm --recursive --force "$target"/opt/jdk/bin/xjc
    
    info "Удаляем модули java"
    run rm --recursive --force "$target"/opt/jdk/jmods/java.activation.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.corba.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.transaction.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.xml.ws.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.xml.ws.annotation.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.desktop.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.datatransfer.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/jdk.scripting.nashorn.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/jdk.scripting.nashorn.shell.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/jdk.jconsole.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.scripting.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.se.ee.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.se.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.sql.jmod
    run rm --recursive --force "$target"/opt/jdk/jmods/java.sql.rowset.jmod
    
    info "Удаляем lib файлы"
    run rm --recursive --force "$target"/opt/jdk/lib/jexec

    info "Записываем переменные окружения"
    # https://docs.oracle.com/cd/E19182-01/820-7851/inst_cli_jdk_javahome_t/
    echo -e '\n### JAVA ###' >> "$target"/root/.bashrc
    echo 'export JAVA_HOME=/opt/jdk' >> "$target"/root/.bashrc
    echo 'export CLASSPATH=.:$JAVA_HOME/lib/' >> "$target"/root/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}