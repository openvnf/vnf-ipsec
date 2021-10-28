DOCS := $(wildcard docs/*.md)
IMG := vnf-ipsec:latest

all: create-toc create-doc-tocs create-up-tocs

create-up-tocs:
	#markdown-toc --bullets="*" -i UPDATING.md

create-toc:
	markdown-toc --bullets="*" -i README.md

create-doc-tocs: $(DOCS)
	$(foreach f,$^,markdown-toc --bullets="*" -i $(f);)

docker-build:
	docker buildx build -t ${IMG} .

.PHONY: create-toc create-doc-tocs create-up-tocs docker-build

