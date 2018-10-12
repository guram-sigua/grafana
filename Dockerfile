FROM ubuntu:18.04
LABEL "org.opencontainers.image.authors"="levkov"
EXPOSE 9001 22 3000
WORKDIR /tmp
ARG GRAFANA_VERSION=5.3.0

RUN apt-get update && \
    apt-get install wget \
                    supervisor \
                    openssh-server \
                    software-properties-common \
                    adduser \
                    curl \ 
                    libfontconfig \
                    dos2unix \
                    -y

RUN wget --no-check-certificate https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_${GRAFANA_VERSION}_amd64.deb  && \
    dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb && \
    rm -rf grafana_${GRAFANA_VERSION}_amd64.deb

RUN chown -R grafana:grafana /var/lib/grafana /var/log/grafana
RUN chown -R grafana:grafana /etc/grafana 

RUN grafana-cli plugins install grafana-piechart-panel && \
    grafana-cli plugins install mtanda-histogram-panel && \
    grafana-cli plugins install grafana-worldmap-panel

RUN mkdir -p /var/run/sshd /var/log/supervisor && \
    echo 'root:ContaineR' |chpasswd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    mkdir /root/.ssh

COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod 657 /var/log/supervisor/ && chmod 657 /usr/share/grafana/
USER grafana
RUN mkdir /usr/share/grafana/.aws/
#COPY conf/credentials /usr/share/grafana/.aws/credentials
RUN touch /var/log/supervisor/grafana-webapp.log
CMD ["/usr/bin/supervisord"]
