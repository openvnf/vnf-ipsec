DOCS := $(wildcard docs/*.md)

all: create-toc create-doc-tocs create-up-tocs

create-up-tocs:
	#markdown-toc --bullets="*" -i UPDATING.md

create-toc:
	markdown-toc --bullets="*" -i README.md

create-doc-tocs: $(DOCS)
	$(foreach f,$^,markdown-toc --bullets="*" -i $(f);)

create-container-image:
	docker build -f Dockerfile -t vnf-ipsec:latest .

.PHONY: create-toc create-doc-tocs create-up-tocs

