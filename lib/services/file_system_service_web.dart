/// Web 平台：日志仅保留在内存，没有可打开的本地目录。
class FileSystemService {
  FileSystemService._(this.appDirName);

  static final FileSystemService instance = FileSystemService._(
    'CarrotDefense',
  );

  final String appDirName;

  Future<String> getLogRootPath() async => '';

  Future<bool> openDirectory(String path) async => false;
}
