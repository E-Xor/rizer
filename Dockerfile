FROM ubuntu:14.04

# Install dependencies
# RUN apt-get update -y
RUN apt-get install -y git

# Clone repo
RUN mkdir ~/docker_test
RUN git clone https://github.com/E-Xor/rizer ~/docker_test

CMD bash
