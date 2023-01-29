
JAVA_SRC_DIR=java

JAVA_SRC_FILES = $(shell find ${JAVA_SRC_DIR} -type f -name '*.java')

EXCEL_JAR=building-blocks/excel/jar/qore-dataprovider-excel.jar

CLASSPATH=./building-blocks/excel/jar/poi-ooxml-full-5.0.0.jar:./building-blocks/excel/jar/poi-5.0.0.jar:./building-blocks/excel/jar/poi-ooxml-5.0.0.jar

all: jar

jar: $(EXCEL_JAR)

$(EXCEL_JAR): $(JAVA_SRC_FILES)
	qjava2jar $(EXCEL_JAR) $(JAVA_SRC_DIR) -cp $(CLASSPATH)
