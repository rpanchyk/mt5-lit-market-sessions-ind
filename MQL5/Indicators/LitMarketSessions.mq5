//+------------------------------------------------------------------+
//|                                            LitMarketSessions.mq5 |
//|                                         Copyright 2024, rpanchyk |
//|               https://github.com/rpanchyk/fx-lit-market-sessions |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, rpanchyk"
#property link      "https://github.com/rpanchyk/fx-lit-market-sessions"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

#include <Object.mqh>
#include <arrays/arrayobj.mqh>

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
         ObjectSetInteger(0, objName, OBJPROP_FILL, true);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, bgColor());
         ObjectSetInteger(0, objName, OBJPROP_BACK, true);
        }
     }

   ENUM_LIT_SESSION_TYPE type;
   datetime          start;
   datetime          end;
   double            low;
   double            high;

private:
   long              bgColor()
     {
      switch(type)
        {
         case  LIT_SESSION_LONDON:
            return clrLightGreen;
         case  LIT_SESSION_NEWYORK:
            return clrYellow;
         case  LIT_SESSION_TOKYO:
            return clrGray;
         default:
            Print("Unknown type");
            return -1;
        }
     }
  };

CArrayObj boxes;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
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
      Print(i, " at ", TimeToString(time[i]));

      TimeToStruct(time[i], currMdt);
      currDt = StructToTime(currMdt);

      TimeToStruct(time[i], startMdt);
      startMdt.min = 0;
      startMdt.sec = 0;

      TimeToStruct(time[i], endMdt);
      endMdt.min = 0;
      endMdt.sec = 0;

      // London
      startMdt.hour = 8;
      endMdt.hour = 9;
      startDt = StructToTime(startMdt);
      endDt = StructToTime(endMdt);

      if(currDt >= startDt && currDt < endDt)
        {
         addBox(&boxes, LIT_SESSION_LONDON, startDt, endDt, low[i], high[i]);
        }

      // New York
      startMdt.hour = 13;
      endMdt.hour = 14;
      startDt = StructToTime(startMdt);
      endDt = StructToTime(endMdt);

      if(currDt >= startDt && currDt < endDt)
        {
         addBox(&boxes, LIT_SESSION_NEWYORK, startDt, endDt, low[i], high[i]);
        }

      // Tokyo
      startMdt.hour = 23;
      endMdt.hour = 6;
      startDt = StructToTime(startMdt) - 86400; // prev day
      endDt = StructToTime(endMdt);

      if(currDt >= startDt && currDt < endDt)
        {
         addBox(&boxes, LIT_SESSION_TOKYO, startDt, endDt, low[i], high[i]);
        }
     }

   Print("boxes=", boxes.Total());

   return rates_total;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addBox(CArrayObj *allBoxes, ENUM_LIT_SESSION_TYPE type, datetime start, datetime end, double low, double high)
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
      box = new Box(type, start, end, NormalizeDouble(low, _Digits), NormalizeDouble(high, _Digits));
      boxes.Add(box);
     }

   box.draw();
  }
//+------------------------------------------------------------------+
