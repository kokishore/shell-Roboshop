#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log

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

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying the mongos repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing mongodb"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling mongod"

systemctl start mongod  &>>$LOGS_FILE
VALIDATE $? "starting mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongo.conf
VALIDATE $? " Enabling access to remote server"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting mongod"
