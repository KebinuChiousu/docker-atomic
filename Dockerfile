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

ENV GOPATH /home/fedora/go
ENV PATH $PATH:/home/fedora/go/bin

# Install Glide (Go package manager)
RUN curl https://glide.sh/get | sh && \ 
    mkdir -p $GOPATH/src/github.com/mh-cbon/go-bin-rpm && \ 
    mkdir -p $GOPATH/src/github.com/mh-cbon/changelog && \ 
    mkdir -p $GOPATH/src/local-persist
# Install rpm package builder
WORKDIR $GOPATH/src/github.com/mh-cbon/go-bin-rpm
RUN git clone https://github.com/mh-cbon/go-bin-rpm.git . && \ 
    glide install && \ 
    go install
# Install changelog maintainer
WORKDIR $GOPATH/src/github.com/mh-cbon/changelog
RUN git clone https://github.com/mh-cbon/changelog.git . && \ 
    glide install && \ 
    go install
# Install docker volume plugin: local-persist
WORKDIR $GOPATH/src/local-persist
RUN git clone https://github.com/KebinuChiousu/local-persist . && \ 
    glide install && \ 
    go install && \ 
    mkdir -p build/amd64 && \ 
    mkdir -p pkg-build && \
    cp $GOPATH/bin/local-persist ./build/amd64/

USER root

VOLUME /etc/ssh
VOLUME /home/fedora
VOLUME /srv/rpm-ostree/centos-atomic-host/7
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
