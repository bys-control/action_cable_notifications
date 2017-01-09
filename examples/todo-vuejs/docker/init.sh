#! /bin/bash

if [[ ! $DEVELOPMENT ]]; then
	echo "## Starting container in PRODUCTION mode"
	chown -R app:app $(pwd)
	sudo -E -H -u app bash -c 'rake db:migrate db:seed'
	/sbin/my_init ## Use baseimage-docker's init system.
else
	echo "## Starting container in DEVELOPMENT mode"
	echo "## RAILS_ENV=${RAILS_ENV}"
	# Change app user UID and GID to the Gemfile's
	user_id="$(stat -c %u Gemfile)"
	group_id="$(stat -c %g Gemfile)"
	usermod -u $user_id app && groupmod -g $group_id app

	bundle install
	# Runs migrations and app server as "app" user preserving environment (-E option)
	sudo -E -H -u app bash -c 'rake assets:precompile db:migrate db:seed'
	/sbin/my_init
fi
