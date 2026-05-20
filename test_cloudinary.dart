import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final List<int> bytes = [137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];
  File f = File('test.png');
  f.writeAsBytesSync(bytes);
  final request = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/darjm6tm0/image/upload'));
  request.fields['upload_preset'] = 'ABDULLAH-MASRY';
  request.files.add(await http.MultipartFile.fromPath('file', f.path));
  final res = await request.send();
  final resp = await http.Response.fromStream(res);
  print('Status: ${resp.statusCode}');
  print('Body: ${resp.body}');
}
