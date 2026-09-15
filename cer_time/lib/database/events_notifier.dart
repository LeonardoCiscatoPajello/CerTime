import 'package:flutter/foundation.dart';

class EventsNotifier extends ChangeNotifier{
  static final EventsNotifier instance = EventsNotifier._internal();
  EventsNotifier._internal();

  void notifyEventsChanged(){
    notifyListeners();
  }
}