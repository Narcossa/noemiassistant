import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleCalendarService {
  final calendar.CalendarApi _calendarApi;

  GoogleCalendarService(this._calendarApi);

  Future<List<calendar.Event>> getUpcomingEvents() async {
    try {
      final now = DateTime.now().toUtc();
      final events = await _calendarApi.events.list(
        'primary',
        timeMin: now,
        maxResults: 10,
        singleEvents: true,
        orderBy: 'startTime',
      );
      
      return events.items ?? [];
    } catch (e) {
      print("Erreur lors de la récupération de l'agenda : $e");
      return [];
    }
  }

  Future<bool> createEvent(String title, DateTime start, DateTime end) async {
    try {
      final event = calendar.Event(
        summary: title,
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
      );
      
      await _calendarApi.events.insert(event, 'primary');
      return true;
    } catch (e) {
      print("Erreur lors de la création de l'événement : $e");
      return false;
    }
  }
}
