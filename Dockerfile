FROM debian:bullseye
MAINTAINER ME

# Update package lists and upgrade packages
RUN apt-get update && apt-get upgrade -y

# Install required packages
RUN apt-get install -y \
    python3-pip \
    wget \
    software-properties-common \
    && pip3 install --upgrade pip

# Add i386 architecture and update package lists
RUN dpkg --add-architecture i386 \
    && apt-get update

# Install WineHQ stable package and dependencies
RUN apt-get install --install-recommends -y \
    # headless mono install
    xvfb \
    openbox \
    xterm \
    tigervnc-standalone-server

## WINEHQ
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wget gnupg software-properties-common && \
    # Add WineHQ repository
    wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key && \
    apt-add-repository https://dl.winehq.org/wine-builds/debian/ && \
    apt-get update && \
    # Install WineHQ stable version
    apt-get install -y winehq-stable && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## WINEHQ/>

# RUN echo 'exec openbox-session' > /root/.xinitrc; \
#     echo 'export WINE_MONO=disable' >> ~/.bashrc \
#     touch /root/.wine_no_dotnet

RUN ln -s /opt/zorro/install/ /zorro && \
    ln -s /opt/wine-stable/bin/wine /wine

# Initialize Wine environment (this creates /root/.wine)
RUN /opt/wine-stable/bin/wineboot -u && /opt/wine-stable/bin/wineboot --init || true

# Pre-configure Wine and disable GUI dialogs
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Set WINEPREFIX and WINEARCH for a 32-bit environment
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
#ENV WINEDEBUG=+all
RUN winecfg

### EXPERIMENT: install mono library, didn't work. Eventually used APPROACH2 and it works quite fast 33 seconds. 
#RUN apt-get update && apt install -y cabextract

# Use winetricks to install common libraries (e.g., vcrun2015, corefonts)
#RUN WINEPREFIX=/root/.wine2 WINE=/opt/wine-stable/bin/wine64 /usr/local/bin/winetricks -q dotnet462

# RUN wget https://aka.ms/vs/17/release/vc_redist.x64.exe -O /root/vc_redist.x64.exe && \
#     Xvfb :1 & DISPLAY=:1 /opt/wine-stable/bin/wine /root/vc_redist.x64.exe /quiet /norestart

# Set up virtual display and finalize Wine initialization
# RUN Xvfb :1 & DISPLAY=:1 /opt/wine-stable/bin/wineboot --init

# RUN WINEPREFIX=/root/.wine /opt/wine-stable/bin/wineboot && \
#     winetricks nocrashdialog && \
#     touch /root/.wine/dosdevices/c:/Program\ Files/Mono.dummy

# Download and silently install the latest Mono runtime
# RUN LATEST_MONO_URL=$(wget -qO- https://dl.winehq.org/wine/wine-mono/ | \
#         grep -oP 'href="\K[^"]*wine-mono-[\d.]+-x86.msi(?=")' | \
#         sort -V | tail -1) && \
#     MONO_VERSION=$(echo $LATEST_MONO_URL | grep -oP '[\d.]+(?=-x86)') && \
#     wget https://dl.winehq.org/wine/wine-mono/${LATEST_MONO_URL} -O wine-mono-latest.msi && \
#     wine msiexec /i wine-mono-latest.msi /qn && \
#     rm wine-mono-latest.msi
###

## APPROACH2: INSTALL MONO from https://gist.github.com/jensmeder/96e258c48d7ef0b3e828a453c2fc667f
RUN wget -P /mono http://dl.winehq.org/wine/wine-mono/4.9.4/wine-mono-4.9.4.msi
RUN wineboot -u && msiexec /i /mono/wine-mono-4.9.4.msi
RUN rm -rf /mono/wine-mono-4.9.4.msi

COPY start.sh /start.sh
COPY xstartup /root/.vnc/xstartup
RUN chmod +x /start.sh && chmod a+x /root/.vnc/xstartup

RUN apt update && apt install -y xclip && echo ". /work/zorro/xload" > ~/.bashrc

# VOLUME /opt/zorro
EXPOSE 5901
CMD /start.sh
