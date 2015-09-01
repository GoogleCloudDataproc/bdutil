FROM google/cloud-sdk

ADD . /bdutil/

ENTRYPOINT ["/bdutil/bdutil"]
CMD ["--help"]
