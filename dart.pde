#include <avr/io.h>
#include <avr/interrupt.h>
#include <inttypes.h>

//INPUT PINS digital 2-7 PIND
//INPUT PINS digitat 8-12 PINB
//INPUT PINS analog 0-4 PINC

#define RF433_PIN 10
//********************************************************************//

typedef unsigned char byte;

//********************************************************************//

void start_timer()
{
  // timer 1: 2 ms
  TCCR1A = 0;                    // prescaler 1:8, WGM = 4 (CTC)
  TCCR1B = 1<<WGM12 | 1<<CS11;   // 
  OCR1A = 159;        // (1+159)*8 = 1280 -> 0.08ms @ 16 MHz -> 1*alpha
//  OCR1A = 207;        // (1+207)*8 = 1664 -> 0.104ms @ 16 MHz -> 1*alpha
  TCNT1 = 0;          // reseting timer
  TIMSK1 = 1<<OCIE1A; // enable Interrupt
}

void stop_timer() // stop the timer
{
  // timer1
  TCCR1B = 0; // no clock source
  TIMSK1 = 0; // disable timer interrupt
}

ISR(TIMER1_COMPA_vect)
{
// Serial.print('a');
}


void setup()
{
//  pinMode(RF433_PIN, INPUT);      // set pin to input
//  digitalWrite(RF433_PIN, LOW);  // turn of pullup resistors 
  //Set Port as input
  DDRB=0;
// disable pull up
  PORTB=0;
  DDRD = DDRD & 3;
  PORTD= PORTD & 3;
  DDRC=0;
  PORTC=0;
  Serial.begin(57600);
  Serial.println("starting timer");
//  start_timer();
}

union union16 {
  byte uint8[2];
  uint16_t uint16;
}; 

//INPUT PINS digital 2-7 PIND
//INPUT PINS digitat 8-12 PINB
//INPUT PINS analog 0-4 PINC
void loop()
{
//  Serial.println("foo");
//  return;

  union16 data;
  data.uint8[0]=PIND;
  data.uint16<<=3;
  data.uint8[0]|= (PINC & B11111);
  data.uint16<<=5; 
  data.uint8[0]|= (PINB & B11111);
  Serial.print(data.uint8[0]);
  Serial.print(data.uint8[1]);
}
