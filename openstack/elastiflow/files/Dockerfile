FROM perl:5.32 AS builder

RUN mkdir -p /etc/logstash/elastiflow/geoipdbs/

WORKDIR /etc/logstash/elastiflow/geoipdbs/

ENV PERL5LIB=./local/lib/perl5

RUN curl -LO http://xrl.us/cpanm

RUN cpanm --local-lib local local::lib && \
    cpanm --local-lib local MaxMind::DB::Reader && \
    cpanm --local-lib local MaxMind::DB::Writer::Tree && \
    cpanm --local-lib local Net::Works::Network && \
    cpanm --local-lib local Data::Dumper && \
    cpanm --local-lib local JSON::PP

FROM builder as asn

COPY ./*GeoLite2-ASN.* ./
RUN chmod +x createGeoLite2-ASN.pl && perl createGeoLite2-ASN.pl -f GeoLite2-ASN.json -p GeoLite2-ASN.mmdb

FROM builder as city

COPY ./*GeoLite2-City.* ./
RUN chmod +x createGeoLite2-City.pl && perl createGeoLite2-City.pl -f GeoLite2-City.json -p GeoLite2-City.mmdb

FROM robcowart/elastiflow-logstash-oss:4.0.0-beta

COPY --from=asn --chown=logstash:root /etc/logstash/elastiflow/geoipdbs/GeoLite2-ASN-SAP.mmdb /etc/logstash/elastiflow/geoipdbs/GeoLite2-ASN.mmdb
COPY --from=city --chown=logstash:root /etc/logstash/elastiflow/geoipdbs/GeoLite2-City-SAP.mmdb /etc/logstash/elastiflow/geoipdbs/GeoLite2-City.mmdb

