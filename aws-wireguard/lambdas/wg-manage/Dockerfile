FROM public.ecr.aws/lambda/python:3.9

#Install wireguard tools, needed to pre-generate keys
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN curl -o /etc/yum.repos.d/jdoss-wireguard-epel-7.repo \
    https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
RUN yum install -y wireguard-dkms wireguard-tools

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}
RUN find . -type f -exec chmod 755 {} \;
# Install the function's dependencies using file requirements.txt
# from your project folder.
COPY requirements.txt  .
RUN  pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "app.handler" ]