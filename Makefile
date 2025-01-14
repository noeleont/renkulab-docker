# -*- coding: utf-8 -*-
#
# Copyright 2017-2019 - Swiss Data Science Center (SDSC)
# A partnership between École Polytechnique Fédérale de Lausanne (EPFL) and
# Eidgenössische Technische Hochschule Zürich (ETHZ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

extensions = \
	bioc \
	r \
	cuda-9.2 \
	cuda-10.0-tf \
	vnc \
	julia

DOCKER_PREFIX?=renku/renkulab
DOCKER_LABEL?=latest
GIT_MASTER_HEAD_SHA:=$(shell git rev-parse --short=7 --verify HEAD)

# for the empty version case:
RENKU_PIP_SPEC="renku"
ifdef RENKU_VERSION
	RENKU_PIP_SPEC="renku==$(RENKU_VERSION)"
	RENKU_TAG=-renku$(RENKU_VERSION)
endif

RVERSION?=4.0.4
BIOC_VERSION?=devel
R_TAG=-r$(RVERSION)
BIOC_TAG=$(BIOC_VERSION)
TENSORFLOW_VERSION?=2.2.0

.PHONY: all

all: $(extensions)

login:
	@echo "${DOCKER_PASSWORD}" | docker login -u="${DOCKER_USERNAME}" --password-stdin ${DOCKER_REGISTRY}

push:
	for ext in "" $(extensions) ; do \
		if test "$$ext" != "" ; then \
			ext=-$$ext; \
		fi; \
		docker push $(DOCKER_PREFIX)$$ext:$(DOCKER_LABEL) ; \
		docker push $(DOCKER_PREFIX)$$ext:$(GIT_MASTER_HEAD_SHA) ; \
	done

pull:
	for ext in "" $(extensions) ; do \
		if test "$$ext" != "" ; then \
			ext=-$$ext; \
		fi; \
		docker pull $(DOCKER_PREFIX)$$ext:$(DOCKER_LABEL) ; \
	done

r: py
	docker build docker/r \
		--build-arg RENKU_BASE=renku/renkulab-py:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG) \
		--build-arg RVERSION=$(RVERSION) \
		-t $(DOCKER_PREFIX)-r:$(DOCKER_LABEL)$(RENKU_TAG)$(R_TAG) && \
	docker tag $(DOCKER_PREFIX)-r:$(DOCKER_LABEL)$(RENKU_TAG)$(R_TAG) $(DOCKER_PREFIX)-r:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)$(R_TAG)

bioc: py
	docker build docker/bioc \
		--build-arg RENKU_BASE=renku/renkulab-py:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG) \
		--build-arg RELEASE=$(BIOC_VERSION) \
		-t $(DOCKER_PREFIX)-bioc:$(DOCKER_LABEL)$(RENKU_TAG)$(BIOC_TAG) && \
	docker tag $(DOCKER_PREFIX)-bioc:$(DOCKER_LABEL)$(RENKU_TAG)$(BIOC_TAG) $(DOCKER_PREFIX)-bioc:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)$(BIOC_TAG)


py:
	cd docker/$@ && \
	docker build \
		-t $(DOCKER_PREFIX)-$@:$(DOCKER_LABEL)$(RENKU_TAG) . && \
	docker tag $(DOCKER_PREFIX)-$@:$(DOCKER_LABEL)$(RENKU_TAG) $(DOCKER_PREFIX)-$@:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)

cuda: py
	docker build docker/cuda-tf \
		--build-arg RENKU_PIP_SPEC=$(RENKU_PIP_SPEC) \
		--build-arg RENKU_BASE=renku/renkulab-py:$(GIT_MASTER_HEAD_SHA) \
		--build-arg TENSORFLOW_VERSION=$(TENSORFLOW_VERSION) \
		-t $(DOCKER_PREFIX)-cuda-tf:$(DOCKER_LABEL) && \
	docker tag $(DOCKER_PREFIX)-cuda-tf:$(DOCKER_LABEL) $(DOCKER_PREFIX)-cuda-tf:$(GIT_MASTER_HEAD_SHA)
	
vnc: py
	docker build docker/vnc \
		--build-arg BASE_IMAGE=renku/renkulab-py:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG) \
		-t $(DOCKER_PREFIX)-vnc:$(DOCKER_LABEL)$(RENKU_TAG) && \
	docker tag $(DOCKER_PREFIX)-vnc:$(DOCKER_LABEL)$(RENKU_TAG) $(DOCKER_PREFIX)-vnc:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)

julia: py
	docker build docker/julia \
		--build-arg BASE_IMAGE=renku/renkulab-py:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG) \
		-t $(DOCKER_PREFIX)-julia:$(DOCKER_LABEL)$(RENKU_TAG) && \
	docker tag $(DOCKER_PREFIX)-julia:$(DOCKER_LABEL)$(RENKU_TAG) $(DOCKER_PREFIX)-julia:$(GIT_MASTER_HEAD_SHA)$(RENKU_TAG)
