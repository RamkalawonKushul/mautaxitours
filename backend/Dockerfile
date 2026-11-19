FROM ruby:3.3-slim

RUN apt-get update -qq \
  && apt-get install --no-install-recommends -y build-essential libpq-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile
RUN bundle install

COPY . .

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1

EXPOSE 10000

# Prepare the trial database on startup because Render's free web instances
# do not support pre-deploy commands or one-off shell jobs.
# Invoke the Rails binstub through Ruby so executable file permissions are not required.
CMD ["bash", "-lc", "bundle exec ruby bin/rails db:prepare && bundle exec ruby bin/rails server -b 0.0.0.0 -p ${PORT:-10000}"]
