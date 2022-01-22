import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'colors.dart' as color;

class calander extends StatefulWidget {
  const calander({Key? key}) : super(key: key);

  @override
  _calanderState createState() => _calanderState();
}

class _calanderState extends State<calander> {
  late Map<DateTime, List<Event>> selectedEvent;
  CalendarFormat formart = CalendarFormat.month;
  DateTime selectDay = DateTime.now();
  DateTime foucsedDay = DateTime.now();
  TextEditingController _eventController = TextEditingController();
  // late SharedPreferences prefs;

  var dataFromFirebase;

  var collection = FirebaseFirestore.instance
      .collection('Event')
      .doc('SelectedEventDocument');

  getData() async {
    var docSnapshot = await collection.get();
    var data = docSnapshot.data();
    return data;
  }

  @override
  void initState() {
    selectedEvent = {};
    print("SELECTED  #${selectedEvent}");
    // prefsData();
    super.initState();
  }

  // prefsData() async {
  //   prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     _eventController = Map<DateTime, List<dynamic>>.from(
  //         decodeMap(json.decode(prefs.getString("events") ?? "{}"))) as TextEditingController ;
  //   });
  // }
  Map<String, dynamic> encodeMap(Map<DateTime, dynamic> map) {
    Map<String, dynamic> newMap = {};
    map.forEach((key, value) {
      newMap[key.toString()] = map[key];
    });
    return newMap;
  }

  Map<DateTime, dynamic> decodeMap(Map<String, dynamic> map) {
    Map<DateTime, dynamic> newMap = {};
    map.forEach((key, value) {
      newMap[DateTime.parse(key)] = map[key];
    });
    return newMap;
  }

  List<Event> _getEventsfromDay(DateTime date) {
    return selectedEvent[date] ?? [];
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.AppColor.gradianS,
        title: Row(
          children: [
            SizedBox(
              width: screenSize.width / 2.9,
            ),
            Text("Calander"),
            SizedBox(
              width: screenSize.width / 6,
            ),
            MaterialButton(
              minWidth: 10,
              child: Icon(Icons.refresh),
              onPressed: () async {
                dataFromFirebase = await getData();

                for (int i = 0; i < dataFromFirebase.length; i++) {
                  var timeS = dataFromFirebase['selectedEvent'][i]['dateTime'];
                  DateTime d = timeS.toDate();
                  List<Event> events = [];
                  events.add(Event(
                      title: dataFromFirebase['selectedEvent'][i]['event']));
                  selectedEvent[d] = events;
                }
                log("$selectedEvent");
                // dataFromFirebase['selectedEvent'].add({
                //   dataFromFirebase['selectedEvent'][0]['dateTime']: "HIIII"
                // });
                // log('NEW DATA ${dataFromFirebase}');
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          TableCalendar(
            focusedDay: selectDay,
            firstDay: DateTime(1990),
            lastDay: DateTime(2050),
            calendarFormat: formart,
            onFormatChanged: (CalendarFormat _format) {
              setState(() {
                formart = _format;
              });
            },

            startingDayOfWeek: StartingDayOfWeek.sunday,
            daysOfWeekVisible: true,
            // day change
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                selectDay = selectedDay;
                foucsedDay = focusedDay;
              });

              print(foucsedDay);
            },
            selectedDayPredicate: (DateTime date) {
              return isSameDay(selectDay, date);
            },
            eventLoader: _getEventsfromDay,

            calendarStyle: CalendarStyle(
              isTodayHighlighted: true,
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: color.AppColor.gradianS,
                shape: BoxShape.circle,
              ),
            ),

            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: color.AppColor.gradianS,
                borderRadius: BorderRadius.circular(5.0),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          ..._getEventsfromDay(selectDay).map((Event event) => ListTile(
                title: Text(event.title),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
            context: context,
            builder: (Context) => AlertDialog(
                  title: Text("Add Event"),
                  content: TextFormField(
                    controller: _eventController,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel")),
                    TextButton(
                        onPressed: () {
                          log('Before update ${dataFromFirebase}');
                          if (_eventController.text.isEmpty) return;
                          setState(() {
                            if (selectedEvent[selectDay] != null) {
                              selectedEvent[selectDay] = [
                                Event(title: _eventController.text)
                              ];
                              for (int i = 0;
                                  i < dataFromFirebase['selectedEvent'].length;
                                  i++) {
                                var timeS = dataFromFirebase['selectedEvent'][i]
                                    ['dateTime'];
                                DateTime d = timeS.toDate();
                                String temp = '${d.toString()}Z';
                                if (selectDay.toString().substring(0, 10) ==
                                    temp.substring(0, 10)) {
                                  log('IN if');
                                  dataFromFirebase['selectedEvent'][i]
                                      ['event'] = _eventController.text;
                                  log("$dataFromFirebase");
                                }
                              }
                            } else {
                              selectedEvent[selectDay] = [
                                Event(title: _eventController.text)
                              ];
                              dataFromFirebase['selectedEvent'].add({
                                'dateTime': Timestamp.fromDate(selectDay),
                                'event': _eventController.text
                              });
                            }
                            collection.set({'selectedEvent': dataFromFirebase});
                            _eventController.clear();
                            Navigator.pop(context);
                          });
                        },
                        child: Text("Ok")),
                  ],
                )),
        label: Text("Add Event"),
        icon: Icon(Icons.add),
      ),
    );
  }
}
