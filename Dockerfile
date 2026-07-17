# Dockerfile development version
FROM ruby:3.3.6 AS home_control

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential libpq-dev zlib1g-dev liblzma-dev \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

# Default directory
ENV INSTALL_PATH="/app/home_control"
RUN mkdir -p $INSTALL_PATH

EXPOSE 3000

# Install gems
WORKDIR $INSTALL_PATH

COPY Gemfile* .
RUN gem install bundler
RUN bundle install

COPY . .
COPY config/database.production.yml config/database.yml

# Importmap + dartsass-sprockets — no Node/Yarn required
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rake assets:clobber
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rake assets:precompile
