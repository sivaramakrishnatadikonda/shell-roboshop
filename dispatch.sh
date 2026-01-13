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


dnf install golang -y
VALIDATE $? "installing golang"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "system roboshop already created ----- $Y skipping $N"
fi


mkdir -p  /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading dispatch"

rm -rf /app/*
cd /app 
unzip /tmp/dispatch.zip  &>>$LOG_FILE
VALIDATE $? "unzipping dispatch"


go mod init dispatch &>>$LOG_FILE
go get &>>$LOG_FILE
go build &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "copying  dispatch serice"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable dispatch  &>>$LOG_FILE
systemctl start dispatch  &>>$LOG_FILE
VALIDATE $? "starting dispatch"

