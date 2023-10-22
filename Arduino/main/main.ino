#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "secrets.h"
#include <WiFiClientSecure.h>
#include "WiFi.h"

//comment in which device configuration should be loaded
//#include "strategy_manual.h"
//#include "strategy_auto_one.h"
//#include "strategy_auto_two.h"

#define WATER_PIN 4
#define MOISTURE_PIN 34

WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);

void setup() {
  connectToWIFI();
  connectToAWS();

  //KYES516
  pinMode(MOISTURE_PIN, INPUT);
  //MAGNET_VENTIL
  pinMode(WATER_PIN, OUTPUT);
}



void connectToAWS() {
  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);
  client.setCallback(callback);

  Serial.println("Connecting to AWS IOT");

  while (!client.connect(THINGNAME)) {
    Serial.print(".");
    delay(100);
  }

  if (!client.connected()) {
    Serial.println("AWS IoT Timeout!");
    return;
  }

  client.subscribe(AWS_IOT_SUBSCRIBE_TOPIC);

  Serial.println("AWS IoT Connected!");
}

unsigned long previousMillis = 0;
long interval = 60000;
void loop() {
  if (reConnectIfConnectionIsLost()) {
    client.loop();
    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis;

      publishMessage();
    }
  }
}

void publishMessage() {
  Serial.println("Try sending message.");
  StaticJsonDocument<200> doc;
  DHT.read();
  doc["moisture"] = analogRead(MOISTURE_PIN);

  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  client.publish(AWS_IOT_PUBLISH_TOPIC, jsonBuffer);
}

void connectToWIFI() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  uint8_t restart_device = 0;
  while(WiFi.status() != WL_CONNECTED) {
    Serial.println("Connecting to Wi-Fi");

    uint8_t timeout_wifi = 10;
    while (timeout_wifi && (WiFi.status() != WL_CONNECTED)) {
      delay(500);
      Serial.print(".");
      timeout_wifi--;
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("Connected to Wi-Fi");
    } else {
      Serial.println("Connect to Wi-Fi failed, will retry.");
      WiFi.reconnect();
      if (restart_device++==3){
        ESP.restart();
      }
    }
  }
}

bool reConnectIfConnectionIsLost() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Connecting to Wi-Fi");

    WiFi.reconnect();

    uint8_t timeout_wifi = 8;
    while (timeout_wifi && (WiFi.status() != WL_CONNECTED)) {
      delay(500);
      Serial.print(".");
      timeout_wifi--;
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("Wi-Fi reconnected");
    } else {
      Serial.println("Wi-Fi reconnect failed");
      return false;
    }
  }

  if (!client.connected()) {
    Serial.println("MQTT reconnect...");
    client.setCallback(callback);
    while (!client.connected()) {
      client.connect(THINGNAME);
      uint8_t timeout_mqtt = 8;
      while (timeout_mqtt && (!client.connected())) {
        Serial.println("Retry...");
        timeout_mqtt--;
        delay(500);
      }
      if (client.connected() && client.subscribe(AWS_IOT_SUBSCRIBE_TOPIC)) {
        Serial.println("MQTT reconnected");
        return true;
      } else {
        Serial.println("MQTT reconnect failed");
        return false;
      }
    }
  }
  return true;
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("incoming: ");
  Serial.println(topic);

  StaticJsonDocument<200> doc;
  deserializeJson(doc, payload);
  long delay_time = doc["delay_time"];
  long watering_count = doc["watering_count"];

  for (int i = 0; i < watering_count; i++) {
    digitalWrite(WATER_PIN, HIGH);
    delay(delay_time);
    digitalWrite(WATER_PIN, LOW);
  }
}