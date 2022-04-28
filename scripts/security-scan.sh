#!/usr/bin/env bash

info "Сканируем образ с помощью trivy"
run trivy fs --no-progress --skip-update "$target" 2>&1 | tee ${dist}/security_scan.txt