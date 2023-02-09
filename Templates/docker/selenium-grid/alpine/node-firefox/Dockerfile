FROM local/alpine-selenium-node-base:latest

RUN apk --no-cache add \
        firefox-esr

COPY entrypoint.sh ${SELENIUM_DIR}
ENTRYPOINT ["./entrypoint.sh"]