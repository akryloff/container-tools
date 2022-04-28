.DEFAULT_GOAL := help

.ONESHELL:

.EXPORT_ALL_VARIABLES:

# По-умолчанию make выводит каждую линию рецепта перед выполнением
# Чтобы включить поведение по-умолчанию: VERBOSE=1 make <target>
ifndef VERBOSE
.SILENT:
endif

include make/phony.mk
include make/tools.mk
include make/java.mk
include make/misc.mk
include make/common.mk

#------------------------------------------------------------------------------

help:
	@echo
	@echo "Использование: make <target>"
	@echo
	@echo " * 'print-%' - print-{ПЕРЕМЕННАЯ} - выводит значение переменной во время выполнения программы"
	@echo
	@echo " * 'prepare' - Установить все необходимые для работы конвейера зависимости"
	@echo
	@echo " * 'shellcheck' - Выполнить проверку bash скриптов линтером"
	@echo " * 'typos' - Выполнить проверку на грамматические ошибки"
	@echo " * 'fix-typos' - Исправить грамматические ошибки"
	@echo
	@echo " * 'install-docker' - Установить docker-ce"
	@echo " * 'install-podman' - Установить podman"
	@echo " * 'install-trivy' - Установить trivy - инструмент для сканирования образов docker на уязвимости"
	@echo " * 'enable-docker-experimental' - Включить экспериментальные функции docker-ce"
	@echo " * 'install-qemu-user-static' - Зарегистрировать в системе binfmt_misc, скачать и установить qemu-user-static"
	@echo
	@echo " ============================"
	@echo "  ** Debian Linux targets ** "
	@echo " ============================"
	@echo
	@echo "|debian11|"
	@echo "|debian11-java|"
	@echo "|debian11-java-slim|"
	@echo "|debian11-graal|"
	@echo "|debian11-graal-slim|"
	@echo "|debian11-java-slim-maven|"
	@echo "|debian11-java-slim-gradle|"

#------------------------------------------------------------------------------

export SHELL := /bin/bash
export CWD := $(shell pwd)

export DOWNLOAD = .download

SRCDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILDDIR := .

PRINT_HEADER = @echo -e "\n********************[ $@ ]********************\n"

RECIPES = recipes
SCRIPTS = scripts

DEBIAN_DIR = debian
DEBIAN_BUILD_SCRIPT = $(DEBIAN_DIR)/mkimage.sh
DEBIAN_KEYS_DIRECTORY = $(DEBIAN_DIR)/keys
DEBIAN_KEYRING = $(DEBIAN_KEYS_DIRECTORY)/debian-archive-keyring.gpg

debian11:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-lint:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(MISC_RECIPES)/lint.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/maven.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			--scripts=$(SCRIPTS)/security-scan.sh