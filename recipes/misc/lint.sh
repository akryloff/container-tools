#!/usr/bin/env bash

lint() {
    if [[ ! -f ${DOWNLOAD}/kubeval-${KUBEVAL_VERSION}.tar.gz ]]; then
        download ${KUBEVAL_URL} kubeval-${KUBEVAL_VERSION}.tar.gz ${DOWNLOAD}
    fi
    run tar -xzf ${DOWNLOAD}/kubeval-${KUBEVAL_VERSION}.tar.gz --directory "$target"/usr/local/bin

    if [[ ! -f ${DOWNLOAD}/kubescore-${KUBESCRORE_VERSION}.tar.gz ]]; then
        download ${KUBEVAL_URL} kubescore-${KUBESCRORE_VERSION}.tar.gz ${DOWNLOAD}
    fi
    run tar -xzf ${DOWNLOAD}/kubescore-${KUBESCRORE_VERSION}.tar.gz --directory "$target"/usr/local/bin
}