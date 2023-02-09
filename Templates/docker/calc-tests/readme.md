# Build samples
``` PowerShell
docker build -t autotestmate-samples:latest --build-arg TESTS_URL=https://stgacct1234.blob.core.windows.net/autotestmate/samples.zip `
    --build-arg TESTS_ARC_NAME=samples --build-arg=TESTS_BIN_NAME=AutoTestMate.Samples.Web.Tests.dll --build-arg RUNSETTINGS_FILE_NAME=Test.runsettings --no-cache .
```

# Build calculator
``` PowerShell
docker build -t autotestmate-calculator:latest --build-arg TESTS_URL=https://stgacct1234.blob.core.windows.net/autotestmate/calculator.zip `
    --build-arg TESTS_ARC_NAME=calculator --build-arg=TESTS_BIN_NAME=AutoTestMate.Calculator.Tests.dll --build-arg RUNSETTINGS_FILE_NAME=Test.runsettings --no-cache .
```

docker -f docker-compose.run.yml up --scale autotestmate-calculator=2
