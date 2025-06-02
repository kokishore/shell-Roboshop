#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo " Script is started execution at : $(date)" | tee -a $LOGS_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}


dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling the Default Node JS Module"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling the NodeJS 20 Version "

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS application"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOGS_FILE 
    VALIDATE $? "ROboshop User creation"
else 
    echo " Roboshop user is already created ..... $Y SKIPPING $N "
fi   

mkdir -p /app   
VALIDATE $? "Creating App Directory "  

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading the user"
cd /app

rm -rf /app/* 

unzip /tmp/user.zip  &>>$LOGS_FILE
VALIDATE $? " Unzipping the user"

npm install   &>>$LOGS_FILE
VALIDATE $? "Node JS Build Tool NPM Installation"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service  &>>$LOGS_FILE
VALIDATE $? "Copying the user service file "

systemctl daemon-reload
systemctl enable user 
systemctl start user

VALIDATE $? "user service enabling and starting"