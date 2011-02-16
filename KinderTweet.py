""" 
KinderTweet.py
November 2010
Chris Elsmore (elsmorian@gmail.com)


Python script that listens to the KinderPult over a serial connection, and tweets when it fires.
CONSUMER_Key and SECRET come from registering a new application with Twitter
ACCESS_TOKEN_KEY and SECRET aquired from one time verification by user with twitter web service:-

    auth = tweepy.OAuthHandler('CONSUMER_KEY', 'CONSUMER_SECRET)'
    try:
        redirect_url = auth.get_authorization_url()
    except tweepy.TweepError:
        print 'Token Error'
    print redirect_url # Send user to this URL to aquire verification code
    try:
        auth.get_access_token(XXXXXXX) # Replace XXXXXXX with verification code from URL
    except tweepy.TweepError:
        print 'Verification Error'
    print auth.access_token.key
    print auth.access_token.secret


Requires tweepy and PySerial: "easy_install pyserial tweepy"
Tweepy Demo: http://joshthecoder.github.com/tweepy/docs/auth_tutorial.html#auth-tutorial
"""

import serial           #Import pyserial    # Import libraries
import tweepy           #Import twitter

# Set key and secret constants

CONSUMER_KEY = "S0EahYJqjxxYO3rtn32HA"
CONSUMER_SECRET = "tbCY5bghPLDOuhzNZ7HI93M2y5uK72vFDxXZ0627U"
ACCESS_TOKEN_KEY = "214062018-zrrwyGtGnJ28fYZcru5Kd8j4qzKBAepPRNnTdii3"
ACCESS_TOKEN_SECRET = "4CmTUJDll30W4Id9CbBjzuEvi6iFeiSDcjOf0afd0s8"
MY_COM_PORT = "/dev/tty.usbserial-A800eI7d"

auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET) # Define a OAuthhandler
auth.set_access_token(ACCESS_TOKEN_KEY, ACCESS_TOKEN_SECRET) # Set access tokens
api = tweepy.API(auth) # Creat an api object with the auth keys

try: # Attempt to open the serial port
    ser = serial.Serial(port=MY_COM_PORT, baudrate=9600)
except serial.SerialException, msg:
    print ("Failed to connect to Arduino: " + str(msg))
    exit(1)

print "Kinderpult OK"

while True: # Main loop
    line = ser.readline() # Read a line from the serial port
    
    try:
        print "Recieved Power: " + line # 
        #print "DEBUG: Numerical power = " + line.replace('%', '') 
        
        power = int(line.replace('%', '')) # remove the percentage sign, and cast to an integer)
        
        # Work out what message to use, depending on the shot power, and display and tweet it
        
        if power > 100:
            print 'OVERDRIVE Kinderpult Shot++! Dangerous, at ' + str(power) + '% egg power!'
            api.update_status('OVERDRIVE Kinderpult Shot++! Dangerous, at ' + str(power) + '% egg power!')
        elif power == 100:
            print 'Kinderpult Fire! Maximum range, at ' + str(power) + '% egg power!'
            api.update_status('Kinderpult Fire! Maximum range, at ' + str(power) + '% egg power!')
        elif power > 70:
            print 'Kinderpult Fire! A Strong shot! Egg power at ' + str(power) + '%!'
            api.update_status('Kinderpult Fire! A Strong shot! Egg power at ' + str(power) + '%!')
        elif power > 40:
            print 'Kinderpult Fire! A Medium shot! Egg power at ' + str(power) + '%!'
            api.update_status('Kinderpult Fire! A Medium shot! Egg power at ' + str(power) + '%!')
        elif power > 5:
            print 'What was that!? Kinderpult hardly fires, a weak shot! Egg power at ' + str(power) + '%!'
            api.update_status('What was that!? Kinderpult hardly fires, a weak shot! Egg power at ' + str(power) + '%!')
            
    except serial.SerialException, err: # Handle serial errors
        print("Failed to receive data from Arduino: " + str(err))
        ser.close()
        exit(1)

ser.close()
exit(0)