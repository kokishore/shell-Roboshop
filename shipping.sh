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
dnf install maven -y &>>$LOGS_FILE
VALIDATE $? " Installing Maven"

id roboshop
if [ $? -ne 0 ]
then 
    echo " Creating Roboshop User "
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
else
    echo " Roboshop user is already exists"
fi

rm -rf /app/*
mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading the Shipping module"

cd /app  
unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? " Unzipping the shipping module "


mvn clean package  &>>$LOGS_FILE
VALIDATE $? " Packing the application"
mv target/shipping-1.0.jar shipping.jar  &>>$LOGS_FILE
VALIDATE $? "moving the target file to shippingJAR file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &>>$LOGS_FILE
VALIDATE $? "Copying the shipping service file "

systemctl daemon-reload  &>>$LOGS_FILE
VALIDATE $? "Daemon reloading"

systemctl enable shipping  &>>$LOGS_FILE
VALIDATE $? "Enabling shipping"
systemctl start shipping  &>>$LOGS_FILE
VALIDATE $? "Start shipping"

dnf install mysql -y  &>>$LOGS_FILE
VALIDATE $? " Installing Mysql"

mysql -h 172.31.45.192 -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
mysql -h 172.31.45.192 -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOGS_FILE
mysql -h 172.31.45.192 -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
VALIDATE $? "Loading data into MySQL"


systemctl restart shipping &>>$LOGS_FILE
VALIDATE $? "Restart shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOGS_FILE

