## AirFlow - Docker Composer , AWS SQS , AWS EFS , AWS RDS ( MySQL )

##### Prerequisits

* AWS Pem Key 
* One VPC with 3 subnets in 3 different availablity zone. 
* One EIP
* AWS IAM account with Administrative privileges, AWS access / secret key. 

#

Considerting the AWS Account has below informations

> VPC - VPC-1000
> Subnet - subnet-1001 , subnet-1002, subnet-1001 ,subnet-1003
> EIP association = eipalloc-001
> AWS KeyPair : airflow 


#
### Terrafrom Init
#

Under Terraform folder run ```terraform init```. This init will pull and generate terraform execution using localhost. In order to use remote storage please check backend.tf file and configure it, then run ```terraform init``` again.

by default terraform will pull workscpace as ```default``` and add this end of the resources. 

### Terrafrom Workspace Create
#
    export TF_VAR_env=test
    terraform workspace select $TF_VAR_env || terraform workspace new $TF_VAR_env

### Export Starting Variables
#
    export TF_VAR_AMI="ami-0b44582c8c5b24a49" 
    export TF_VAR_INSTANCE_TYPE="t2.xlarge"
    export TF_VAR_KEY_NAME="airflow"
    export TF_VAR_VPC="vpc-001"
    export TF_VAR_SUBNET="subnet-1001"
    export TF_VAR_RDS_SUBNET='["subnet-1001","subnet-1001","subnet-1003"]'
    export TF_VAR_EIP_ASSOCIATION="eipalloc-0531ed5cb54b003f2"
    export TF_VAR_SQS_NAME="AirPoc-SQS-System-$TF_VAR_env.fifo"
    export TF_VAR_AWS_ACCOUNT="29**********82"
    export TF_VAR_AWS_REGION="ap-southeast-1"
    export TF_VAR_TAGS='{"Name"="AirFlow-'$TF_VAR_env'","Environment"="'$TF_VAR_env'"}'
    export TF_VAR_MASTER_USERNAME="admin"
    export TF_VAR_MASTER_PASSWORD="UK766AU3GJC"
    export TF_VAR_DATABASE_NAME="airflow"
    export MHAIP=['"'"$(curl ifconfig.me)/32"'"']
    export TF_VAR_MHAIP=['"'"$(curl ifconfig.me)/32"'"']

### Terraform Plan > Check > Apply
#
    terraform plan
    terraform apply --auto-approve

    ### Attention ####
    Its a bug that airflow configuration don't support / 
    
    terraform output SecretKey
    Makesure terraform SecretKey dont contains / . Example below. If you see / inside the secret key just delete from aws portal and run terraform again. You may may need to continue this process one or sometime more than 2 times to get a key without /.

    NejOKmya/D5O7B+5BVadfHfTNaw1DexXw8y91PMt [ Not accepted ]
    5fXAUqpNqzEQswS6Ai26QbqaM9RoDQWqI46bDGlo [ Ok ]

> Once Terraform Completed

    export Result_AccessKey=$(terraform output AccessKey)
    export Result_Instance_Public_IP=$(terraform output Instance_Public_IP)
    export Result_RDS=$(terraform output RDS)
    export Result_SecretKey=$(terraform output SecretKey)
    export Result_EFS=$(terraform output EFS)

> cd ../Docker-Compose/

    echo "AIRFLOW__CORE__SQL_ALCHEMY_CONN=mysql://$TF_VAR_MASTER_USERNAME:$TF_VAR_MASTER_PASSWORD@$Result_RDS/$TF_VAR_DATABASE_NAME" >> .env.$TF_VAR_env
    echo "AIRFLOW__CELERY__RESULT_BACKEND=db+mysql://$TF_VAR_MASTER_USERNAME:$TF_VAR_MASTER_PASSWORD@$Result_RDS:3306/$TF_VAR_DATABASE_NAME" >> .env.$TF_VAR_env
    echo "AIRFLOW__CELERY__BROKER_URL=sqs://$Result_AccessKey:$Result_SecretKey@ap-southeast-1.queue.amazonaws.com/$TF_VAR_AWS_ACCOUNT/$TF_VAR_SQS_NAME" >> .env.$TF_VAR_env
    echo "AIRFLOW__CELERY__DEFAULT_QUEUE=$TF_VAR_SQS_NAME" >> .env.$TF_VAR_env
    echo "AIRFLOW__CORE__DAGS_FOLDER=/root/airflow/dags" >> .env.$TF_VAR_env
    echo "AIRFLOW_LOAD_EXAMPLES=no" >> .env.$TF_VAR_env
    echo "AIRFLOW__CORE__LOAD_EXAMPLES=False" >> .env.$TF_VAR_env
    echo "AIRFLOW__SCHEDULER__DAG_DIR_LIST_INTERVAL=10" >> .env.$TF_VAR_env
    echo "AIRFLOW__CORE__EXECUTOR=CeleryExecutor" >> .env.$TF_VAR_env
    echo "AWS_DEFAULT_REGION=ap-southeast-1" >> .env.$TF_VAR_env

> cd ../Ansible/

``` ! adjust ansible hosts file for connection and copy the pem key inside this folder. Set permission chmod 600 to pem file```

    ansible-playbook -i hosts playbook.yaml --tag FullSetup --extra-vars "mount_dns=$Result_EFS env=$TF_VAR_env"

Initiate Airflow Database

## Once the deployment complete 
### SSH ec2 instance ( ssh -i <pem>.pem ubuntu@<ip> )
    sudo su - 
    cp -a  AirFlow/Docker-Compose/ /tmp/ 
    cd /tmp/Docker-Compose/ 
    cp ContainerImage/Dockerfile . 
    # From Dockerfile remove last 2 lines ( 17 , 18 Entrypoint and cmd )  
    docker build . -t console 
    [ .env.dev can be different depends on what value you setup in terraform workspace. if any error please ls and check which file exists]
    docker run --env-file=.env.dev -it console /bin/bash 
    airflow initdb 
    exit 
    docker rmi -f console
## Exit from ec2

ansible-playbook -i hosts playbook.yaml --tag startAirFlow --extra-vars "mount_dns=$Result_EFS env=$TF_VAR_env"