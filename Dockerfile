FROM python:3.10.2-alpine3.15

ENV PYTHONUNBUFFERED True
ENV TRIVY_VERSION 0.24.2
ENV TRIVY_CHECKSUM 4b2dd2bca5c44a4bb175d66e784457edd7fe5154bd2554319907c2abd76c8f5a
ENV APP_HOME /app
ENV USER_HOME /var/cache/gunicorn
ENV CURL_VERSION 7.80
ENV UID 1001
ENV GID 1001
ENV PORT 8080
ENV PENV_VERSION 2022.1.8
ENV PIP_VERSION 22.0.3
ENV POINTVY_VERSION 1.4.2

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

WORKDIR ${APP_HOME}
COPY app/Pipfile .
COPY app/Pipfile.lock .

RUN set -eux; \
    addgroup -g $GID -S gunicorn; \
    adduser -S -D -H -u $UID -h ${USER_HOME} -G gunicorn -g gunicorn gunicorn; \
    apk add --no-cache curl~=${CURL_VERSION} && rm -rf /var/cache/apk/*; \
    mkdir -p ${USER_HOME}; \
    chown -R gunicorn:gunicorn ${APP_HOME}; \
    chown -R gunicorn:gunicorn ${USER_HOME}; \
    curl -sSL https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz \
    -o trivy.tar.gz; \
    echo "${TRIVY_CHECKSUM}  trivy.tar.gz" | sha256sum -c -; \
    tar xf trivy.tar.gz && rm trivy.tar.gz && chmod ugo+x trivy; \
    apk del curl; \
    pip install -U pip=="$PIP_VERSION"; \
    pip install -U pipenv=="$PENV_VERSION"

COPY app/ ./

USER gunicorn

RUN pipenv install --deploy --ignore-pipfile

CMD pipenv run gunicorn --bind :${PORT} --workers 1 --threads 2 --timeout 0 main:app
