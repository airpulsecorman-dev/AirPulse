import 'package:redux/redux.dart';
import 'app_state.dart';
import 'reducers/app_reducer.dart';
import 'middleware/app_middleware.dart';

Store<AppState> createStore() {
  return Store<AppState>(
    appReducer,
    initialState: const AppState(),
    middleware: appMiddleware,
  );
}
