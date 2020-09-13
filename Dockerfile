FROM ruby:2.7.1

ENV LANG C.UTF-8

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  libfontconfig1 && \
  rm -rf /var/lib/apt/lists/* && \
  gem install sinatra \
  sinatra-contrib \
  pg \
  pry

WORKDIR /app