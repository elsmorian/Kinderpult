// Kinderpult
// 
// Code for Arduino running the kinderpult prototype
// Servo modified for continous rotation
//
// November 2010
// Chris Elsmore (elsmorian@gmail.com)

#include <Servo.h>           // Include Servo lib
#include <LiquidCrystal.h>   // Include LCD Lib


const int buttonPin = 7;     // Pin used for the loading button
const int sensePin = 2;      // Pin used to sense if kinderpult fired - must be hardware interrupt.
const int ledPin =  13;      // the number of the LED pin
const int loadtime = 17;     // (Seconds takes to load to 'full' capacity)


int ledState = HIGH;         // The current state of the output pin
int buttonState;             // The current reading from the input pin
int lastButtonState = LOW;   // The previous reading from the input pin
Servo myservo;               // The servo 
LiquidCrystal lcd(12, 11, 5, 4, 3, 6);    // The LCD (D4-7 was on 5,4,3,2, used 6 as pin 2 needed for interrupt)
int tweeted = 0;             // Have we tweeted (DEPRECATED)
int servostopped = 0;        // Is the servo stopped
volatile int charge = 0;     // Charge variable in percent
volatile int chargetmp = 0;  // temp charge variable for working out percent
int buttonTimer = 0;         // millis button was for the button
int lastOffState = 0;        // millis when button was last in the off state
int tmpint = 0;              // temporary int
volatile int servoR = 0;     // servo reverse mode
int lastfire;                // when was the last fire
long lastDebounceTime = 0;   // the last time the output pin was toggled
long debounceDelay = 80;     // the debounce time; increase if the output flickers


void setup() {
  lcd.begin(16,2);           // Start the LCD with a 16 char 2 line display
  lcd.print("   KinderPult   ");
  lcd.setCursor(0, 1);       // Set LCD cursor to start of second line
  lcd.print(" Starting Up..  ");
  attachInterrupt(0, tweet, RISING);  // Attach RISING interrupt to Digital pin 2 for fired sensor
  pinMode(buttonPin, INPUT); // Setup pin for load button
  pinMode(ledPin, OUTPUT);   // Setup pin for testing LED
  //myservo.attach(14);      // We don't attach the servo here anymore
  //myservo.write(91);      
  // Each time we run the servo, we attach it first, and then detach to stop, to prevent it glitching or creeping
  // due to the internal pot not being exactly centred
  Serial.begin(9600);        // Start serial coms
  lcd.setCursor(0, 1);       // Set the LCD at the top line again
  lcd.print("     Ready!     ");
}


void loop() {
  // Button Debounce Code
  int reading = digitalRead(buttonPin);  // Read in button state
  if (reading != lastButtonState) {      // If reading is not the same as the last button state read
    lastDebounceTime = millis();         // Make the last debounce time = current arduino time, as button state still fluctuating
  } 
  if ((millis() - lastDebounceTime) > debounceDelay) { // if the debounce time has past, without being reset
    buttonState = reading;              // Set the buttonState to the reading, as state has settled
  }
  digitalWrite(ledPin, buttonState);   // Reflect the state of the button in the LED
  
  
  if(buttonState) {                  // When button pushed:
    if (servoR == 1) {              // If we are in post-fire servo reverse mode after a firing
      myservo.write(91);            // Stop the servo
      myservo.detach();             // Detach the servo
      servoR = 0;                   // Indicate we are no longer in servo reverse mode
    }
    else {                          // If we are in normal pre-fire mode
    buttonTimer = millis()/100;     // Store the time when the button was pushed on the last loop
    myservo.attach(14);             // Attach the servo
    myservo.write(180);             // Start the servo winding the firing mech back, full speed
    servostopped = 0;               // Indicate the servo is not stopped
      lcd.setCursor(0, 1);          // Set LCD text
      lcd.print("Charge:         ");
      lcd.setCursor(0, 0);
      lcd.print(" Charging egg.. ");
      lcd.setCursor(0, 1);
      lcd.print("Charge: Loading ");
      lcd.print(charge);
      // FUTUREWORK: add code to refresh screen only when a %Power increase has been detected, and notify user of charge power in real time
    }
  }
  else{                              // When button released
    if(!servostopped) {              // If we haven't already stopped the servo
      myservo.detach();              // Stop and detach servo
      servostopped = 1;              // Indicate the servo is now stopped.
    }
   if(buttonTimer > 0) {                            // If the button timer is not zero, we have a button press we need to add to current power
     chargetmp += (buttonTimer - lastOffState);     // Store length of time the button was pressed for in millis()/100
     charge = map(chargetmp,0,loadtime*10,0,100);   // Store the charge as a percentage of the calibrated time for a full load
     buttonTimer = 0;                               // Indicate we have stored the last button press
     lcd.setCursor(0, 1);                          // Update the LCD
     lcd.print("                ");
     lcd.setCursor(0, 1);
     lcd.print("Charge: ");
     lcd.print(charge);
     lcd.print("%");
   }
   lastOffState = millis()/100;    // Store the time of the current button not pressed loop
  }
 
  // Save the reading.  Next time through the loop, it'll be the lastButtonState:
  lastButtonState = reading;
}

void tweet()
{
   if (servoR == 0) {             // If we are not already in servo reverse mode
     Serial.print(charge);        // Transmit the last fired power
     Serial.println("%");
     chargetmp = 0;               // Reset the charge veriables
     charge = 0;
     myservo.attach(14);          // Rewind the servo
     myservo.write(80);
     servoR = 1;                  // Indicate servo reverse mode started
   }
}


