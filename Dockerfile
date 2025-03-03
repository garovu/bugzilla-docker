FROM ubuntu:22.04
LABEL maintainer="Stefan Pielmeier <stefan@symlinux.com>"
LABEL version="0.3"
LABEL description="Docker image for bugzilla on Ubuntu 22.04 using PerlCGI/Apache2"

# Environment variables
ENV BUGZILLA_BRANCH=release-5.0-stable \
    APACHE_USER=www-data \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /var/www/html

# Install required packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      vim \
      bash \
      supervisor \
      libappconfig-perl \
      libdate-calc-perl \
      libtemplate-perl \
      libmime-tools-perl \
      build-essential \
      libdatetime-timezone-perl \
      libdatetime-perl \
      libemail-sender-perl \
      libemail-mime-perl \
      libdbi-perl \
      libdbd-mysql-perl \
      libcgi-pm-perl \
      libmath-random-isaac-perl \
      libmath-random-isaac-xs-perl \
      libapache2-mod-perl2 \
      libapache2-mod-perl2-dev \
      libchart-perl \
      libxml-perl \
      libxml-twig-perl \
      perlmagick \
      libgd-graph-perl \
      libtemplate-plugin-gd-perl \
      libsoap-lite-perl \
      libhtml-scrubber-perl \
      libjson-rpc-perl \
      libdaemon-generic-perl \
      libtheschwartz-perl \
      libtest-taint-perl \
      libauthen-radius-perl \
      libfile-slurp-perl \
      libencode-detect-perl \
      libmodule-build-perl \
      libnet-ldap-perl \
      libfile-which-perl \
      libauthen-sasl-perl \
      libfile-mimeinfo-perl \
      libhtml-formattext-withlinks-perl \
      libgd-dev \
      libcache-memcached-perl \
      libfile-copy-recursive-perl \
      libdbd-sqlite3-perl \
      libmysqlclient-dev \
      graphviz \
      sphinx-common \
      rst2pdf \
      libemail-address-perl \
      libemail-reply-perl \
      apache2 \
      postfix \
      git \
      cpanminus \
      libdbix-connector-perl \
      libjson-xs-perl \
      make && \
    rm -rf /var/lib/apt/lists/*

# Configure Apache modules
RUN a2enmod cgid rewrite headers expires

# Copy configuration files
COPY bugzilla.conf /etc/apache2/conf-available/
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY perl_patch /tmp/perl_patch

# Set appropriate permissions for files
RUN chmod 755 /entrypoint.sh && \
    chmod 644 /etc/supervisor/conf.d/supervisord.conf

# Enable Bugzilla configuration in Apache
RUN a2enconf bugzilla

# Clone Bugzilla repository
RUN git clone --branch ${BUGZILLA_BRANCH} https://github.com/bugzilla/bugzilla /var/www/html/bugzilla

# Install necessary Perl modules using cpanm
RUN cpanm DBIx::Connector Template Email::Sender Email::Address::XS JSON::XS PatchReader XMLRPC::Lite && \
    # Find the correct path for Safe.pm in Ubuntu 22.04
    SAFE_PM_PATH=$(find /usr/share/perl -name "Safe.pm") && \
    if [ -n "$SAFE_PM_PATH" ]; then \
      patch -u $SAFE_PM_PATH -i /tmp/perl_patch || true; \
    else \
      echo "Safe.pm not found"; \
      exit 1; \
    fi

# Configure Bugzilla
WORKDIR /var/www/html/bugzilla
RUN ./checksetup.pl && \
    chown -R ${APACHE_USER}:${APACHE_USER} /var/www/html/bugzilla && \
    rm -f /tmp/perl_patch

# Define volumes for persistent data
VOLUME ["/var/www/html/bugzilla/images", "/var/www/html/bugzilla/data", "/var/www/html/bugzilla/lib"]

# Expose port for apache2
EXPOSE 80

# Set working directory and entrypoint
WORKDIR /var/www/html
ENTRYPOINT ["/entrypoint.sh"]