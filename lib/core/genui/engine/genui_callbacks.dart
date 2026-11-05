import '../models/genui_action.dart';
import '../models/genui_option.dart';

typedef GenUiActionCallback = void Function(GenUiAction action);
typedef GenUiOptionCallback = void Function(GenUiOption option);
typedef GenUiMultiOptionCallback = void Function(List<GenUiOption> selectedOptions);
typedef GenUiInputCallback = void Function(Map<String, dynamic> data);
typedef GenUiVoidCallback = void Function();

