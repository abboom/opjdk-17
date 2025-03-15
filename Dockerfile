FROM ubuntu:24.04

RUN set -x; buildDeps='gcc libc6-dev make wget' \
    && apt-get update \
    && apt-get install -y $buildDeps \
    && apt install -y build-essential \
    && apt install -y git \
    && apt install -y cmake \
    && apt install -y libxml2 libxml2-dev libxslt-dev \
    && apt install -y libgd-dev  libgeoip-dev

RUN wget -O pcre2.tar.gz "github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-10.42.tar.gz" \
    && mkdir -p /usr/src/pcre2 \
    && tar -xzf pcre2.tar.gz -C /usr/src/pcre2 --strip-components=1 \
    && rm -rf pcre2.tar.gz \
    && wget -O zlib.tar.gz "https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz" \
	  && mkdir -p /usr/src/zlib \
	  && tar -xzf zlib.tar.gz -C /usr/src/zlib --strip-components=1 \
	  && rm -rf zlib.tar.gz \
	  && wget -O openssl.tar.gz "http://www.openssl.org/source/openssl-1.1.1v.tar.gz" \
	  && mkdir -p /usr/src/openssl \
	  && tar -xzf openssl.tar.gz -C /usr/src/openssl --strip-components=1 \
	  && rm -rf openssl.tar.gz \
	  && wget -O nginx-1.24.0.tar.gz "https://nginx.org/download/nginx-1.24.0.tar.gz" \
	  && mkdir -p /usr/src/nginx \
	  && tar -xzf nginx-1.24.0.tar.gz -C /usr/src/nginx --strip-components=1 \
	  && rm -rf nginx-1.24.0.tar.gz

RUN cd /usr/src \
	&& git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli \
	&& cd ngx_brotli/deps/brotli \
	&& mkdir out && cd out \
	&& cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed .. \
	&& cmake --build . --config Release --target brotlienc

RUN cd /usr/src \
	&& git clone https://github.com/arut/nginx-rtmp-module.git

RUN cd /usr/src/nginx \
	&& ./configure \
  --with-cc-opt='-g -O2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -ffile-prefix-map=/build/nginx-DlMnQR/nginx-1.24.0=. -flto=auto -ffat-lto-objects -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -fdebug-prefix-map=/build/nginx-DlMnQR/nginx-1.24.0=/usr/src/nginx-1.24.0-2ubuntu7.1 -fPIC -D_FORTIFY_SOURCE=3' \
	--prefix=/etc/nginx \
	--pid-path=/run/nginx.pid \
	--conf-path=/etc/nginx/nginx.conf \
  --sbin-path=/usr/sbin/nginx \
  --pid-path=/var/run/nginx.pid \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --with-pcre=/usr/src/pcre2 \
	--with-zlib=/usr/src/zlib \
	--with-openssl=/usr/src/openssl \
  --prefix=/usr/share/nginx \
  --http-log-path=/var/log/nginx/access.log \
	--error-log-path=stderr \
	--lock-path=/var/run/nginx.lock \
	--modules-path=/usr/lib/nginx/modules \
  --with-stream \
  --with-stream_ssl_preread_module \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-compat \
	--with-debug \
	--with-pcre-jit \
  --with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-http_v2_module \
	--with-http_dav_module \
	--with-http_slice_module \
	--with-threads \
  --with-http_addition_module \
	--with-http_flv_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_mp4_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_sub_module \
	--with-mail_ssl_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--with-stream_realip_module \
	--with-http_geoip_module=dynamic \
	--with-http_image_filter_module=dynamic \
  --with-http_xslt_module=dynamic \
	--with-mail=dynamic \
	--with-stream=dynamic \
	--with-stream_geoip_module=dynamic \
  --add-module=/usr/src/nginx-rtmp-module \
	--add-module=/usr/src/ngx_brotli \
  && make \
  && make install \
  && apt-get purge -y --auto-remove $buildDeps \
  && rm -rf /usr/src/pcre2 \
  && rm -rf /usr/src/zlib \
  && rm -rf /usr/src/openssl \
  && rm -rf /usr/src/nginx \

RUN echo "[Unit]\nDescription=The NGINX HTTP and reverse proxy server\nAfter=network.target\n\n[Service]\nUser=root\nExecStartPre=/usr/bin/rm -f /run/nginx.pid\nExecStart=/usr/sbin/nginx -c $NGX_CONF_FILE\nExecReload=/bin/kill -s HUP $MAINPID\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/nginx.service

ADD /nginx /etc/nginx
ADD /html /usr/share/nginx/html

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]