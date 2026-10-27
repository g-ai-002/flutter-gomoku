/// 对局记录服务：按平台选择实现——IO 平台落盘 JSON 文件，Web 平台使用
/// SharedPreferences。
library;

export 'game_record_service_io.dart'
    if (dart.library.js_interop) 'game_record_service_web.dart';
