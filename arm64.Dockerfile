FROM arm64v8/alpine:3.16.2

ENV JAVA_VERSION="jdk-11.0.11+9" \
  LANG='en_US.UTF-8' \
  LANGUAGE='en_US:en' \
  LC_ALL='en_US.UTF-8'

#
# glibc setup
#
RUN set -eux; \
  apk add --no-cache tzdata --virtual .build-deps binutils curl gnupg zstd; \
  GLIBC_VER="2.32-r0"; \
  ALPINE_GLIBC_REPO="https://github.com/ljfranklin/alpine-pkg-glibc/releases/download"; \
  GCC_LIBS_URL="https://mirrors.dotsrc.org/archlinuxarm/aarch64/core/gcc-libs-12.1.0-2.1-aarch64.pkg.tar.xz"; \
  ZLIB_URL="https://mirrors.dotsrc.org/archlinuxarm/aarch64/core/zlib-1%3A1.2.12-2-aarch64.pkg.tar.xz"; \
  curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub; \
  SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2"; \
  echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - ; \
  gpg --keyserver hkps://pgp.mit.edu:443 --recv-key 68B3537F39A313B3E574D06777193F152BDBE6A6; \
  curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}-arm64/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk; \
  apk add --allow-untrusted --no-cache /tmp/glibc-${GLIBC_VER}.apk; \
  curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}-arm64/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk; \
  apk add --allow-untrusted --no-cache /tmp/glibc-bin-${GLIBC_VER}.apk; \
  curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}-arm64/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk; \
  apk add --allow-untrusted --no-cache /tmp/glibc-i18n-${GLIBC_VER}.apk; \
  /usr/glibc-compat/bin/localedef --inputfile en_US --charmap UTF-8 "$LANG" || true ;\
  echo "export LANG=$LANG" > /etc/profile.d/locale.sh; \
  curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz; \
  curl -LfsS ${GCC_LIBS_URL}.sig -o /tmp/gcc-libs.tar.xz.sig; \
  gpg --verify /tmp/gcc-libs.tar.xz.sig; \
  mkdir /tmp/gcc; \
  tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc; \
  mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib; \
  strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so*; \
  curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz; \
  curl -LfsS ${ZLIB_URL}.sig -o /tmp/libz.tar.xz.sig; \
  gpg --verify /tmp/libz.tar.xz.sig; \
  mkdir /tmp/libz; \
  tar -xf /tmp/libz.tar.xz -C /tmp/libz; \
  mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib; \
  apk del --purge .build-deps glibc-i18n; \
  rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar* /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*;

#
# AdoptOpenJDK/openjdk11 setup
#
RUN set -eux; \
  apk add --no-cache --virtual .fetch-deps curl; \
  ARCH="$(apk --print-arch)"; \
  case "${ARCH}" in \
  aarch64|arm64) \
  ESUM='fde6b29df23b6e7ed6e16a237a0f44273fb9e267fdfbd0b3de5add98e55649f6'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jre_aarch64_linux_hotspot_11.0.11_9.tar.gz'; \
  ;; \
  armhf|armv7l) \
  ESUM='ad02656f800fd64c2b090b23ad24a099d9cd1054948ecb0e9851bc39c51c8be8'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jre_arm_linux_hotspot_11.0.11_9.tar.gz'; \
  ;; \
  ppc64el|ppc64le) \
  ESUM='37c19c7c2d1cea627b854a475ef1a765d30357d765d20cf3f96590037e79d0f3'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jre_ppc64le_linux_hotspot_11.0.11_9.tar.gz'; \
  ;; \
  s390x) \
  ESUM='f18101fc50aad795a41b4d3bbc591308c83664fd2390bf2bc007fd9b3d531e6c'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jre_s390x_linux_hotspot_11.0.11_9.tar.gz'; \
  ;; \
  amd64|x86_64) \
  ESUM='144f2c6bcf64faa32016f2474b6c01031be75d25325e9c3097aed6589bc5d548'; \
  BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jre_x64_linux_hotspot_11.0.11_9.tar.gz'; \
  ;; \
  *) \
  echo "Unsupported arch: ${ARCH}"; \
  exit 1; \
  ;; \
  esac; \
  curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
  echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
  mkdir -p /opt/java/openjdk; \
  cd /opt/java/openjdk; \
  tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
  apk del --purge .fetch-deps; \
  rm -rf /var/cache/apk/*; \
  rm -rf /tmp/openjdk.tar.gz;

#
# SonarQube setup
#
ARG SONARQUBE_VERSION=9.6.1.59531
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
ENV JAVA_HOME=/opt/java/openjdk \
  PATH="/opt/java/openjdk/bin:$PATH" \
  SONARQUBE_HOME=/opt/sonarqube \
  SONAR_VERSION="${SONARQUBE_VERSION}" \
  SQ_DATA_DIR="/opt/sonarqube/data" \
  SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
  SQ_LOGS_DIR="/opt/sonarqube/logs" \
  SQ_TEMP_DIR="/opt/sonarqube/temp"

RUN set -eux; \
  addgroup -S -g 1000 sonarqube; \
  adduser -S -D -u 1000 -G sonarqube sonarqube; \
  apk add --no-cache --virtual build-dependencies gnupg unzip curl; \
  apk add --no-cache bash su-exec ttf-dejavu; \
  # pub   2048R/D26468DE 2015-05-25
  #       Key fingerprint = F118 2E81 C792 9289 21DB  CAB4 CFCA 4A29 D264 68DE
  # uid                  sonarsource_deployer (Sonarsource Deployer) <infra@sonarsource.com>
  # sub   2048R/06855C1D 2015-05-25
  echo "networkaddress.cache.ttl=5" >> "${JAVA_HOME}/conf/security/java.security"; \
  sed --in-place --expression="s?securerandom.source=file:/dev/random?securerandom.source=file:/dev/urandom?g" "${JAVA_HOME}/conf/security/java.security"; \
  for server in $(shuf -e ha.pool.sks-keyservers.net \
  hkp://p80.pool.sks-keyservers.net:80 \
  keyserver.ubuntu.com \
  hkp://keyserver.ubuntu.com:80 \
  pgp.mit.edu) ; do \
  gpg --batch --keyserver "${server}" --recv-keys 679F1EE92B19609DE816FDE81DB198F93525EC1A && break || : ; \
  done; \
  mkdir --parents /opt; \
  cd /opt; \
  curl --fail --location --output sonarqube.zip --silent --show-error "${SONARQUBE_ZIP_URL}"; \
  curl --fail --location --output sonarqube.zip.asc --silent --show-error "${SONARQUBE_ZIP_URL}.asc"; \
  gpg --batch --verify sonarqube.zip.asc sonarqube.zip; \
  unzip -q sonarqube.zip; \
  mv "sonarqube-${SONARQUBE_VERSION}" sonarqube; \
  rm sonarqube.zip*; \
  rm -rf ${SONARQUBE_HOME}/bin/*; \
  chown -R sonarqube:sonarqube ${SONARQUBE_HOME}; \
  # this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
  chmod -R 777 "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \
  apk del --purge build-dependencies;

COPY --chown=sonarqube:sonarqube run.sh sonar.sh ${SONARQUBE_HOME}/bin/

WORKDIR ${SONARQUBE_HOME}
EXPOSE 9000
STOPSIGNAL SIGINT
ENTRYPOINT ["/opt/sonarqube/bin/run.sh"]
CMD ["/opt/sonarqube/bin/sonar.sh"]
