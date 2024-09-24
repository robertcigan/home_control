# Dockerfile development version
FROM ruby:3.1.2 AS home_control

# Install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -o /root/yarn-pubkey.gpg && apt-key add /root/yarn-pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y --no-install-recommends nodejs yarn build-essential libpq-dev zlib1g-dev liblzma-dev

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

# RUN rm -rf node_modules vendor

RUN yarn install
RUN rake assets:clobber
RUN rake assets:precompile