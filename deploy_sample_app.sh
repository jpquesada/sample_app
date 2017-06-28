#!/bin/bash
yum update -y
iptables -I INPUT -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
service iptables save
service iptables restart
yum -y install docker-io
service docker start
chkconfig docker on
docker run --name some-postgres -e POSTGRES_PASSWORD=12345678 -e POSTGRES_USER=sample_app -d postgres
cd /opt
yum -y install git
git clone https://bitbucket.org/evcndan/sample_app_rails_4.git
cd sample_app_rails_4
cp config/database.yml.postgres config/database.yml
echo -e "FROM ruby:2.2.6-onbuild \n RUN apt-get update && apt-get -y install nodejs \n CMD [\"/bin/bash\"]" > Dockerfile
docker build -t sample_app_image .
docker run --link some-postgres:db --rm -w /usr/src/app sample_app_image rake db:setup
docker run --link some-postgres:db --rm -w /usr/src/app sample_app_image rake db:migrate
docker run --link some-postgres:db --rm -w /usr/src/app sample_app_image rake db:populate
docker run --link some-postgres:db -d -w /usr/src/app -p 80:3000 sample_app_image rails server
