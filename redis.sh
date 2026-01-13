#!/bin/bash
START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m" 
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="var/log/roboshop-logs"
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
# validate functions takes input as exit status,what commands they tried to install
VALIDATE(){
if [ $1 -eq 0 ]
then
    echo -e "$G $2 sucessfully Install $N" | tee -a $LOG_FILE
else
    echo -e "$R $2 failure $N" | tee -a $LOG_FILE
    exit 1
fi
}

dnf module disable redis -y
VALIDATE $? "disabling redis"

dnf module enable redis:7 -y
VALIDATE $? "enabling redis:7"

dnf install redis -y 
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "change protected-mode yes to no and provide firewall allow all in  redis config"

systemctl enable redis 
VALIDATE $? "enabling redis"

systemctl start redis 
VALIDATE $? "starting redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed sucessfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE