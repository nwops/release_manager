FROM ruby:2.3.4
RUN apt-get update && apt-get install -y libssh2-1-dev libssh2-1 cmake && apt-get clean
RUN useradd -m appuser && su - appuser -c 'ssh-keygen -t rsa -N "password" -f /home/appuser/.ssh/id_rsa' && mkdir /app \
    && chown appuser:appuser /app
COPY ./Gemfile* /app/
RUN su - appuser -c "BUNDLE_PATH='/home/appuser/.bundle' GEM_HOME='/home/appuser/.gems' bundle install --gemfile=/app/Gemfile" \
    && rm -f /app/*

USER appuser