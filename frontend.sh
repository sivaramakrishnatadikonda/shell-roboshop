#!/bin/bash
START_TIME=$(date +%s)
END_TIME=$(date +%s)
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

dnf module list nginx &>>$LOG_FILE
VALIDATE $? "listing nginx server"

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling nginx:1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx server"

systemctl enable nginx 
VALIDATE $? "enabling nginx"

systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "remove root directory file"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "unzip frontend code"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "coping nginx.conf"

systemctl restart nginx  &>>$LOG_FILE
VALIDATE $? "restarting nginx"

TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed sucessfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE