# 🛠 Serverless IoT Sensor Dashboard

This project aims to develop a serverless IoT data processing and visualization system leveraging cloud computing. Using AWS Lambda/OpenFaaS, MQTT, and NoSQL databases, the system will process and store IoT data in real time. The processed data will be visualized using a web dashboard (Grafana/Streamlit) for real-time analytics. The idea is to demonstrate the scalability and cost-effectiveness of serverless architectures for IoT applications.

---

## ✅ Tools Used:

* Amazon Linux (via EC2 + PuTTY)
* Python with Flask, Streamlit, paho-mqtt
* MQTT Broker (Mosquitto) – for data transfer
* AWS Lambda – for serverless processing
* DynamoDB – to store sensor data

---

## Components
- **sensor_simulator.py**: Simulates IoT sensor data.
- **lambda_function.py**: AWS Lambda function to store data into DynamoDB.
- **app.py**: Flask API to retrieve stored data.
- **dashboard.py**: Streamlit dashboard to visualize the data.

---

## 🚀 Execution

### 🔐 Step 1: Launch and Connect to Amazon Linux EC2 (with PuTTY)

#### 📦 A. Launch EC2 Instance

1. Go to the [AWS EC2 Console](https://console.aws.amazon.com/ec2).

2. Click "Launch Instance".

3. Choose Amazon Linux 2 (Free tier eligible).

4. Select t2.micro instance type.

5. Under Configure Security Group:

   * Add rules to allow:

     * SSH (22) – for PuTTY
     * HTTP (80) – for web access
     * Custom TCP 5000 – for Flask
     * Custom TCP 8501 – for Streamlit

6. Launch the instance and *download the .pem file* (key pair).

---

#### 🔌 B. Connect to EC2 with PuTTY

1. Open PuTTY.
2. In Host Name, enter: ec2-XX-XX-XX-XX.compute.amazonaws.com
3. Go to Connection > SSH > Auth and browse for your .ppk key (convert .pem using PuTTYgen).
4. Click Open to connect.

---

### ⚙ Step 2: Set Up Your Environment

#### 🧰 A. Install Tools on EC2

Run the following commands one by one after logging into your EC2:

bash
sudo yum update -y
sudo yum install python3 -y
sudo yum install git -y


#### 🧪 B. Install Python Libraries

bash
pip3 install flask boto3 streamlit paho-mqtt requests


---

### 🔄 Step 3: Install & Start MQTT Broker (Mosquitto)

bash
sudo yum install mosquitto -y
sudo systemctl start mosquitto
sudo systemctl enable mosquitto


Check if it's running:

bash
sudo systemctl status mosquitto


---

### 🧪 Step 4: Run the Sensor Simulator

1. Copy your sensor_simulator.py to EC2 using SCP or manually.
2. Edit the file if needed (with nano):

bash
nano sensor_simulator.py


3. Run the script:

bash
nohup python3 sensor_simulator.py &


💡 This will keep sending fake sensor data every 5 seconds using MQTT.

---

### ☁ Step 5: Set Up AWS Lambda & DynamoDB

#### A. Create DynamoDB Table

1. Go to AWS Console > DynamoDB
2. Create Table:

   * Name: IoTData
   * Partition Key: timestamp (String)

#### B. Create SNS Topic

1. Go to AWS SNS Console
2. Create a topic: Name it IoTTopic.

#### C. Create Lambda Function

1. Go to AWS Lambda Console
2. Create function from scratch: IoTStoreFunction
3. Choose Python 3.x runtime.
4. Add lambda_function.py code.
5. Give the Lambda permissions to write to DynamoDB.
6. Add SNS trigger using IoTTopic.

---

### 🌐 Step 6: Run the Flask API Server

1. Copy app.py to EC2.
2. Run the API:

bash
nohup python3 app.py &


3. Access from browser:

   
   http://<your-ec2-public-ip>:5000/data
   

📌 Make sure port 5000 is open in EC2's security group.

---

### 📊 Step 7: Run Streamlit Dashboard

1. Copy dashboard.py to EC2.
2. Edit the API URL in the file:

python
API_URL = "http://<your-ec2-public-ip>:5000/data"


3. Start dashboard:

bash
streamlit run dashboard.py


4. Open in browser:


http://<your-ec2-public-ip>:8501


📌 Port 8501 must be allowed in security group.

---