import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'sql_helper.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedEvents = [];

  final _quickMoods = ['Happy', 'Sad', 'Angry', 'Excited'];

  @override
  void initState() {
    super.initState();
    _events = {};
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final data = await SQLHelper.getDiaries();
    final Map<DateTime, List<Map<String, dynamic>>> ev = {};
    for (var e in data) {
      final dt  = DateTime.parse(e['date']);
      final key = DateTime(dt.year, dt.month, dt.day);
      ev.putIfAbsent(key, () => []).add(e);
    }
    setState(() {
      _events         = ev;
      _selectedEvents = ev[_selectedDay ?? _focusedDay] ?? [];
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _emoji(String f) {
    f = f.toLowerCase();
    if (f.contains('happy'))   return '😊';
    if (f.contains('sad'))     return '😢';
    if (f.contains('angry'))   return '😡';
    if (f.contains('excited')) return '🤩';
    return '📝';
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate : DateTime(2000),
      lastDate  : DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _focusedDay     = DateTime(picked.year, picked.month, 1);
        _selectedDay    = _focusedDay;
        _selectedEvents = _getEventsForDay(_focusedDay);
      });
    }
  }

  /* 18(calendar_page.dart → _openDetail()) for editing / deleting entry */
  Future<void> _openDetail(Map<String, dynamic> e) async {
    final id       = e['id'] as int;
    final feelCtrl = TextEditingController(text: e['feeling']);
    final descCtrl = TextEditingController(text: e['description']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diary Detail'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: feelCtrl, decoration: const InputDecoration(labelText: 'Feeling')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _quickMoods.map((m) {
                  final sel = feelCtrl.text.toLowerCase() == m.toLowerCase();
                  return ChoiceChip(
                    label: Text(m),
                    selected: sel,
                    onSelected: (_) => setState(() => feelCtrl.text = sel ? '' : m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              await SQLHelper.updateDiary(id, feelCtrl.text, descCtrl.text);
              await _loadEvents();
              if (mounted) Navigator.pop(ctx);
            }),
          TextButton(
            style : TextButton.styleFrom(foregroundColor: Colors.red),
            child : const Text('Delete'),
            onPressed: () async {
              await SQLHelper.deleteDiary(id);
              await _loadEvents();
              if (mounted) Navigator.pop(ctx);
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme     = Theme.of(context).colorScheme;
    final monthLabel = DateFormat.yMMMM().format(_focusedDay);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))),
                GestureDetector(
                  onTap: _pickMonthYear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(monthLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
              ],
            ),
            /* 16(calendar_page.dart → TableCalendar) for monthly view with markers */
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay : DateTime.utc(2020, 1, 1),
              lastDay  : DateTime.utc(2100, 12, 31),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerVisible: false,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: _getEventsForDay,
              /* 17(calendar_page.dart → onDaySelected) for loading selected day’s entries */
              onDaySelected: (sel, foc) {
                setState(() {
                  _selectedDay    = sel;
                  _focusedDay     = foc;
                  _selectedEvents = _getEventsForDay(sel);
                });
              },
              onPageChanged: (foc) => setState(() => _focusedDay = foc),
              calendarStyle: CalendarStyle(markerDecoration:
                BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
            ),
            const Divider(height: 0),
            Expanded(
              child: _selectedEvents.isEmpty
                  ? const Center(child: Text('No entries'))
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _selectedEvents.length,
                      itemBuilder: (ctx, i) {
                        final e = _selectedEvents[i];
                        /* 19(calendar_page.dart → Dismissible) for swipe delete in calendar list */
                        return Dismissible(
                          key: ValueKey(e['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            await SQLHelper.deleteDiary(e['id']);
                            await _loadEvents();
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            child: ListTile(
                              onTap : () => _openDetail(e),
                              leading: CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                child: Text(_emoji(e['feeling']))),
                              title : Text(e['feeling'], style: Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(e['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: Text(e['date'].toString().substring(11,16),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
