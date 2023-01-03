FROM nginx
COPY --from=phntom/binaryvision-static-wordpress:0.0.3@sha256:85a2dfb83b11c8ef1972170145e2811e9cca2007d3bc6a513749a3e91aea5580 /etc/nginx/conf.d/statis-website.conf /etc/nginx/conf.d/static-website.conf
COPY --from=phntom/binaryvision-static-wordpress:0.0.3@sha256:85a2dfb83b11c8ef1972170145e2811e9cca2007d3bc6a513749a3e91aea5580 /usr/share/nginx/html /usr/share/nginx/html

