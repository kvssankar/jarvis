// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Shots Studio';

  @override
  String get searchScreenshots => 'Поиск скриншотов';

  @override
  String analyzed(int count, int total) {
    return 'Проанализировано $count/$total';
  }

  @override
  String get developerModeDisabled => 'Расширенные настройки отключены';

  @override
  String get collections => 'Коллекции';

  @override
  String get screenshots => 'Скриншоты';

  @override
  String get settings => 'Настройки';

  @override
  String get about => 'О программе';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get createCollection => 'Создать коллекцию';

  @override
  String get editCollection => 'Редактировать коллекцию';

  @override
  String get deleteCollection => 'Удалить коллекцию';

  @override
  String get collectionName => 'Название коллекции';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get ok => 'ОК';

  @override
  String get search => 'Поиск';

  @override
  String get noResults => 'Результаты не найдены';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get share => 'Поделиться';

  @override
  String get copy => 'Копировать';

  @override
  String get paste => 'Вставить';

  @override
  String get selectAll => 'Выбрать всё';

  @override
  String get aiSettings => 'Настройки ИИ';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get modelName => 'Модель ИИ';

  @override
  String get autoProcessing => 'Автообработка';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Отключено';

  @override
  String get theme => 'Тема';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Темная';

  @override
  String get systemTheme => 'Системная';

  @override
  String get language => 'Язык';

  @override
  String get analytics => 'Аналитика';

  @override
  String get betaTesting => 'Бета-тестирование';

  @override
  String get advancedSettings => 'Расширенные настройки';

  @override
  String get developerMode => 'Расширенные настройки';

  @override
  String get safeDelete => 'Безопасное удаление';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get support => 'Поддержка';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get privacyNotice => 'Уведомление о конфиденциальности';

  @override
  String get analyticsAndTelemetry => 'Аналитика и телеметрия';

  @override
  String get performanceMenu => 'Меню производительности';

  @override
  String get serverMessages => 'Сообщения сервера';

  @override
  String get maxParallelAI => 'Максимум параллельных ИИ';

  @override
  String get enableScreenshotLimit => 'Включить лимит скриншотов';

  @override
  String get tags => 'Теги';

  @override
  String get aiDetails => 'Детали ИИ';

  @override
  String get size => 'Размер';

  @override
  String get addDescription => 'Добавить описание';

  @override
  String get addTag => 'Добавить тег';

  @override
  String get amoledMode => 'Режим AMOLED';

  @override
  String get notifications => 'Уведомления';

  @override
  String get permissions => 'Разрешения';

  @override
  String get storage => 'Хранилище';

  @override
  String get camera => 'Камера';

  @override
  String get version => 'Версия';

  @override
  String get buildNumber => 'Номер сборки';

  @override
  String get ocrResults => 'Результаты OCR';

  @override
  String get extractedText => 'Извлеченный текст';

  @override
  String get noTextFound => 'Текст в изображении не найден';

  @override
  String get processing => 'Обработка...';

  @override
  String get selectImage => 'Выбрать изображение';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get fromGallery => 'Из галереи';

  @override
  String get imageSelected => 'Изображение выбрано';

  @override
  String get noImageSelected => 'Изображение не выбрано';

  @override
  String get apiKeyRequired => 'Требуется для функций ИИ';

  @override
  String get apiKeyValid => 'API-ключ действителен';

  @override
  String get apiKeyValidationFailed => 'Проверка API-ключа не удалась';

  @override
  String get apiKeyNotValidated => 'API-ключ установлен (не проверен)';

  @override
  String get enterApiKey => 'Введите API-ключ Gemini';

  @override
  String get validateApiKey => 'Проверить API-ключ';

  @override
  String get valid => 'Действителен';

  @override
  String get autoProcessingDescription =>
      'Скриншоты будут автоматически обрабатываться при добавлении';

  @override
  String get manualProcessingOnly => 'Только ручная обработка';

  @override
  String get amoledModeDescription =>
      'Темная тема, оптимизированная для AMOLED-экранов';

  @override
  String get defaultDarkTheme => 'Стандартная темная тема';

  @override
  String get getApiKey => 'Получить API-ключ';

  @override
  String get stopProcessing => 'Остановить обработку';

  @override
  String get processWithAI => 'Обработать с ИИ';

  @override
  String get createFirstCollection => 'Создайте свою первую коллекцию, чтобы';

  @override
  String get organizeScreenshots => 'организовать ваши скриншоты';

  @override
  String get cancelSelection => 'Отменить выбор';

  @override
  String get deselectAll => 'Отменить выбор';

  @override
  String get deleteSelected => 'Удалить выбранные';
}
