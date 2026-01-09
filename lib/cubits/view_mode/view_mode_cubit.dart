import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode { grid, list }

class ViewModeCubit extends Cubit<ViewMode> {
  final SharedPreferences prefs;

  ViewModeCubit(this.prefs) : super(ViewMode.grid) {
    _loadViewMode();
  }

  void _loadViewMode() {
    final isGrid = prefs.getBool('isGridView') ?? true;
    emit(isGrid ? ViewMode.grid : ViewMode.list);
  }

  void toggleViewMode() {
    final newMode = state == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    prefs.setBool('isGridView', newMode == ViewMode.grid);
    emit(newMode);
  }
}