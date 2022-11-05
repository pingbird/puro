FROM ubuntu
RUN apt update -y; apt install -y curl git unzip bc build-essential snapd sudo
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
RUN echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /root/.profile
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.profile
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
ADD ./* $HOME/