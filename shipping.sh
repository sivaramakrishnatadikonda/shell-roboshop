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

echo "please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD
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

dnf install maven -y
VALIDATE $? "Installing maven"

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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip  &>>$LOG_FILE
VALIDATE $? "unzipping shipping"


mvn clean package &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "moving and renaming  jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copying  catalogue serice"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping  &>>$LOG_FILE
systemctl start shipping  &>>$LOG_FILE
VALIDATE $? "starting shipping"


dnf install mysql -y 
VALIDATE $? "Installing mysql client"
mysql -h mysql.tadikondadevops.site -u root -p$MYSQL_ROOT_PASSWORD 'use cities'
if [ $? -ne 0 ]
then
mysql -h mysql.tadikondadevops.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql
mysql -h mysql.tadikondadevops.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
mysql -h mysql.tadikondadevops.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
else
    echo -e "Data is already loaded into MYSQL  --- $Y SKIPPING $N"
fi
systemctl restart shipping
VALIDATE $? "Restart shipping"



END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed sucessfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE