#!/bin/bash
START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m" 
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started executing at : $(date)" | tee -a $LOG_FILE
# check the user has root priveleges or not 
if [ $USERID != 0 ]
then    
    echo -e "$R ERROR:: please run the script with root access $N" | tee -a $LOG_FILE
    exit 1 # give other than 0 upto 127
else
    echo -e "$G you are running the script with root access $N" | tee -a $LOG_FILE
fi

echo "please enter rabbitmq password to setup"
read -s RABBITMQ_PASSWORD  # RoboShop@1

# validate functions takes input as exit status,what commands they tried to install
VALIDATE(){
if [ $1 -eq 0 ]
then
    echo -e "$2 is ---- $G SUCCESS $N" | tee -a $LOG_FILE
else
    echo -e "$2 is ---- $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
fi
}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "copy rabbitmq repo" 

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbitmq servers" | tee -a $LOG_FILE

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabling rabbitmq-server" | tee -a $LOG_FILE

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "startring  rabbitmq-server" | tee -a $LOG_FILE



rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD #roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"



