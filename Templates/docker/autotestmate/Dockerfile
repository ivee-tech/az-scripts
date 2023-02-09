FROM mcr.microsoft.com/dotnet/core/sdk:3.1

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        wget \
        unzip

# The storage account or github url containing the test zip file, e.g. https://stgacct1234.blob.core.windows.net/autotestmate/samples.zip
ARG TESTS_URL
RUN wget -N ${TESTS_URL}

# Test archive file name (without extension), e.g. samples
ARG TESTS_ARC_NAME
ENV ETESTS_ARC_NAME ${TESTS_ARC_NAME}
RUN unzip ${ETESTS_ARC_NAME}.zip

# The tests assembly name, e.g. AutoTestMate.Samples.Web.Tests.dll
ARG TESTS_BIN_NAME
ENV ETESTS_BIN_NAME ${TESTS_BIN_NAME}
# The runsettings file name (without extension, assumes the same folder)
ARG RUNSETTINGS_FILE_NAME=Test.runsettings
ENV ERUNSETTINGS_FILE_NAME ${RUNSETTINGS_FILE_NAME}
# CMD ["dotnet", "vstest", "./${ETESTS_ARC_NAME}/${ETESTS_BIN_NAME}", "/Settings:./${ETESTS_ARC_NAME}/${ERUNSETTINGS_FILE_NAME}"]
CMD dotnet vstest ./${ETESTS_ARC_NAME}/${ETESTS_BIN_NAME} /Settings:./${ETESTS_ARC_NAME}/${ERUNSETTINGS_FILE_NAME}
