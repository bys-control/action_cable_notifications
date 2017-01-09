FROM phusion/passenger-ruby22:0.9.19
MAINTAINER ByS Control "info@bys-control.com.ar"

RUN apt-get update && apt-get install -y --no-install-recommends nano sudo iputils-ping && rm -rf /var/lib/apt/lists/*
ENV TERM=xterm

RUN mkdir /home/app/webapp
WORKDIR /home/app/webapp

# Install gems
ADD Gemfile* .ruby* /home/app/webapp/
ADD vendor /home/app/webapp/vendor/
RUN bundle install --without development test

# Copio la aplicacion
ADD . /home/app/webapp
RUN RAILS_ENV=production rake assets:precompile

# Start Nginx / Passenger
# Remove the default site
# Add the nginx site and config
RUN rm -f /etc/service/nginx/down && \
	rm /etc/nginx/sites-enabled/default && \
	cp docker/nginx.conf /etc/nginx/sites-enabled/webapp.conf && \
	cp docker/rails-env.conf /etc/nginx/main.d/rails-env.conf && \
  cp docker/main-context.conf /etc/nginx/conf.d/main-context.conf && \
  cp docker/http-block.conf /etc/nginx/conf.d/http-block.conf

# Init application
CMD ["/home/app/webapp/docker/init.sh"]
