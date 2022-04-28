TOOLS = util/bin
BOOTSTRAP = util/bootstrap-binary.sh
BOOTSTRAP-QEMU = util/gh-downloader.sh

INSTALL_PKG := scripts/install_pkg.sh

# Добавляем tools/bin в $PATH, чтобы избежать путаницы с бинарными файлами
export PATH := $(CWD)/tools/bin:$(PATH)

HOST_OS := $(shell uname --kernel-name | tr A-Z a-z)
HOST_ARCH = $(shell uname --machine)
ifeq (x86_64, $(HOST_ARCH))
	HOST_ARCH = amd64
endif

DEBIAN? := $(shell dpkg --version 2>/dev/null)
ifdef DEBIAN?
	install-docker:=install-docker-debian
	install-trivy:=install-trivy-debian
	prepare:=prepare-debian
else
	install-docker:=install-docker-redhat
	install-trivy:=install-trivy-redhat
	prepare:=prepare-redhat
endif

PODMAN? := $(shell podman --version 2>/dev/null)
ifdef DOCKER?
	DOCKER := podman
else
	DOCKER := docker
endif

##shellcheck: Выполнить проверку bash скриптов линтером
shellcheck:
	$(PRINT_HEADER)
	shellcheck --severity=error --enable=all --shell=bash $(shell find . -type f -name "*.sh")

typos:
	$(PRINT_HEADER)
	codespell --skip .git --ignore-words .codespellignore --check-filenames

fix-typos:
	$(PRINT_HEADER)
	codespell --skip .git --ignore-words .codespellignore --check-filenames --write-changes --interactive=1

##prepare: Установить все необходимые для работы конвейера зависимости
prepare: $(prepare) install-qemu-user-static
install-docker: $(install-docker)
install-trivy: $(install-trivy)

prepare-debian:install-docker install-trivy
	$(PRINT_HEADER)
	sudo apt-get install --yes debian-keyring debian-archive-keyring debootstrap jq unzip

prepare-redhat:install-podman install-trivy
	$(PRINT_HEADER)
	sudo yum install --assumeyes yum-utils

install-docker-redhat:
	$(PRINT_HEADER)
	sudo yum-config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
	sudo yum install --allowerasing --assumeyes docker-ce
	sudo systemctl enable docker
	sudo systemctl start docker

install-docker-debian:
	$(PRINT_HEADER)
	sudo apt-get install ca-certificates curl gnupg lsb-release
	sudo curl --silent --location https://download.docker.com/linux/debian/gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/docker-archive-keyring.gpg
	sudo echo "deb [arch=$(shell dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
	$(shell lsb_release --codename --short) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo sed --in-place 's/debian/ubuntu/g' /etc/apt/sources.list.d/docker.list
	sudo apt-get update
	sudo apt-get install --yes docker-ce docker-ce-cli containerd.io
	sudo systemctl enable docker
	sudo systemctl start docker

enable-docker-experimental:
	$(PRINT_HEADER)
	@sudo mkdir --parents $$HOME/.docker
	@echo '{ "experimental": "enabled" }' | tee $$HOME/.docker/config.json
	@echo '{ "experimental": true, "storage-driver": "overlay2", "max-concurrent-downloads": 10, "max-concurrent-uploads": 10 }' | tee /etc/docker/daemon.json 
	@sudo systemctl restart docker

install-podman-redhat:
	$(PRINT_HEADER)
	sudo yum install --allowerasing --assumeyes podman

install-trivy-redhat:
	$(PRINT_HEADER)
	sudo rpm --install --hash https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.rpm
	sudo trivy image --download-db-only

install-trivy-debian:
	$(PRINT_HEADER)
	curl --remote-name --location --silent --fail https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.deb
	sudo dpkg --install trivy_0.18.3_Linux-64bit.deb
	sudo unlink trivy_0.18.3_Linux-64bit.deb
	sudo trivy image --download-db-only

install-trivy-debian-arm64:
	$(PRINT_HEADER)
	curl --remote-name --location --silent --fail https://github.com/aquasecurity/trivy/releases/download/v0.27.1/trivy_0.27.1_Linux-ARM64.deb
	sudo dpkg --install trivy_0.27.1_Linux-ARM64.deb
	sudo unlink trivy_0.27.1_Linux-ARM64.deb
	sudo trivy image --download-db-only

install-fedora-box:
	sudo curl --remote-name --location --silent --fail https://app.vagrantup.com/generic/boxes/fedora33/versions/3.6.10/providers/virtualbox.box
	sudo vagrant box add --force fedora/fedora33 virtualbox.box
	sudo unlink virtualbox.box

bootstrap-qemu-user-static:
	$(PRINT_HEADER)
	$(DOCKER) run --rm --privileged multiarch/qemu-user-static:register --reset
	$(BOOTSTRAP-QEMU) --username=multiarch --project=qemu-user-static --version=latest --arch=x86_64_qemu-aarch64-static --output=/usr/bin

CRANE_VERSION=0.8.0

bootstrap-crane:
	$(PRINT_HEADER)
	go install github.com/google/go-containerregistry/cmd/crane@v$(CRANE_VERSION)
	unlink /usr/local/bin/crane && ln --symbolic $$GO_HOME/bin/crane /usr/local/bin/crane

COSIGN_VERSION=1.3.1
COSIGN_SHA256SUM=1227b270e5d7d21d09469253cce17b72a14f6b7c9036dfc09698c853b31e8fc8

bootstrap-cosign:
	$(PRINT_HEADER)
	$(BOOTSTRAP) https://github.com/sigstore/cosign/releases/download/v$(COSIGN_VERSION)/cosign-linux-amd64 cosign $(TOOLS) $(COSIGN_SHA256SUM)

cleanup:
	$(PRINT_HEADER)
	rm --verbose --recursive --force $(CWD)/debain/dist
	rm --verbose --recursive --force $(CWD)/fedora/dist
	rm --verbose --recursive --force $(CACHE)/*