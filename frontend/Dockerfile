# Use pre-built files
FROM nginx:1.19.5-alpine

# Runtime stage
FROM nginx:1.19.5-alpine

# Copy nginx configuration files
COPY ./nginx/mime.types /etc/nginx/mime.types
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy pre-built application
COPY dist/utm-stack/ /usr/share/nginx/html/

# Copy compatibility HTML file as backup (not overriding index.html)
COPY ./nginx/compatibility.html /usr/share/nginx/html/compatibility.html

# Copy JavaScript compatibility wrapper
COPY ./nginx/js-compatibility.js /usr/share/nginx/html/js-compatibility.js

# Copy JavaScript transformer
COPY ./nginx/js-transformer.js /usr/share/nginx/html/js-transformer.js

# Copy and run JavaScript cleaning script
COPY ./nginx/clean-js.sh /usr/share/nginx/html/clean-js.sh
RUN chmod +x /usr/share/nginx/html/clean-js.sh

# Health check
HEALTHCHECK --start-period=120s --interval=60s --timeout=60s \
  CMD curl --insecure -I -f http://localhost/health && curl --insecure -I -f http://localhost/api/ping || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]