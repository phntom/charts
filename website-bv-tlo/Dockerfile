# docker build . -t phntom/binaryvision-tlo-static:0.0.4 --pull

FROM php:apache

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY root /
