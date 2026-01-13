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


dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "installing mysql-server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enabling mysqld"

systemctl start mysqld  &>>$LOG_FILE
VALIDATE $? "starting mysqld"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD
VALIDATE $? "starting mysqld"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed sucessfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE 