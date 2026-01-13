#!/bin/bash
USERID=$(id-u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG-FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script started executing at : $(date)" | tee -a $LOG_FILE
# check the user has root priveleges or not 
if [ $USERID -ne 0 ]
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
cp mongo.rep /etc/yum.repos.d/mongo.repo 
VALIDATE $? "copy mongo.repo" 
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb servers" | tee -a $LOG_FILE
systemctl enable mongod  &>>$LOG_FILE
VALIDATE $? "Enabling mongodb" | tee -a $LOG_FILE
systemctl start mongod  &>>$LOG_FILE
VALIDATE $? "Starting mongodb" | tee -a $LOG_FILE
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "editing mongodb.conf file for remote connections" | tee -a $LOG_FILE
systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restarting mongodb" | tee -a $LOG_FILE