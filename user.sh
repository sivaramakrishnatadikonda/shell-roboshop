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

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "system roboshop already created ----- $Y skipping $N"
fi

mkdir -p  /app 
VALIDATE $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "Downloading user"

rm -rf /app/* # remove the app directory content
cd /app 
unzip /tmp/user.zip
VALIDATE $? "Unzipping user"

npm install &>>$LOG_FILE # installing dependencies 
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "copying  user.serice"

systemctl daemon-reload
VALIDATE $? "daemon-reloading"

systemctl enable user 
VALIDATE $? "enabling user"

systemctl start user
VALIDATE $? "starting user"

TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed sucessfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE