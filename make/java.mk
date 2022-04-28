JAVA_RECIPES = $(RECIPES)/java

JDK_VERSION ?= 18
ifeq "$(JDK_VERSION)" "18"
	JDK_SHA=d52c868db194c8b474982c83480ab49a4e6f1025ebf4332042b0b5efc334abfe
	JDK_URL=https://download.oracle.com/java/${JDK_VERSION}/latest/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz
endif

MAVEN_VERSION ?= 3.8.5
ifeq "$(MAVEN_VERSION)" "3.8.5"
	MAVEN_SHA=88e30700f32a3f60e0d28d0f12a3525d29b7c20c72d130153df5b5d6d890c673
	MAVEN_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
endif

GRADLE_VERSION ?= 7.4.2
ifeq "$(GRADLE_VERSION)" "7.4.2"
	GRADLE_SHA=29e49b10984e585d8118b7d0bc452f944e386458df27371b49b4ac1dec4b7fda
	GRADLE_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
endif

GRAALVM_VERSION ?= 22.0.0.2
ifeq "$(GRAALVM_VERSION)" "22.0.0.2"
	GRAALVM_SHA=bc86083bb7e2778c7e4fe4f55d74790e42255b96f7806a7fefa51d06f3bc7103
	GRAALVM_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAALVM_VERSION}/graalvm-ce-java11-linux-amd64-${GRAALVM_VERSION}.tar.gz
endif