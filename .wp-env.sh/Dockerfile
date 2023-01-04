FROM wordpress:5.7-php7.3-apache

LABEL maintainer="Andrzej Misiewicz <andrzej@pandasoft.pl>"

# change uid and gid for user
RUN usermod -u 1000 www-data; \
    groupmod -g 1000 www-data; \
	chown -R www-data:www-data /var/www/html/

###########################################################################
# xDebug:
###########################################################################

ARG INSTALL_XDEBUG=true

RUN if [ ${INSTALL_XDEBUG} = true ]; then \
	# Install the xdebug extension
	if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
	    pecl install xdebug-2.5.5; \
	else \
	    pecl install xdebug; \
	fi && \
	docker-php-ext-enable xdebug && \
	{ \
		echo 'zend_extension=xdebug.so'; \
		echo 'xdebug.client_port=9003'; \
		echo 'xdebug.mode=debug'; \
		echo 'xdebug.log=/var/log/xdebug.log'; \
		echo 'xdebug.discover_client_host=0'; \
		echo 'xdebug.start_with_request=yes'; \
		echo 'xdebug.client_host=172.18.0.1'; \
		echo 'xdebug.output_dir=/run/profiler'; \
	} > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
;fi

###########################################################################
# PHP REDIS EXTENSION
###########################################################################

ARG INSTALL_PHPREDIS=true

RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    # Install Php Redis Extension
    printf "\n" | pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis \
;fi

###########################################################################
# IonCube Loader:
###########################################################################

ARG INSTALL_IONCUBE=true

RUN if [ ${INSTALL_IONCUBE} = true ]; then \
    # Install the php ioncube loader
    curl -L -o /tmp/ioncube_loaders_lin_x86-64.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar zxpf /tmp/ioncube_loaders_lin_x86-64.tar.gz -C /tmp \
    && mv /tmp/ioncube/ioncube_loader_lin_$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;").so $(php -r "echo ini_get('extension_dir');")/ioncube_loader.so \
    && printf "zend_extension=ioncube_loader.so\n" > $PHP_INI_DIR/conf.d/0ioncube.ini \
    && rm -rf /tmp/ioncube* \
;fi

###########################################################################
# Intl EXTENSION
###########################################################################

ARG INSTALL_PHPINTL=true

RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    apt-get update \
    && apt-get install -y libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
;fi

#####################################
# Exif:
#####################################

ARG INSTALL_EXIF=true

RUN if [ ${INSTALL_EXIF} = true ]; then \
    # Enable Exif PHP extentions requirements
    docker-php-ext-install exif && \
     docker-php-ext-enable exif \
;fi