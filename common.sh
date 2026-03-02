#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-common-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
Mongodb_Host=mongodb.sowjanya.fun
start_time=$(date +%s)
Mysql_Host=mysql.sowjanya.fun

mkdir $LOGS_FOLDER

echo "$(date "+%Y-%m-%d %H:%M:%S") script started execution at: $start_time" | tee -a $LOGS_FILE

check_root() {
if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi
}

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$(date "+%Y-%m-%d %H:%M:%S") $2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$(date "+%Y-%m-%d %H:%M:%S") $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

nodejs_setup() {
    dnf module disable nodejs -y &>>$LOGS_FILE
    VALIDATE $? "Disabling NodeJS Default version"

    dnf module enable nodejs:20 -y &>>$LOGS_FILE
    VALIDATE $? "Enabling NodeJS 20"

    dnf install nodejs -y &>>$LOGS_FILE
    VALIDATE $? "Install NodeJS"

    npm install  &>>$LOGS_FILE
    VALIDATE $? "Installing dependencies"
}

app_setup() {
    id roboshop &>>$LOGS_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
        VALIDATE $? "Creating system user"
    else
        echo -e "Roboshop user already exist ... $Y SKIPPING $N"
    fi

    mkdir -p /app 
    VALIDATE $? "Creating app directory"

    curl -o /tmp/$module.zip https://roboshop-artifacts.s3.amazonaws.com/$module-v3.zip  &>>$LOGS_FILE
    VALIDATE $? "Downloading $module code"

    cd /app
    VALIDATE $? "Moving to app directory"

    rm -rf /app/*
    VALIDATE $? "Removing existing code"

    unzip /tmp/$module.zip &>>$LOGS_FILE
    VALIDATE $? "Uzip $module code"
}
    system_setup() {

    cp $SCRIPT_DIR/$module.service /etc/systemd/system/$module.service
    VALIDATE $? "Created systemctl service"

    systemctl daemon-reload
    systemctl enable $module  &>>$LOGS_FILE
    systemctl start $module
    VALIDATE $? "Starting and enabling $module"
}

java_setup() {
    dnf install maven -y &>>$LOGS_FILE
    VALIDATE $? "Installing Maven"

    cd /app 
    mvn clean package &>>$LOGS_FILE
    VALIDATE $? "Installing and Building shipping"

    mv target/shipping-1.0.jar shipping.jar 
    VALIDATE $? "Moving and Renaming shipping"
}

python_setup() {
    dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
    VALIDATE $? "Installing Python"

    cd /app 
    pip3 install -r requirements.txt &>>$LOGS_FILE
    VALIDATE $? "Installing dependencies"

}

restart_setup() {
    systemctl restart $module
    VALIDATE $? "Restarting $module"
}

run_time() {
    end_time=$(date +%s)
    run_time=$(( $end_time - $start_time ))
    echo "$(date "+%Y-%m-%d %H:%M:%S") total time taken to execute script: $run_time" | tee -a $LOGS_FILE
}