FROM ubuntu
USER mwaeckerlin
ENV TERM xterm

RUN debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
RUN debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
RUN apt-get update
RUN apt-get install -y postfix

