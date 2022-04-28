MISC_RECIPES = $(RECIPES)/misc

KUBEVAL_VERSION ?= 0.15.0
ifeq "$(KUBEVAL_VERSION)" "0.15.0"
	KUBEVAL_URL=https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz
endif

KUBESCRORE_VERSION ?= 1.14.0
ifeq "$(KUBESCRORE_VERSION)" "1.14.0"
	KUBEVAL_URL=https://github.com/zegl/kube-score/releases/download/v${KUBESCRORE_VERSION}/kube-score_${KUBESCRORE_VERSION}_linux_amd64.tar.gz
endif