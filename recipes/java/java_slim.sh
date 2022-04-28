#!/usr/bin/env bash

java_slim() {
    if [[ ! -f ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz ]]; then
        download ${JDK_URL} jdk-${JDK_VERSION}.tar.gz ${DOWNLOAD}
    fi
    check_sum ${JDK_SHA} ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz
    run tar -xzf ${DOWNLOAD}/jdk-${JDK_VERSION}.tar.gz --directory "$target"/tmp

    # https://www.oracle.com/corporate/features/understanding-java-9-modules.html
    # https://docs.oracle.com/javase/9/tools/jlink.htm
    run "$target"/tmp/jdk-${JDK_VERSION}/bin/jlink \
                                                     --add-modules ALL-MODULE-PATH \
                                                     --strip-java-debug-attributes \
                                                     --no-man-pages \
                                                     --no-header-files \
                                                     --compress=2 \
                                                     --vm=server \
                                                     --output "$target"/opt/jdk

    run rm --recursive --force "$target"/tmp/jdk-${JDK_VERSION}

    info "Записываем переменные окружения"
    # https://docs.oracle.com/cd/E19182-01/820-7851/inst_cli_jdk_javahome_t/
    echo -e '\n### JAVA ###' >> "$target"/root/.bashrc
    echo 'export JAVA_HOME=/opt/jdk' >> "$target"/root/.bashrc
    echo 'export CLASSPATH=.:$JAVA_HOME/lib/' >> "$target"/root/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}