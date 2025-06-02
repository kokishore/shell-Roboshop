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

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading the Catalogue"
cd /app

rm -rf /app/* 

unzip /tmp/catalogue.zip  &>>$LOGS_FILE
VALIDATE $? " Unzipping the catalogue"

npm install   &>>$LOGS_FILE
VALIDATE $? "Node JS Build Tool NPM Installation"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service  &>>$LOGS_FILE
VALIDATE $? "Copying the catalogue service file "

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue

VALIDATE $? "catalogue service enabling and starting"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo  &>>$LOGS_FILE
VALIDATE $? "Copying the data of MongoDB"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB"

STATUS=$(mongosh --host 172.31.38.208 --eval 'db.getMongo().getDBNames().indexOf("catalogue")')  &>>$LOGS_FILE
if [ $STATUS -lt 0 ]
then
    mongosh --host 172.31.91.253 </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi


