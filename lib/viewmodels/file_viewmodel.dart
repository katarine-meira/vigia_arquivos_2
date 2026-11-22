import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/file_model.dart';
import '../services/file_service.dart';

class FileViewModel extends ChangeNotifier {
  final FileService _service;
  StreamSubscription<List<FileModel>>? _filesSub;

  FileViewModel(this._service);

  List<FileModel> _files = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;
  PlatformFile? _selectedFile;

  List<FileModel> get files => _files;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;
  PlatformFile? get selectedFile => _selectedFile;
  int get fileCount => _files.length;

  /// Inicia a escuta em tempo real dos arquivos do usuário
  void init(String userId) {
    if (userId.isEmpty) return;

    _filesSub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _filesSub = _service.getUserFilesStream(userId).listen(
      (list) {
        _files = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('DEBUG: Erro no Firestore Stream: $err');
        _isLoading = false;
        _error = 'Não foi possível sincronizar com o banco. Verifique as regras do Firestore.';
        notifyListeners();
      },
    );
  }

  /// Abre o seletor para o usuário escolher um arquivo
  Future<void> pickFile() async {
    try {
      final file = await _service.pickFile();
      if (file != null) {
        _selectedFile = file;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DEBUG: Erro ao selecionar arquivo: $e');
      _error = 'Erro ao selecionar o arquivo.';
      notifyListeners();
    }
  }

  void clearSelectedFile() {
    _selectedFile = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Faz o upload do arquivo selecionado
  Future<bool> uploadSelectedFile(String userId) async {
    if (_selectedFile == null) return false;

    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.uploadFile(
        file: _selectedFile!,
        ownerId: userId,
      );
      _selectedFile = null;
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DEBUG: Erro no upload/gravação Firestore: $e');
      _isUploading = false;
      _error = 'Erro ao salvar no banco. Verifique as regras do Firestore no Console.';
      notifyListeners();
      return false;
    }
  }

  /// Exclui um arquivo
  Future<bool> deleteFile(FileModel file) async {
    try {
      await _service.deleteFile(file);
      return true;
    } catch (e) {
      debugPrint('DEBUG: Erro ao excluir arquivo: $e');
      _error = 'Erro ao excluir o arquivo.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _filesSub?.cancel();
    super.dispose();
  }
}
