FROM stevenpray/ubuntu

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN apt-get update

RUN apt-get install --assume-yes --no-install-recommends --no-install-suggests \
    postgresql-10 \
    postgresql-client-10 \
    postgresql-contrib-10

RUN apt-get purge --assume-yes --auto-remove \
    --option APT::AutoRemove::RecommendsImportant=false \
    --option APT::AutoRemove::SuggestsImportant=false
RUN rm -rf /var/lib/apt/lists/*

ENV PATH "$PATH:/usr/lib/postgresql/10/bin:/docker-entrypoint-initdb.d"
ENV PGDATA /var/lib/postgresql/10/main
ENV PGUSER postgres
ENV PGTZ UTC

RUN mkdir -p /docker-entrypoint-initdb.d

COPY etc/postgresql /etc/postgresql/10/main
COPY etc/postgresql-common /etc/postgresql-common

ENV FLYWAY_CONFIG_FILES /etc/flyway.conf
ENV FLYWAY_VERSION 5.1.4

RUN curl -LS https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz \
    | tar xzv -C /opt \
    && ln -s /opt/flyway-${FLYWAY_VERSION}/flyway /usr/local/bin/flyway

RUN chmod +x /opt/flyway-${FLYWAY_VERSION}/flyway

COPY etc/flyway.conf /etc/flyway.conf

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

RUN chown root:root /usr/local/bin/*
RUN chmod 755 /usr/local/bin/*

CMD ["postgres", "--config-file=/etc/postgresql/10/main/postgresql.conf"]
