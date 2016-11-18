FROM mwaeckerlin/mailforward
MAINTAINER mwaeckerlin

RUN apt-get update
RUN apt-get install -y postfix postfix-ldap postfix-pcre