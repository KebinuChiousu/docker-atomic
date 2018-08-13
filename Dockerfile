FROM fedora:28

RUN yum -y install openssh-clients openssh-server && \
    yum -y install pykickstart rpm-ostree-toolbox && \
    yum -y install git which sudo zsh && \
    yum -y install rpm-build rpmdevtools && \
    yum -y clean all && \
    touch /run/utmp && \
    chmod u+x usr/bin/ping && \
    mkdir -p /srv/rpm-ostree/centos-atomic-host/7

RUN dnf -y install golang

COPY entrypoint.sh /
RUN usermod -p "!" root
COPY config/authorized_keys /root/.ssh/authorized_keys
COPY config/sudoers /etc/sudoers
RUN chmod 440 /etc/sudoers
RUN chown root:root /etc/sudoers
RUN useradd -g wheel -s /bin/zsh fedora
COPY config/authorized_keys /home/fedora/.ssh/authorized_keys
RUN mkdir /home/fedora/git
RUN mkdir -p /home/fedora/go/bin
RUN chown -R fedora:wheel /home/fedora
RUN chmod -R 755 /home/fedora
RUN chmod 640 /home/fedora/.ssh/authorized_keys

WORKDIR /root
RUN git clone https://github.com/baude/sig-atomic-buildscripts

USER fedora
WORKDIR /home/fedora
RUN rpmdev-setuptree
WORKDIR /home/fedora/git
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git oh-my-zsh
RUN git clone https://github.com/powerline/fonts.git powerline-fonts
RUN /home/fedora/git/powerline-fonts/install.sh
RUN /home/fedora/git/oh-my-zsh/tools/install.sh
RUN mkdir -p /home/fedora/.oh-my-zsh/custom/themes
WORKDIR /home/fedora/.oh-my-zsh/custom/themes
RUN git clone https://github.com/bhilburn/powerlevel9k.git powerlevel9k
WORKDIR /home/fedora
RUN sed -i "s|ZSH_THEME=\"robbyrussell\"|ZSH_THEME=\"powerlevel9k/powerlevel9k\"|g" .zshrc
COPY config/omz/*.zsh /home/fedora/.oh-my-zsh/custom/

RUN GOPATH=/home/fedora/go && \ 
    PATH=$PATH:$GOPATH/bin && \ 
    curl https://glide.sh/get | sh && \ 
    mkdir -p $GOPATH/src/github.com/mh-cbon/go-bin-rpm && \ 
    mkdir -p $GOPATH/src/github.com/KebinuChiousu/docker-volume-local-persist
WORKDIR /home/fedora/go/src/github.com/mh-cbon/go-bin-rpm
RUN GOPATH=/home/fedora/go && \ 
    PATH=$PATH:$GOPATH/bin && \ 
    git clone https://github.com/mh-cbon/go-bin-rpm.git . && \ 
    glide install && \ 
    go install
WORKDIR /home/fedora/go/src/github.com/KebinuChiousu/docker-volume-local-persist
RUN GOPATH=/home/fedora/go && \ 
    PATH=$PATH:$GOPATH/bin && \ 
    git clone https://github.com/KebinuChiousu/docker-volume-local-persist . && \ 
    glide install && \ 
    go install


USER root

VOLUME /etc/ssh
VOLUME /home/fedora
VOLUME /srv/rpm-ostree/centos-atomic-host/7
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
