FROM local/alpine-selenium-base:latest

ENV SELENIUM_HUB_PORT 4444

EXPOSE ${SELENIUM_HUB_PORT}

COPY entrypoint.sh ${SELENIUM_DIR}
ENTRYPOINT ["./entrypoint.sh"]
