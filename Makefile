
# current date
DATE=$(shell qore -nX 'now().format("YYYY-MM-DD")')

# the building block release version
VERSION=1.0-$(DATE)

#top_srcdir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

BB_SUBDIRS=generic job service step

BB_FILES=$(shell find ${BB_SUBDIRS} -name \*.q\* | sort)

BB_JAVA=$(shell find ${BB_SUBDIRS} -name \*.jar -type f | sort)

TEST_FILES=$(shell find test -name \*.q\* | sort)

TESTS=$(shell find test -name \*.qtest | sort)

all:
	@echo "usage: make release|load-all|load-building-blocks|load-tests|test"
	@echo "  release:              make the building block release package"
	@echo "  load-all:             load all building blocks and test code"
	@echo "  load-building-blocks: load only building blocks (no tests)"
	@echo "  load-tests:           load only tests"
	@echo "  test:                 run tests"

dummy:

release: ${BB_FILES} ${BB_JAVA}
	make-release -U. -Puser/building-blocks building-blocks-$(VERSION) $^
load-all: load-building-blocks load-tests

load-building-blocks: ${BB_FILES}
	# copy jar files to the target dir
	for jar in ${BB_JAVA}; do \
		dir=`dirname "$$jar"`; \
		target_dir="$$OMQ_DIR/user/building-blocks/$$dir"; \
		if [ ! -d "$$target_dir" ]; then \
			echo creating "$$target_dir"; \
			mkdir -p "$$target_dir"; \
		fi; \
		cp "$$jar" "$$target_dir"; \
	done
	# make a temporary load file
	make-release -l/tmp/building-blocks.qrf -U. $^
	# load the release
	oload /tmp/building-blocks.qrf -lvR
	# delete the temporary load file
	rm /tmp/building-blocks.qrf

load-tests: ${TEST_FILES}
	# make a temporary load file
	make-release -l/tmp/building-blocks-tests.qrf -U. $^
	# load the release
	oload /tmp/building-blocks-tests.qrf -lvR
	# delete the temporary load file
	rm /tmp/building-blocks-tests.qrf

test: dummy
	for test in $(TESTS); do echo running $$test; qore $$test -vv; done
