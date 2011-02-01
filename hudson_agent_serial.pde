int relayPin = 7; // Relay pin
int ledPin = 14; // LED pin
String RELAY_1_ID = "relay_1";
String request = "";
boolean relayOn = false; 

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(relayPin, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  request = readMessage(request);
  Serial.println("Command: " + request);
  
  String relayParameterValue = getParameterValue(request, RELAY_1_ID);
  boolean turnRelayOn = isParameterTrue(relayParameterValue, relayOn);

  if(turnRelayOn) {
    digitalWrite(ledPin, HIGH); // set the LED on
    digitalWrite(relayPin, HIGH); // set the relay on
    Serial.println("Turned relay ON");
  } 
  else {
    digitalWrite(ledPin, LOW); // set the LED off
    digitalWrite(relayPin,LOW); // set the relay on
    Serial.println("Turned relay OFF");
  }
  relayOn = turnRelayOn;
  request = removeTopCommandFromBuffer(request);
}

String readMessage(String leftoverBuffer){
  String message = leftoverBuffer;

  while(message.indexOf(';') == -1 && message.indexOf('\r') == -1){
    if (Serial.available() > 0) {
      char incomingChar = Serial.read();
      Serial.print(incomingChar);
      message = message + incomingChar;
    }
  }
  Serial.println();
  return message;
}

String getParameterValue(String request, String parameterName){
  String parameterValue = "";
  int parameterOffset = request.indexOf(parameterName + "=");

  if(parameterOffset >= 0){
    Serial.println("Found parameter \"" + parameterName + "\"");  
    String tempValue = request.substring(parameterOffset + parameterName.length() + 1);
    int endOfCommand = getNextCommandEnd(tempValue);
    parameterValue = tempValue.substring(0, endOfCommand);
    Serial.println("Parameter value: \"" + parameterValue + "\"");
  } 
  else{
    Serial.println("Did not find parameter " + parameterName);  
  }
  return parameterValue;
  
}  

boolean isParameterTrue(String parameterValue, boolean currentValue){
  boolean isOn = currentValue;
  boolean isToggled = parameterValue.trim().equalsIgnoreCase("TOGGLE");
  if(isToggled){
    isOn = !isOn;
  } 
  else{
    isOn = parameterValue.trim().equalsIgnoreCase("ON");
  }

  return isOn;
}

String removeTopCommandFromBuffer(String request){
  int endOfFirstCommand = getNextCommandEnd(request) + 1;
  return String(request.substring(endOfFirstCommand));
}

int getNextCommandEnd(String input){
  int newlineIndex = input.indexOf('\n');
  int dividerIndex = input.indexOf(';');

  int parameterCuttoff = input.length();
  if(newlineIndex > 0) parameterCuttoff = newlineIndex;
  if(dividerIndex > 0) parameterCuttoff = min(parameterCuttoff, dividerIndex);

  return parameterCuttoff;
}
