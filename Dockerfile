FROM fedora:27

RUN dnf -y install openssh-clients openssh-server && \
    dnf -y install iputils bind-utils nc wget && \
    dnf -y install pykickstart rpm-ostree-toolbox && \
    dnf -y install rpm-build rpmdevtools && \
    dnf -y install git which sudo zsh python3 golang

COPY entrypoint.sh /

RUN usermod -p "!" root
COPY config/authorized_keys /root/.ssh/authorized_keys
COPY config/sudoers /etc/sudoers
RUN chmod 440 /etc/sudoers
RUN chown root:root /etc/sudoers

WORKDIR /root
RUN git clone https://github.com/baude/sig-atomic-buildscripts

RUN useradd -g wheel -s /bin/zsh fedora
COPY config/authorized_keys /home/fedora/.ssh/authorized_keys
RUN mkdir /home/fedora/git
RUN mkdir -p /home/fedora/go/bin
RUN chown -R fedora:wheel /home/fedora
RUN chmod -R 755 /home/fedora
RUN chmod 640 /home/fedora/.ssh/authorized_keys

RUN mkdir -p /srv/rpm-ostree/centos-atomic-host/7 && \
    mkdir -p /srv/repo/rpm

USER fedora

# Configure ZSH shell
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

# Configure go environment.
ENV GOPATH /home/fedora/go
ENV PATH $PATH:/home/fedora/go/bin

# Install Glide (Go package manager)
RUN curl https://glide.sh/get | sh && \
    mkdir -p $GOPATH/src/github.com/mh-cbon/go-bin-rpm && \
    mkdir -p $GOPATH/src/github.com/mh-cbon/go-bin-deb && \
    mkdir -p $GOPATH/src/github.com/mh-cbon/changelog && \
    mkdir -p $GOPATH/src/github.com/mh-cbon/emd && \
    mkdir -p $GOPATH/src/github.com/mh-cbon/gump && \
    mkdir -p $GOPATH/src/github.com/mh-cbon/gh-api-cli && \
    mkdir -p $GOPATH/src/local-persist 

# Install below packages as suggested in: https://github.com/mh-cbon/go-github-release

# Install rpm package builder
WORKDIR $GOPATH/src/github.com/mh-cbon/go-bin-rpm
RUN git clone https://github.com/mh-cbon/go-bin-rpm.git . && \
    glide install && \ 
    go install

# Install deb package builder
WORKDIR $GOPATH/src/github.com/mh-cbon/go-bin-deb
RUN git clone https://github.com/mh-cbon/go-bin-deb.git . && \
    glide install && \ 
    go install

# Install changelog maintainer
WORKDIR $GOPATH/src/github.com/mh-cbon/changelog
RUN git clone https://github.com/mh-cbon/changelog.git . && \
    glide install && \ 
    go install

# Install Enhanced Markdown template processor
WORKDIR $GOPATH/src/github.com/mh-cbon/emd
RUN git clone https://github.com/mh-cbon/emd.git . && \
    glide install && \
    go install

# Gump is an utility to bump your package using semver.
WORKDIR $GOPATH/src/github.com/mh-cbon/gump
RUN git clone https://github.com/mh-cbon/gump.git . && \
    glide install && \
    go install

# Package gh-api-cli is a command line utility to work with github api.
WORKDIR $GOPATH/src/github.com/mh-cbon/gh-api-cli
RUN git clone https://github.com/mh-cbon/gh-api-cli.git . && \
    glide install && \
    go install

# Install docker volume plugin: local-persist
WORKDIR $GOPATH/src/local-persist
RUN git clone https://github.com/KebinuChiousu/local-persist . && \
    glide install && \
    go install && \
    mkdir -p rpm && \
    mkdir -p build/amd64 && \
    mkdir -p pkg-build/amd64 && \
    cp $GOPATH/bin/local-persist ./build/amd64/docker-volume-local-persist

COPY config/rpm/docker-volume-local-persist/* $GOPATH/src/local-persist/rpm/
COPY config/rpm/docker-volume-local-persist/rpm.json $GOPATH/src/local-persist/
COPY config/rpm/docker-volume-local-persist/change.log $GOPATH/src/local-persist/

RUN go-bin-rpm test
RUN go-bin-rpm generate-spec -a amd64 --version 1.3.0
RUN go-bin-rpm generate -a amd64 --version 1.3.0 -b pkg-build/amd64 -o docker-volume-local-persist.rpm

USER root

VOLUME /etc/ssh
VOLUME /home/fedora
VOLUME /srv/repo
VOLUME /srv/rpm-ostree/centos-atomic-host/7
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
