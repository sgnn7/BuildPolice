#include <SPI.h>
#include <Ethernet.h>

byte mac[] = { 
  0x00, 0xCD, 0xEF, 0xAB, 0xCD, 0xEF };
byte ip[] = { 
  192,168,3, 244 };
int relayPin = 7; // relay pin
int ledPin = 14; // LED pin
String RELAY_1_ID = "relay_1";
boolean relayOn = false; //LED status flag
Server server(80);

void setup()
{
  Serial.begin(9600);
  Ethernet.begin(mac, ip);
  //EthernetDHCP.begin(mac, 1);
  //updateIpAddress();
  pinMode(ledPin, OUTPUT);
  pinMode(relayPin, OUTPUT);
  server.begin();
}

void loop()
{
  Client client = server.available();
  if (client) {
    boolean currentLineIsBlank = true;
    String request = "";
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();        
        request = request + c;

        if (c == '\n' && currentLineIsBlank) {     
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();

          //Serial.println("Content: "  + request);
          String relayParameterValue = getParameterValue(request, RELAY_1_ID);
          boolean turnRelayOn = isParameterTrue(relayParameterValue, relayOn);

          if(turnRelayOn) {
            digitalWrite(ledPin, HIGH); // set the LED on
            digitalWrite(relayPin, HIGH); // set the relay on
            Serial.println("Turned relay ON");
          }
          else{
            digitalWrite(ledPin, LOW); // set the LED off
            digitalWrite(relayPin,LOW); // set the relay on
            Serial.println("Turned relay OFF");
          }
          LEDON = turnRelayOn;

          break;
        }
        if (c == '\n') {
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          currentLineIsBlank = false;
        }
      }
    }

    delay(1);
    client.stop();
  }
}

String getParameterValue(String request, String parameterName){
  String parameterValue = "";
  int parameterOffset = request.indexOf(parameterName + "=");

  if(parameterOffset > 0){
    Serial.println("Found parameter \"" + parameterName + "\"");  
    String tempValue = request.substring(parameterOffset + parameterName.length() + 1);

    int newlineIndex = tempValue.indexOf('\n');
    int carriageReturnIndex = tempValue.indexOf('\r');
    int parameterDividerIndex = tempValue.indexOf('&');
    int spacerIndex = tempValue.indexOf(' ');

    int parameterCuttoff = tempValue.length();
    if(newlineIndex > 0) parameterCuttoff = newlineIndex;
    if(carriageReturnIndex > 0) parameterCuttoff = min(parameterCuttoff, carriageReturnIndex);
    if(parameterDividerIndex > 0) parameterCuttoff = min(parameterCuttoff, parameterDividerIndex);
    if(spacerIndex > 0) parameterCuttoff = min(parameterCuttoff, spacerIndex);

    parameterValue = tempValue.substring(0, parameterCuttoff);
    Serial.println("Parameter value: \"" + parameterValue + "\"");
  } else {
    Serial.println("Did not find parameter " + parameterName);  
  }
  return parameterValue;
}  

boolean isParameterTrue(String parameterValue, boolean currentValue){
  boolean isOn = currentValue;
  boolean isToggled = parameterValue.trim().equalsIgnoreCase("TOGGLE");
  if(isToggled){
    isOn = !isOn;
  } else {
    isOn = parameterValue.trim().equalsIgnoreCase("ON");
  }

  return isOn;
}
