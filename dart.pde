#include <avr/io.h>
#include <avr/interrupt.h>
#include <inttypes.h>

#define RF433_PIN 10
//********************************************************************//

typedef unsigned char byte;

typedef struct {
  byte offset;
  byte state;
} rf_bit_t;

// offset is number of alphas (0.08ms)

const rf_bit_t zero_bit[] = { {  4, 1 },
                              { 16, 0 },
                              { 20, 1 },
                              { 32, 0 },
                              {  0, 0 } };

const rf_bit_t one_bit[] = { { 12, 1 },
                             { 16, 0 },
                             { 28, 1 },
                             { 32, 0 },
                             {  0, 0 } };

const rf_bit_t float_bit[] = { {  4, 1 },
                               { 16, 0 },
                               { 28, 1 },
                               { 32, 0 },
                               {  0, 0 } };

const rf_bit_t sync_bit[] = { {   4, 1 },
                              { 128, 0 },
                              {   0, 0 } };

typedef enum { ZERO = 0, ONE , FLOAT , SYNC } adbit_t;
typedef byte ad_bit_t;
#define WORD_LEN 13
typedef ad_bit_t word_t[WORD_LEN];

const rf_bit_t* bit_defs[] = { zero_bit, one_bit, float_bit, sync_bit };

byte alpha_cnt = 0;
byte bit_cnt = 0;
byte chunk_cnt = 0;
byte word_cnt = 0;
const ad_bit_t* current_word;
byte volatile frame_finished = 1;

#define FRAME_LEN 8

#define A1_ON  0
#define A1_OFF 1
#define A2_ON  2
#define A2_OFF 3

#define B1_ON  4
#define B1_OFF 5
#define B2_ON  6
#define B2_OFF 7

#define C1_ON  8
#define C1_OFF 9
#define C2_ON  10
#define C2_OFF 11

#define D1_ON  12
#define D1_OFF 13
#define D2_ON  14
#define D2_OFF 15

const word_t words[]  = { 
{ ZERO,  ZERO,  FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // A1_ON
{ ZERO,  ZERO,  FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }, // A1_OFF
{ ZERO,  ZERO,  FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // A2_ON
{ ZERO,  ZERO,  FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }, // A2_OFF

{ FLOAT, ZERO,  FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // B1_ON
{ FLOAT, ZERO,  FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }, // B1_OFF
{ FLOAT, ZERO,  FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // B2_ON
{ FLOAT, ZERO,  FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }, // B2_OFF

{ ZERO,  FLOAT, FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // C1_ON
{ ZERO,  FLOAT, FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }, // C1_OFF
{ ZERO,  FLOAT, FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // C2_ON
{ ZERO,  FLOAT, FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }, // C2_OFF

{ FLOAT, FLOAT, FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // D1_ON
{ FLOAT, FLOAT, FLOAT, FLOAT, ZERO,  ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }, // D1_OFF
{ FLOAT, FLOAT, FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, FLOAT, SYNC }, // D2_ON
{ FLOAT, FLOAT, FLOAT, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO, FLOAT, FLOAT, ZERO,  SYNC }  // D2_OFF
};


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

union {
  byte uint8[4];
  uint32_t uint32;
} rf433_data;
byte rf433_hi_cnt=0;
byte rf433_lo_cnt=0;
byte last_sample=0;
int valid=0;
ISR(TIMER1_COMPA_vect)
{
  byte sample = digitalRead(RF433_PIN);
  if (last_sample!=sample && sample==HIGH)
  {
    if ( rf433_lo_cnt > 2 && rf433_lo_cnt<6 && rf433_hi_cnt>10 && rf433_hi_cnt < 14)
    {
      rf433_data.uint32<<=1;
      rf433_data.uint32|=1;
      valid++;
    } else if (rf433_hi_cnt > 2 && rf433_hi_cnt<6 && rf433_lo_cnt>10 && rf433_lo_cnt < 14) {
      rf433_data.uint32<<=1;
      valid++;
    } else if (rf433_hi_cnt > 2 && rf433_hi_cnt<6 && rf433_lo_cnt>120 && rf433_lo_cnt < 128 && valid >=24) {
      //rf433_data.uint8[3]=0;
      //Serial.print(rf433_data.uint32);
      Serial.print(rf433_data.uint8[0],BYTE);
      Serial.print(rf433_data.uint8[1],BYTE);
      Serial.print(rf433_data.uint8[2],BYTE);
      //Serial.print(rf433_data.uint8[3],BYTE);
    } else {
      valid=0;
      rf433_data.uint32=0;
    }
    rf433_hi_cnt=0;
    rf433_lo_cnt=0;
  }
  if (sample == HIGH)
    rf433_hi_cnt++;
  else 
    rf433_lo_cnt++;
  last_sample=sample;
}

//unsigned long wm_start_[3]={0,0,0};
//bool wait_millis(unsigned long *start_time, unsigned long ms)
//{
//  if (ms == 0)
//    return false;
//  else if (*start_time > 0)
//  {
//    if (millis() < *start_time || millis() > (*start_time) + ms)
//    {
//      *start_time = 0;
//      return false;
//    }
//    else
//      return true;
//  }
//  else
//  {
//    *start_time=millis();
//    return true;
//  }
//}

//********************************************************************//

void setup()
{
  pinMode(RF433_PIN, INPUT);      // set pin to input
  digitalWrite(RF433_PIN, LOW);  // turn of pullup resistors 

  Serial.begin(57600);
//  Serial.println("starting timer");
  start_timer();
}


void loop()
{
}
