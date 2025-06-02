#!/bin/bash
START_TIME=$(date +%s)
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


dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing the python3"


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

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading the cart"

rm -rf /app/*

cd /app
unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping Payment module"

pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? " Installing Pip3 and Requirements"

cp $SCRIPT_DIR/payment.sh /etc/systemd/system/payment.service &>>$LOGS_FILE

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Daemon Reloading "

systemctl enable payment &>>$LOGS_FILE
VALIDATE $? "Enbling Payment"
systemctl start payment &>>$LOGS_FILE
VALIDATE $? " Starting Payment"

ND_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

