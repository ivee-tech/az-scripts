FROM mcr.microsoft.com/dotnet/core/sdk:3.1

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        wget \
        unzip

RUN wget -N https://stgacct1234.blob.core.windows.net/autotestmate/samples.zip

# RUN unzip samples.zip

# CMD ["dotnet", "vstest", "./samples/AutoTestMate.Samples.Web.Tests.dll", "/Settings:./samples/Test.runsettings"]
CMD ["sh"]