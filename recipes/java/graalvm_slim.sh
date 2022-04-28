#!/usr/bin/env bash

graalvm_slim() {
    if [[ ! -f ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz ]]; then
        download ${GRAALVM_URL} graal-${GRAALVM_VERSION}.tar.gz ${DOWNLOAD}
    fi
    info "Проверяем контрольную сумму"
    check_sum ${GRAALVM_SHA} ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz
    run tar -xzf ${DOWNLOAD}/graal-${GRAALVM_VERSION}.tar.gz --directory "$target"/tmp

    # https://www.oracle.com/corporate/features/understanding-java-9-modules.html
    # https://docs.oracle.com/javase/9/tools/jlink.htm
    run "$target"/tmp/graalvm-ce-java11-${GRAALVM_VERSION}/bin/jlink \
                                                     --add-modules ALL-MODULE-PATH \
                                                     --strip-debug \
                                                     --no-man-pages \
                                                     --no-header-files \
                                                     --compress=2 \
                                                     --vm=server \
                                                     --output "$target"/opt/graal

    run rm --recursive --force "$target"/tmp/graalvm-ce-java11-${GRAALVM_VERSION}

    info "Записываем переменные окружения"
    echo -e '\n### GRAAL ###' >> "$target"/root/.bashrc
    echo 'export GRAALVM_HOME=/opt/graal' >> "$target"/root/.bashrc
    echo 'export JAVA_HOME=$GRAALVM_HOME' >> "$target"/root/.bashrc
    echo 'export PATH=$GRAALVM_HOME/bin:$PATH' >> "$target"/root/.bashrc
    cat "$target"/root/.bashrc
}