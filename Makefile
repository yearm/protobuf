PLATFORM := $(patsubst mingw%,windows,$(shell uname -s | tr '[:upper:]' '[:lower:]'))

PROTOC := protoc$(if $(filter windows,$(PLATFORM)),.exe,)
PROTOC_GEN_GO := protoc-gen-go$(if $(filter windows,$(PLATFORM)),.exe,)
PROTOC_GEN_GO_GRPC := protoc-gen-go-grpc$(if $(filter windows,$(PLATFORM)),.exe,)
PROTOC_GO_INJECT_TAG := protoc-go-inject-tag$(if $(filter windows,$(PLATFORM)),.exe,)

PROTOC_VERSION := "3.4.0"
PROTOC_GEN_GO_VERSION := "1.36.6"
PROTOC_GEN_GO_GRPC_VERSION := "1.5.1"
PROTOC_GO_INJECT_TAG_VERSION := "1.4.0"

DOWNLOAD_URL := "https://raw.githubusercontent.com/yearm/protoc/refs/heads/main"

export PATH := $(shell pwd)/build/${PLATFORM}:${PATH}

.PHONY: init
init:
	@rm -rf build
	@mkdir -p build/${PLATFORM}

	@wget -nv ${DOWNLOAD_URL}/protoc/${PROTOC_VERSION}/${PLATFORM}/${PROTOC} -O build/${PLATFORM}/${PROTOC}
	@chmod +x build/${PLATFORM}/${PROTOC}

	@wget -nv ${DOWNLOAD_URL}/protoc-gen-go/${PROTOC_GEN_GO_VERSION}/${PLATFORM}/${PROTOC_GEN_GO} -O build/${PLATFORM}/${PROTOC_GEN_GO}
	@chmod +x build/${PLATFORM}/${PROTOC_GEN_GO}

	@wget -nv ${DOWNLOAD_URL}/protoc-gen-go-grpc/${PROTOC_GEN_GO_GRPC_VERSION}/${PLATFORM}/${PROTOC_GEN_GO_GRPC} -O build/${PLATFORM}/${PROTOC_GEN_GO_GRPC}
	@chmod +x build/${PLATFORM}/${PROTOC_GEN_GO_GRPC}

	@wget -nv ${DOWNLOAD_URL}/protoc-go-inject-tag/${PROTOC_GO_INJECT_TAG_VERSION}/${PLATFORM}/${PROTOC_GO_INJECT_TAG} -O build/${PLATFORM}/${PROTOC_GO_INJECT_TAG}
	@chmod +x build/${PLATFORM}/${PROTOC_GO_INJECT_TAG}

.PHONY: generate
generate:
	@if [ ! -f build/"${PLATFORM}"/"${PROTOC_GO_INJECT_TAG}" ]; then \
		$(MAKE) init; \
	fi

	@go install github.com/bufbuild/buf/cmd/buf@v1.54.0
	@buf generate
	@find gen -name '*.pb.go' -print0 | while IFS= read -r -d '' file; do \
		protoc-go-inject-tag -input="$${file}"; \
	done

.PHONY: local-generate
local-generate:
	@if [ ! -f build/"${PLATFORM}"/"${PROTOC}" ]; then \
		$(MAKE) init; \
	fi
	@if [ ! -f build/"${PLATFORM}"/"${PROTOC_GEN_GO}" ]; then \
		$(MAKE) init; \
	fi
	@if [ ! -f build/"${PLATFORM}"/"${PROTOC_GEN_GO_GRPC}" ]; then \
		$(MAKE) init; \
	fi
	@if [ ! -f build/"${PLATFORM}"/"${PROTOC_GO_INJECT_TAG}" ]; then \
		$(MAKE) init; \
	fi

	@mkdir -p gen
	@find proto -name '*.proto' -print0 | while IFS= read -r -d '' file; do \
		protoc \
			--proto_path=proto \
			--go_out=paths=source_relative:gen \
			--go-grpc_out=require_unimplemented_servers=false,paths=source_relative:gen \
			"$${file}"; \
	done
	@find gen -name '*.pb.go' -print0 | while IFS= read -r -d '' file; do \
		protoc-go-inject-tag -input="$${file}"; \
	done
