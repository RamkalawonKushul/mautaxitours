FROM ruby:3.3-slim
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libpq-dev postgresql-client && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile
RUN bundle install
COPY . .
ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=1
EXPOSE 3000
CMD ["bash", "-lc", "bin/rails db:prepare && bin/rails server -b 0.0.0.0 -p 3000"]
