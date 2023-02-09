FROM local/alpine-selenium-node-base:latest

RUN apk --no-cache add \
        chromium \
        chromium-chromedriver

COPY entrypoint.sh ${SELENIUM_DIR}
ENTRYPOINT ["./entrypoint.sh"]