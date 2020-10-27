FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install build-essential \
            libmysqlclient-dev \
            libcurl4-openssl-dev \
	    libssl-dev \
            python3-pip -y 

RUN mkdir -p /root/airflow/dags/
RUN pip3 install  apache-airflow==1.10.12  --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-1.10.12/constraints-3.7.txt"
RUN pip3 install 'apache-airflow[mysql]'
RUN pip3 install celery[sqs]
RUN pip3 install 'apache-airflow[celery]'
RUN rm -rf /root/.cache/*
EXPOSE 8080/tcp 5555/tcp 8793/tcp

ENTRYPOINT ["airflow"]
CMD ["webserver"]
