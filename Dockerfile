FROM ruby:2.3.4
RUN apt-get update && apt-get install -y libssh2-1-dev libssh2-1 vim qqcmake && apt-get clean
RUN useradd -m appuser && su - appuser -c 'ssh-keygen -t rsa -N "password" -f /home/appuser/.ssh/id_rsa' && mkdir /app \
    && chown appuser:appuser /app
COPY ./Gemfile* /app/
COPY .bash_profile /home/appuser/.bash_profile
RUN su - appuser -c 'git config --global user.email "user@example.com"' && \
    su - appuser -c 'git config --global user.name "Example User"' && \
    chown -R appuser:appuser /home/appuser/ && \
    chown -R appuser:appuser /app
RUN su - appuser -c "BUNDLE_PATH='/home/appuser/.bundle' GEM_HOME='/home/appuser/.gems' bundle install --gemfile=/app/Gemfile" \
    && rm -f /app/*
# update PATH to find local gems
USER appuser