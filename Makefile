
# current date
DATE=$(shell qore -nX 'now().format("YYYY-MM-DD")')

# the building block release version
VERSION=1.0-$(DATE)

#top_srcdir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

BB_SUBDIRS=generic job service step kafka mqtt-paho snmp
EX_SUBDIRS=examples

BB_FILES_NO_JAVA=$(shell find ${BB_SUBDIRS} -name \*.q* -o -name \*.yaml -o -name \*py | grep -v -i -e salesforce -e excel -e java -e snmp -e kafka -e mqtt | sort)

BB_FILES=$(shell find ${BB_SUBDIRS} -name \*.q* -o -name \*.yaml -o -name \*java -o -name \*py | sort)

BB_ONDEWO=$(shell ls ondewo/*.{yaml,py,qscript})
BB_ONDEWO_MODULE_DIRS=ondewo/OndewoNluClientConnection \
	ondewo/OndewoVtsiClientConnection

BB_JAVA=$(shell find ${BB_SUBDIRS} -name \*.jar -type f | sort)
BB_JAVA_STRIP=$(shell find ExcelDataProvider/building-blocks/excel/jar -name \*.jar -type f | sort)

#BB_MODULES=$(shell find modules -name \*.qm -type f | grep -v Excel | sort)
BB_MODULE_DIRS=ExcelDataProvider/qlib/ExcelDataProvider mqtt-paho/MqttPahoClientConnection

TEST_FILES=$(shell find test -name \*.q\* -o -name \*.yaml | sort)

TESTS=$(shell find test -name \*.qtest | sort)

EX_FILES=$(shell find ${EX_SUBDIRS} -name \*.q* -o -name \*.yaml -o -name \*java -o -name \*py -o -name \*html -o -name \*qjs -o -name \*css -o -name \*png | sort)
EX_OTHER_CHATBOT=examples/service/http/websockets/saved_model \
	examples/service/http/websockets/intents.json
EX_OTHER=${EX_OTHER_CHATBOT}

RELDIR := /tmp/release-$(shell qore -lUtil -nX 'get_random_string()')

OLOAD ?= oload
#MAKE_RELEASE=~/src/Qorus/git/qorus-docker/remote/python/make-release.py
MAKE_RELEASE ?= make-release

all:
	@echo "usage: make release|load-all|load-building-blocks|load-tests|test"
	@echo "  release:         make the building block release package"
	@echo "  rel-ex:          make the BB release package with examples"
	@echo "  rel-ondewo:      make an ONDEWO release package"
	@echo "  load-all:        load all building blocks, test code, and examples"
	@echo "  load-bb:         load only building blocks (no tests)"
	@echo "  load-bb-no-java: load only building blocks (no tests)"
	@echo "  load-tests:      load only tests"
	@echo "  load-bb-tests:   load building blocks and tests"
	@echo "  load-ondewo:     load ONDEWO building blocks"
	@echo "  load-examples:   load only examples (BBs must be already loaded)"
	@echo "  readme:          make README.md"
	@echo "  test:            run tests"

dummy:

readme:
	@bin/build-docs -v

docs: readme

release: ${BB_FILES} ${BB_JAVA} ${BB_MODULES} ${BB_MODULE_DIRS}
	@echo using release dir: ${RELDIR}
	mkdir -p ${RELDIR}/building-blocks ${RELDIR}/modules
	for f in ${BB_FILES} ${BB_JAVA}; do \
		dir=`dirname "$$f"`; \
		target_dir="${RELDIR}/building-blocks/$${dir}"; \
		if [ ! -d "$${target_dir}" ]; then \
			echo creating "$${target_dir}"; \
			mkdir -p "$${target_dir}"; \
		fi; \
		cp "$${f}" "$${target_dir}"; \
	done
	cp -apRxuv ${BB_MODULES} ${BB_MODULE_DIRS} ${RELDIR}/modules
	for jar in ${BB_JAVA_STRIP}; do \
		dir=`dirname "$$jar" | cut -f3- -d/`; \
		target_dir="${RELDIR}/building-blocks/$$dir"; \
		if [ ! -d "$${target_dir}" ]; then \
			echo creating "$${target_dir}"; \
			mkdir -p "$${target_dir}"; \
		fi; \
		cp "$$jar" "$${target_dir}"; \
	done
	cd ${RELDIR}; ${MAKE_RELEASE} -mcf -Puser building-blocks-$(VERSION) `find .`; cd -
	rm -rf ${RELDIR}

rel-ex: ${BB_FILES} ${BB_JAVA} ${BB_MODULES} ${BB_MODULE_DIRS} ${EX_FILES} ${EX_OTHER}
	@echo using release dir: ${RELDIR}
	@mkdir -p ${RELDIR}/building-blocks ${RELDIR}/modules
	@for f in ${BB_FILES} ${BB_JAVA} ${EX_FILES} ${EX_OTHER}; do \
		dir=`dirname "$$f"`; \
		target_dir="${RELDIR}/building-blocks/$${dir}"; \
		if [ ! -d "$${target_dir}" ]; then \
			echo creating "$${target_dir}"; \
			mkdir -p "$${target_dir}"; \
		fi; \
		cp -apR "$${f}" "$${target_dir}"; \
	done
	@cp -apRxuv ${BB_MODULES} ${BB_MODULE_DIRS} ${RELDIR}/modules
	@for jar in ${BB_JAVA_STRIP}; do \
		dir=`dirname "$$jar" | cut -f3- -d/`; \
		target_dir="${RELDIR}/building-blocks/$$dir"; \
		if [ ! -d "$${target_dir}" ]; then \
			echo creating "$${target_dir}"; \
			mkdir -p "$${target_dir}"; \
		fi; \
		cp "$$jar" "$${target_dir}"; \
	done
	@cd ${RELDIR}; ${MAKE_RELEASE} -mcf -Puser building-blocks-with-examples-$(VERSION) `find .`; cd -
	@rm -rf ${RELDIR}

load-all: load-building-blocks load-tests load-examples

load-bb-tests: load-building-blocks load-tests

load-bb: load-building-blocks

load-bb-no-java: load-building-blocks-no-java

load-building-blocks: ${BB_FILES} ${BB_JAVA} ${BB_JAVA_STRIP}
	# copy jar files to the target dir
	for jar in ${BB_JAVA}; do \
		dir=`dirname "$$jar"`; \
		target_dir="$${OMQ_DIR}/user/building-blocks/$$dir"; \
		if [ ! -d "$$target_dir" ]; then \
			echo creating "$$target_dir"; \
			mkdir -p "$$target_dir"; \
		fi; \
		cp "$$jar" "$$target_dir"; \
	done
	for jar in ${BB_JAVA_STRIP}; do \
		dir=`dirname "$$jar" | cut -f3- -d/`; \
		target_dir="$${OMQ_DIR}/user/building-blocks/$$dir"; \
		if [ ! -d "$$target_dir" ]; then \
			echo creating "$$target_dir"; \
			mkdir -p "$$target_dir"; \
		fi; \
		cp "$$jar" "$$target_dir"; \
	done
	# copy modules to ${OMQ_DIR}/user/modules
	mkdir -p ${OMQ_DIR}/user/modules
	for mod in ${BB_MODULES}; do \
		cp $$mod ${OMQ_DIR}/user/modules; \
	done
	for mod in $(BB_MODULE_DIRS); do \
	    cp -apR $$mod ${OMQ_DIR}/user/modules; \
	done
	# make a temporary load file
	${MAKE_RELEASE} -l/tmp/building-blocks.qrf -U. $^
	# load the release
	${OLOAD} /tmp/building-blocks.qrf -lvRA
	# delete the temporary load file
	rm /tmp/building-blocks.qrf

load-building-blocks-no-java: ${BB_FILES_NO_JAVA}
	# copy modules to ${OMQ_DIR}/user/modules
	mkdir -p ${OMQ_DIR}/user/modules
	for mod in ${BB_MODULES}; do \
		cp $$mod ${OMQ_DIR}/user/modules; \
	done
	for mod in $(BB_MODULE_DIRS); do \
	    cp -apR $$mod ${OMQ_DIR}/user/modules; \
	done
	# make a temporary load file
	${MAKE_RELEASE} -l/tmp/building-blocks.qrf -U. $^
	# load the release
	${OLOAD} /tmp/building-blocks.qrf -lvRA
	# delete the temporary load file
	rm /tmp/building-blocks.qrf

load-tests: ${TEST_FILES}
	# make a temporary load file
	${MAKE_RELEASE} -l/tmp/building-blocks-tests.qrf -U. $^
	# load the release
	${OLOAD} /tmp/building-blocks-tests.qrf -lvRA
	# delete the temporary load file
	rm /tmp/building-blocks-tests.qrf

load-examples: ${EX_FILES} ${EX_OTHER}
	# copy models and other info to ${OMQ_DIR}/user
	for f in ${EX_OTHER}; do \
		dir=`dirname "$$f"`; \
		mkdir -p $${OMQ_DIR}/user/building-blocks/$${dir}; \
		cp -apR $$f $${OMQ_DIR}/user/building-blocks/$${dir}; \
	done
	# make a temporary load file
	${MAKE_RELEASE} -l/tmp/building-blocks-examples.qrf -U. ${EX_FILES}
	# load the release
	${OLOAD} /tmp/building-blocks-examples.qrf -lvRA
	# delete the temporary load file
	rm /tmp/building-blocks-examples.qrf

rel-ondewo: ${BB_ONDEWO} ${BB_ONDEWO_MODULE_DIRS}
	@echo using release dir: ${RELDIR}
	@mkdir -p ${RELDIR}/building-blocks ${RELDIR}/modules
	@for f in ${BB_ONDEWO}; do \
		dir=`dirname "$$f"`; \
		target_dir="${RELDIR}/building-blocks/$${dir}"; \
		if [ ! -d "$${target_dir}" ]; then \
			echo creating "$${target_dir}"; \
			mkdir -p "$${target_dir}"; \
		fi; \
		cp -apR "$${f}" "$${target_dir}"; \
	done
	@cp -apRxuv ${BB_ONDEWO_MODULE_DIRS} ${RELDIR}/modules
	@cd ${RELDIR}; ${MAKE_RELEASE} -mcf -Puser building-blocks-ondewo-$(VERSION) `find .`; cd -
	@rm -rf ${RELDIR}

load-ondewo: ${BB_ONDEWO} ${BB_ONDEWO_MODULE_DIRS}
	for mod in $(BB_ONDEWO_MODULE_DIRS); do \
	    cp -apR $$mod ${OMQ_DIR}/user/modules; \
	done
	# make a temporary load file
	${MAKE_RELEASE} -l/tmp/ondewo-building-blocks.qrf -U. ${BB_ONDEWO}
	# load the release
	${OLOAD} /tmp/ondewo-building-blocks.qrf -lvRA
	# delete the temporary load file
	rm /tmp/ondewo-building-blocks.qrf

test: dummy
	for test in $(TESTS); do echo running $$test; qore $$test -vv; done
