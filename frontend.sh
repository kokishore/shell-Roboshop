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

dnf module disable nginx -y  &>>$LOGS_FILE
VALIDATE $? " Disabling the default  Nginx"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "Enabling the Nginx 1.24"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? " Installing Nginx Web server "

systemctl enable nginx  &>>$LOGS_FILE
systemctl start nginx 

VALIDATE $? "Enabling and starting the Nginx"

rm -rf /usr/share/nginx/html/*  &>>$LOGS_FILE
VALIDATE $? "Removing the Default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading the Frontend end code from S3 Bucket "

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping the Frontend content to the HTML folder"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOGS_FILE


systemctl restart nginx  &>>$LOGS_FILE
VALIDATE $? " Restarting the NGINX "