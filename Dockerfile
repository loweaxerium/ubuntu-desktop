FROM ubuntu:16.04

ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 17.12.0-ce
ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex bison libxml2-dev dpkg-dev libcap-dev"

RUN set -ex; \
	sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list; \
	apt-get -y update; \
	apt-get -yy install \ 
		sudo \
		apt-utils \
		software-properties-common \
		vim \
		wget \
		ca-certificates \
    	xfce4 \
		xfce4-terminal \
		xfce4-screenshooter \
		xfce4-taskmanager \
    	xfce4-clipman-plugin \
		xfce4-cpugraph-plugin \
		xfce4-netload-plugin \
    	xfce4-xkb-plugin \
		xauth \
		supervisor \
		uuid-runtime \
		pulseaudio \
		locales \
    	firefox \
		pepperflashplugin-nonfree \
		openssh-server \
    	$BUILD_DEPS \
	; \
	# Build xrdp
	cd /tmp; \
	apt-get source pulseaudio; \
	apt-get build-dep -yy pulseaudio; \
	cd /tmp/pulseaudio-8.0; \
	dpkg-buildpackage -rfakeroot -uc -b; \
	cd /tmp; \
	git clone --branch v0.9.4 --recursive https://github.com/neutrinolabs/xrdp.git; \
	cd /tmp/xrdp; \
	./bootstrap; \
	./configure; \
	make; \
	make install; \
	cd /tmp/xrdp/sesman/chansrv/pulse; \
	sed -i "s/\/tmp\/pulseaudio\-10\.0/\/tmp\/pulseaudio\-8\.0/g" Makefile; \
	make; \
	cp *.so /usr/lib/pulse-8.0/modules/; \
	# Build xorgxrdp
	cd /tmp; \
	git clone --branch v0.2.4 --recursive https://github.com/neutrinolabs/xorgxrdp.git; \
	apt-get -yy install xserver-xorg-dev; \
	cd /tmp/xorgxrdp; \
	./bootstrap; \
	./configure; \
	make; \
	make install; \
	# Configure
	mkdir /var/run/dbus; \
	cp /etc/X11/xrdp/xorg.conf /etc/X11; \
	sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini; \
	locale-gen en_US.UTF-8; \
	echo "xfce4-session" > /etc/skel/.Xclients; \
	cp -r /etc/ssh /ssh_orig; \
	rm -rf /etc/ssh/*; \
	rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem; \
	ln -fs /usr/share/zoneinfo/America/Mexico_City /etc/localtime; \
	dpkg-reconfigure -f noninteractive tzdata; \
	# Chrome
	cd /; \
	wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -; \
    echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list; \
    apt-get -y update; \
	apt-get -yy install google-chrome-stable; \
    # Docker
	osArch="$(uname -m)"; \
	case "$osArch" in \
		x86_64) dockerArch='x86_64' ;; \
		aarch64) dockerArch='aarch64' ;; \
		ppc64le) dockerArch='ppc64le' ;; \
		s390x) dockerArch='s390x' ;; \
		*) echo >&2 "error: unsupported architecture ($osArch)"; exit 1 ;;\
	esac; \
    wget -qO- "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz" | \
    tar --extract \
        --verbose \
		--strip-components 1 \
        --gzip \
		--directory /usr/local/bin/ \
	; \
	# Clean 
	cd /; \
	apt-get -yy remove xscreensaver; \
	apt-get -yy remove $BULD_DEPS; \
	apt-get -yy autoremove; \
	apt-get -yy clean; \
	rm -rf /var/lib/apt/lists/*; \
	rm -rf /tmp/*; \
	# Add user
	addgroup ubuntu; \
	useradd -m -s /bin/bash -g ubuntu ubuntu; \
	echo "ubuntu:ubuntu" | /usr/sbin/chpasswd; \
	echo "ubuntu    ALL=(ALL) ALL" >> /etc/sudoers; \
	usermod -G 100 ubuntu

ADD bin /usr/bin
ADD etc /etc

# Docker config
VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]

    
