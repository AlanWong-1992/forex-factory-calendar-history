
//+------------------------------------------------------------------+
//|                                                  ffc_history.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_minimum 1
#property indicator_maximum 10

#define INAME     "ffc_history"
#import "shell32.dll"

int ShellExecuteW(int hwnd,string Operation,string File,string Parameters,string Directory,int ShowCmd);

#import
int counter = 0;
string tooltip = "";

// CSV file data 
string day_of_week; // Day of Week Mon-Fri
string date_and_time; // Date and Time
datetime dt_date_and_time; // Date and Time in the datetime datatype of mql4
string event_time; // Hour and Minutes of the event
string curr_symbol; // Currency of News Event
string impact; // Impact Level of the news
string event_name; // Name of the Event
string previous_fig; // Previous Release Figure
string forecast_fig; // Forecasted Release Figure
string actual_fig; // Actual Release Figure

// Miscellaneous 
datetime event_time_array[]; // An array of event times, need to compare with previous event times in while loop to see if the same or not to shift up on the indicator subwindow
double rank_of_event=2; // The y-axis co-ordinate for where the arrow object should be placed
color clr_arrow; // color of the arrow object depending on impact
int arrow_code_impact; // The number on the arrow object depending on impact
int one_hour_in_secs = 3600;
bool found_event;
string curr_to_show;
// User Inputs
input int hours_to_shift;
input bool up_date_news_csv = false;
input bool high_impact_news = true;
input bool med_impact_news = true;
input bool low_impact_news = false;
input bool holiday_impact_news = false;
input string search_words = "";
input bool usd_events = true;
input bool eur_events = true;
input bool gbp_events = true;
input bool cad_events = true;
input bool aud_events = true;
input bool nzd_events = true;
input bool jpy_events = true;
input bool cny_events = true;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
    Print("Search Words: "+search_words);
//--- indicator buffers mapping
   // string common_data_path=TerminalInfoString(TERMINAL_COMMONDATA_PATH);
   // string terminal_data_path=TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\";
   // string python_script = terminal_data_path + "\\Scripts\\ffc_scraper.py";
   // string python_successful_exec_file = "ffc_events_scraper_successful.txt";

   // if(up_date_news_csv)
   // {

   //  if(FileIsExist(python_successful_exec_file))
   //   {
   //      FileDelete(python_successful_exec_file);
   //   }
   
   //  ShellExecuteW(0, "Open", python_script, "calendar.php?day=jan1.2015 calendar.php?day=jul15.2018", "", 1);
   
   //  while(FileIsExist(python_successful_exec_file)==False)
   //    {
   //      Sleep(100);
   //      if (FileIsExist(python_successful_exec_file)) break;
   //    }
   // }
   
   // Print("Found File");
   int time_shift = one_hour_in_secs * hours_to_shift;
   int filehandle=FileOpen("ffc_news_events.csv",FILE_READ|FILE_CSV, ",");
   
   if(filehandle!=INVALID_HANDLE)
     {
      // FileWrite(filehandle,TimeCurrent(),Symbol(), EnumToString(ENUM_TIMEFRAMES(_Period)));
      ArrayFree(event_time_array);
      ArrayResize(event_time_array, 1);
      while(FileIsEnding(filehandle)==false)  // While the file pointer..
      { 
        day_of_week = FileReadString(filehandle);
        date_and_time = FileReadString(filehandle);
        dt_date_and_time = StrToTime(date_and_time);
        event_time = FileReadString(filehandle);
        curr_symbol = FileReadString(filehandle); 
        impact = FileReadString(filehandle);
        event_name = FileReadString(filehandle);
        previous_fig = FileReadString(filehandle);
        forecast_fig = FileReadString(filehandle);
        actual_fig = FileReadString(filehandle);

        ArrayFill(event_time_array, counter, 1, dt_date_and_time);
        ArrayResize(event_time_array, ArraySize(event_time_array)+1);

        search_event(event_name, search_words) > -1 ? found_event = true : found_event = false;

        // event time array has the dat and time values, compare to see if the current date tinme is equal to the last datetime
        // if they are equal then this means they have the same date time and rank_of_event increases by 1 so then the arrow
        // object gets increased by one so that the object is shown above the previous object with the same time. 
        if(counter > 0){
          if(event_time_array[counter] == event_time_array[counter-1]) {
            rank_of_event++;
          } else {
            rank_of_event = 2;
          }  
        }

        // Determine if news event is high/med/low impact and provide right properties for the arrow objects.
        if(impact == " high") {
          clr_arrow = clrRed;
          arrow_code_impact = 142;
        } else if(impact == " medium") {
          clr_arrow = clrOrange;
          arrow_code_impact = 141;
        } else if(impact == " low") {
          clr_arrow = clrPowderBlue;
          arrow_code_impact = 140;
        } else {
          clr_arrow = clrGray;
          arrow_code_impact = 139;
        }

        // Creating the Arrow Objects in the sub windows
        tooltip = StringTrimLeft(curr_symbol) + " | " +StringTrimLeft(day_of_week) +" | " + StringTrimLeft(event_time) + " | " +StringTrimLeft(impact) + "\n" + StringTrimLeft(event_name) + "\nPrevious: " +previous_fig + "\nForecast: " + forecast_fig + "\nActual: " + actual_fig;  
        string name = INAME + " " +event_name + " " + counter;

        curr_to_show =currencies_to_show(usd_events, eur_events, gbp_events, cad_events, nzd_events, aud_events, jpy_events, cny_events);

        if(search_words == "" &&((impact == " high" && high_impact_news) || (impact == " medium" && med_impact_news) || (impact == " low" && low_impact_news) || (impact == " holiday" && holiday_impact_news)) && (StringFind(curr_to_show, curr_symbol)>-1))
        {
         create_event_objects(dt_date_and_time, time_shift, rank_of_event, name, arrow_code_impact, clr_arrow, tooltip);
        }
        else if(found_event &&((impact == " high" && high_impact_news) || (impact == " medium" && med_impact_news) || (impact == " low" && low_impact_news) || (impact == " holiday" && holiday_impact_news)) && (StringFind(curr_to_show, curr_symbol)>-1))
        {
          create_event_objects(dt_date_and_time, time_shift, rank_of_event, name, arrow_code_impact, clr_arrow, tooltip);
        }

        counter = counter +1;

        if(FileIsEnding(filehandle)==true)   // File pointer is at the end
          break;                        // Exit reading and drawing
      }
      FileClose(filehandle);
      Print("FileOpen OK");
     }
   else Print("Operation FileOpen failed, error ",GetLastError());
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Custom Functions function                                              |
//+------------------------------------------------------------------+
void show_news_impact_levels(bool high_impact_news, bool med_impact_news, bool low_impact_news, bool holiday_impact_news)
{
  
}

int search_event(string event_name, string search_words)
{
    int pos = StringFind(event_name, search_words);
    return pos;
}

void create_event_objects(datetime dt_date_and_time, int time_shift, int rank_of_event, string name, int arrow_code_impact, color clr_arrow, string tooltip)
{
  ObjectCreate(name, OBJ_ARROW, 1, dt_date_and_time + time_shift, rank_of_event);
  ObjectSet(name, OBJPROP_ARROWCODE, arrow_code_impact);
  ObjectSet(name, OBJPROP_COLOR, clr_arrow);
  ObjectSetString(0,name, OBJPROP_TOOLTIP,tooltip);
}

string currencies_to_show(bool usd_events, bool eur_events, bool gbp_events, bool cad_events, bool nzd_events, bool aud_events, bool jpy_events, bool cny_events)
{
  string currencies_to_show = "";
  if(usd_events) currencies_to_show = currencies_to_show+" USD";
  if(eur_events) currencies_to_show = currencies_to_show+" EUR";
  if(gbp_events) currencies_to_show = currencies_to_show+" GBP";
  if(cad_events) currencies_to_show = currencies_to_show+" CAD";
  if(nzd_events) currencies_to_show = currencies_to_show+" NZD";
  if(aud_events) currencies_to_show = currencies_to_show+" AUD";
  if(jpy_events) currencies_to_show = currencies_to_show+" JPY";
  if(cny_events) currencies_to_show = currencies_to_show+" CNY";
  return currencies_to_show;
}