#FROM fedora:latest
FROM docker.io/Fedora-Docker-Base-22_Alpha-20150305.x86_64

MAINTAINER Jakub Filak

ENV container docker

#RUN dnf copr enable -y jfilak/abrt-atomic
RUN curl -o /etc/yum.repos.d/jfilak-abrt-atomic.repo https://copr.fedoraproject.org/coprs/jfilak/abrt-atomic/repo/fedora-22/jfilak-abrt-atomic-fedora-22.repo
RUN yum --releasever=22 -y update; dnf --releasever=22 -y install supervisor git sendmail abrt-tui abrt-addon-ccpp abrt-addon-kerneloops abrt-addon-vmcore abrt-dbus libreport-fedora libreport-plugin-\* gdb ; dnf clean all

LABEL Version=1.0

RUN sed 's/\(abrt-action-save-package-data\)/\1 -r \/host/' -i /etc/libreport/events.d/abrt_event.conf
RUN sed 's/\(abrt-action-save-kernel-data\)/\1 -r \/host/' -i /etc/libreport/events.d/koops_event.conf
RUN sed 's/\(abrt-action-save-container-data\)/\1 -r \/host/' -i /etc/libreport/events.d/abrt_event.conf
RUN sed 's/\(journalctl \)--system/\1 -D \/host\/var\/log\/journal /' -i /etc/libreport/events.d/ccpp_event.conf
RUN sed 's/\(journalctl.*-b\)/\1 -D \/host\/var\/log\/journal /' -i /etc/libreport/events.d/ccpp_event.conf
RUN sed 's/\(OpenGPGCheck *=\).*/\1 no/' -i /etc/abrt/abrt-action-save-package-data.conf

LABEL INSTALL="docker run --privileged --rm -v /:/host IMAGE \
/usr/local/bin/abrt-install.sh"

LABEL UNINSTALL="docker run --privileged --rm -v /:/host IMAGE \
/usr/local/bin/abrt-uninstall.sh"

LABEL RUN="docker run -d --privileged --name NAME \
-v /var/tmp:/var/tmp \
-v /run:/run \
-v /var/lib/abrt:/var/lib/abrt \
-v /:/host \
-e HOST=/host' \
-e IMAGE=IMAGE \
-e NAME=NAME \
--pid=host \
--net=host \
IMAGE"

RUN git clone --depth=1 --single-branch -b master https://github.com/abrt/cockpit-abrt.git /usr/local/share/cockpit

ADD abrt-install.sh /usr/local/bin/abrt-install.sh
ADD abrt-uninstall.sh /usr/local/bin/abrt-uninstall.sh

RUN chmod +x /usr/local/bin/abrt-install.sh
RUN chmod +x /usr/local/bin/abrt-uninstall.sh

ADD supervisord.ini /etc/supervisord.d/supervisord.ini

CMD /usr/bin/supervisord
