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
    echo -e " you are running  with root access" | tee -a $LOG_FILE
fi
# validate functions takes input as exit status,what commands they tried to install
VALIDATE(){
if [ $1 -eq 0 ]
then
    echo -e "$2 is --- $G SUCCESS $N" | tee -a $LOG_FILE
else
    echo -e "$2 is --- $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
fi
}
dnf module list nodejs &>>$LOG_FILE
VALIDATE $? "listing nodejs"

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"

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

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip 
VALIDATE $? "unzipping catalogue"

npm install  # installing dependencies 
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying  catalogue serice"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue 
VALIDATE $? "starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y 
VALIDATE $? "Installing mongodb client"

#Data base is exit or not to check mongodb
STATUS=$(mongosh --host mongodb.tadikondadevops.site --eval 'db.getMongo().getDBNames().indexof("catalogue")')

if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.tadikondadevops.site </app/db/master-data.js 
    VALIDATE $? "Loading data into  mongodb"
else    
    echo -e "Data is already loaded ---- $Y SKIPPING $N"
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed sucessfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
