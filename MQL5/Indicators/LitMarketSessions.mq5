//+------------------------------------------------------------------+
//|                                            LitMarketSessions.mq5 |
//|                                         Copyright 2024, rpanchyk |
//|           https://github.com/rpanchyk/fx-lit-market-sessions-ind |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, rpanchyk"
#property link      "https://github.com/rpanchyk/fx-lit-market-sessions-ind"
#property description "Indicator shows LIT market sessions"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots 0

#include <Object.mqh>
#include <arrays/arrayobj.mqh>

enum ENUM_TIME_ZONE
  {
   TZauto = 99, // auto
   TZp6 = 6, // +6
   TZp5 = 5, // +5
   TZp4 = 4, // +4
   TZp3 = 3, // +3
   TZp2 = 2, // +2
   TZp1 = 1, // +1
   TZp0 = 0, // 0
   TZm1 = -1, // -1
   TZm2 = -2, // -2
   TZm3 = -3, // -3
   TZm4 = -4, // -4
   TZm5 = -5, // -5
   TZm6 = -6 // -6
  };

enum ENUM_BORDER_STYLE
  {
   BORDER_STYLE_SOLID = STYLE_SOLID, // Solid
   BORDER_STYLE_DASH = STYLE_DASH // Dash
  };

enum ENUM_LIT_SESSION_TYPE
  {
   LIT_SESSION_LONDON,  // 08 AM to 09 AM [UTC] - Open Inducement Window (1 hour)
   LIT_SESSION_NEWYORK, // 01 PM to 02 PM [UTC] - Open Inducement Window (1 hour)
   LIT_SESSION_TOKYO    // 23 PM to 06 AM [UTC]
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Box : public CObject
  {
public:
                     Box(ENUM_LIT_SESSION_TYPE sType, datetime startDt, datetime endDt, double lowPrice, double highPrice)
     {
      this.type = sType;
      this.start = startDt;
      this.end = endDt;
      this.low = lowPrice;
      this.high = highPrice;
     }

   void              draw()
     {
      string objName = "sbox " + TimeToString(start);
      if(ObjectFind(0, objName) < 0)
        {
         ObjectCreate(0, objName, OBJ_RECTANGLE, 0, start, low, end, high);

         ObjectSetInteger(0, objName, OBJPROP_COLOR, getTypeAsColor());
         ObjectSetInteger(0, objName, OBJPROP_FILL, inpFill);
         ObjectSetInteger(0, objName, OBJPROP_STYLE, inpBoderStyle);
         ObjectSetInteger(0, objName, OBJPROP_WIDTH, inpBoderWidth);
         ObjectSetInteger(0, objName, OBJPROP_BACK, true);
         ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
         ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
         ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
        }
     }

   ENUM_LIT_SESSION_TYPE type;
   datetime          start;
   datetime          end;
   double            low;
   double            high;

   long              getTypeAsColor()
     {
      switch(type)
        {
         case  LIT_SESSION_LONDON:
            return inpLondonSessionColor;
         case  LIT_SESSION_NEWYORK:
            return inpNewyorkSessionColor;
         case  LIT_SESSION_TOKYO:
            return inpTokyoSessionColor;
         default:
            Print("Unknown type");
            return -1;
        }
     }

   int               getTypeAsNumber()
     {
      switch(type)
        {
         case  LIT_SESSION_LONDON:
            return 1;
         case  LIT_SESSION_NEWYORK:
            return 2;
         case  LIT_SESSION_TOKYO:
            return 3;
         default:
            Print("Unknown type");
            return -1;
        }
     }
  };

// buffers
double TypeBuffer[];
double LowBuffer[];
double HighBuffer[];

// input parameters
sinput string _10 = "=== Section :: Main ===";
input ENUM_TIME_ZONE inpTimeZoneOffsetHours = TZauto; // Time zone (offset in hours)
sinput string _20 = "=== Section :: Style ===";
input color inpLondonSessionColor = clrLightGreen; // London session color
input color inpNewyorkSessionColor = clrYellow; // NewYork session color
input color inpTokyoSessionColor = clrLightGray; // Tokyo session color
input bool inpFill = true; // Fill solid (true) or transparent (false)
input ENUM_BORDER_STYLE inpBoderStyle = BORDER_STYLE_SOLID; // Border line style
input int inpBoderWidth = 2; // Border line width

// runtime
CArrayObj boxes;
int timeShift;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(TypeBuffer, true);
   ArraySetAsSeries(LowBuffer, true);
   ArraySetAsSeries(HighBuffer, true);

   SetIndexBuffer(0, TypeBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, LowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, HighBuffer, INDICATOR_DATA);

   timeShift = (inpTimeZoneOffsetHours == TZauto ? getTimeZoneOffsetHours() : inpTimeZoneOffsetHours) * 60 * 60;

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "sbox");
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
   if(rates_total == prev_calculated)
     {
      return rates_total;
     }

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);

   int limit = rates_total - prev_calculated;
   Print("rates_total=", rates_total, " prev_calculated=", prev_calculated, " limit=", limit);

   MqlDateTime currMdt;
   MqlDateTime startMdt;
   MqlDateTime endMdt;

   datetime currDt;
   datetime startDt;
   datetime endDt;

   for(int i = limit - 1; i > 0; i--)
     {
      datetime dt = time[i];
      Print(i, " at ", TimeToString(dt), " GMT");

      TimeToStruct(dt, currMdt);
      currDt = StructToTime(currMdt);

      TimeToStruct(dt, startMdt);
      startMdt.min = 0;
      startMdt.sec = 0;

      TimeToStruct(dt, endMdt);
      endMdt.min = 0;
      endMdt.sec = 0;

      // London
      startMdt.hour = 8;
      endMdt.hour = 9;
      startDt = StructToTime(startMdt) + timeShift;
      endDt = StructToTime(endMdt) + timeShift;

      if(currDt >= startDt && currDt < endDt)
        {
         addBox(&boxes, LIT_SESSION_LONDON, startDt, endDt, low[i], high[i], i);
        }

      // New York
      startMdt.hour = 13;
      endMdt.hour = 14;
      startDt = StructToTime(startMdt) + timeShift;
      endDt = StructToTime(endMdt) + timeShift;

      if(currDt >= startDt && currDt < endDt)
        {
         addBox(&boxes, LIT_SESSION_NEWYORK, startDt, endDt, low[i], high[i], i);
        }

      // Tokyo
      startMdt.hour = 23;
      endMdt.hour = 6;
      startDt = StructToTime(startMdt) - 86400 + timeShift; // prev day
      endDt = StructToTime(endMdt) + timeShift;

      if(currDt >= startDt && currDt < endDt)
        {
         addBox(&boxes, LIT_SESSION_TOKYO, startDt, endDt, low[i], high[i], i);
        }
     }

   Print("boxes=", boxes.Total());

   return rates_total;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get time zone offset in hours                                    |
//+------------------------------------------------------------------+
int getTimeZoneOffsetHours()
  {
   datetime serverTime = TimeTradeServer();
   datetime gmtTime = TimeGMT();

   int offsetSeconds = ((int)serverTime) - ((int)gmtTime);
   int offsetHours = offsetSeconds / 3600;

   Print("Detected server offset: ", IntegerToString(offsetHours), " hrs");
   return offsetHours;
  }

//+------------------------------------------------------------------+
//| Add or update existing box and draw it                           |
//+------------------------------------------------------------------+
void addBox(CArrayObj *allBoxes, ENUM_LIT_SESSION_TYPE sType, datetime start, datetime end, double low, double high, int i)
  {
   Box *box = allBoxes.Total() > 0
              ? allBoxes.At(allBoxes.Total() - 1)
              : NULL;

   if(box != NULL && box.start == start)
     {
      box.end = end;
      box.low = MathMin(box.low, NormalizeDouble(low, _Digits));
      box.high = MathMax(box.high, NormalizeDouble(high, _Digits));

      ObjectsDeleteAll(0, "sbox " + TimeToString(start));
     }
   else
     {
      box = new Box(sType, start, end, NormalizeDouble(low, _Digits), NormalizeDouble(high, _Digits));
      boxes.Add(box);
     }

   box.draw();
   Print("box drawn");

   setBuffers(box, i);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Fill indicator buffers                                           |
//+------------------------------------------------------------------+
void setBuffers(Box *box, int i)
  {
   TypeBuffer[i] = box.getTypeAsNumber();
   LowBuffer[i] = box.low;
   HighBuffer[i] = box.high;
  }
//+------------------------------------------------------------------+
