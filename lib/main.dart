import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html; // Usando a biblioteca nativa da Web!

void main() {
  runApp(const AnalisadorApp());
}

class AnalisadorApp extends StatelessWidget {
  const AnalisadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analisador de Crédito',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // Aplica o fundo escuro
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const TelaAnalisador(),
    );
  }
}

class TelaAnalisador extends StatefulWidget {
  const TelaAnalisador({super.key});

  @override
  State<TelaAnalisador> createState() => _TelaAnalisadorState();
}

class _TelaAnalisadorState extends State<TelaAnalisador> {
  bool _isLoading = false;
  Map<String, dynamic>? _resultado;
  String? _erro;

  void _selecionarEEnviarArquivo() {
    // 1. Cria um "botão invisível" de upload nativo do navegador
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.pdf';
    uploadInput.click();

    // 2. Fica a escutar quando o utilizador escolher o ficheiro
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();

        setState(() {
          _isLoading = true;
          _resultado = null;
          _erro = null;
        });

        // 3. Lê o ficheiro e envia para a API quando terminar
        reader.onLoadEnd.listen((e) async {
          var fileBytes = reader.result as List<int>;
          var fileName = file.name;

          try {
            var uri = Uri.parse('http://127.0.0.1:8000/analisar-pdf/');
            var request = http.MultipartRequest('POST', uri);

            request.files.add(http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: fileName,
            ));

            var response = await request.send();
            var responseData = await response.stream.bytesToString();

            if (response.statusCode == 200) {
              setState(() {
                _resultado = jsonDecode(responseData);
                _isLoading = false;
              });
            } else {
              setState(() {
                _erro = 'Erro no servidor: ${response.statusCode}';
                _isLoading = false;
              });
            }
          } catch (e) {
            setState(() {
              _erro = 'Erro de conexão: Não foi possível aceder à API. Verifique se o Python está a correr.';
              _isLoading = false;
            });
          }
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 50),
        backgroundColor: const Color.fromARGB(255, 252, 252, 252), 
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 20),
                const Text(
                  'Envie o PDF da Serasa Experian para avaliar o cliente',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _selecionarEEnviarArquivo,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(_isLoading ? 'A analisar...' : 'Fazer Upload do PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 40),
                if (_erro != null)
                  Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                if (_resultado != null)
                  _construirCardResultado(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCardResultado() {
    bool aprovado = _resultado!['status'] == 'APROVADO';
    Color corStatus = aprovado ? Colors.green.shade700 : Colors.red.shade700;
    var detalhes = _resultado!['detalhes'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: corStatus.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _resultado!['status'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: corStatus),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pontuação Total: ${_resultado!['pontuacao_total']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Divider(height: 30),
            _linhaDetalhe('Score Serasa', detalhes['score'].toString()),
            _linhaDetalhe('Atraso Aluguer', detalhes['teve_atraso_aluguel'] ? 'Sim' : 'Não'),
            _linhaDetalhe('Dívida Nu Financeira', 'R\$ ${detalhes['divida_nu_financeira']}'),
            _linhaDetalhe('Protestos', detalhes['qtd_protestos'].toString()),
            _linhaDetalhe('Total Pendências', 'R\$ ${detalhes['total_pendencias']}'),
          ],
        ),
      ),
    );
  }

  Widget _linhaDetalhe(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}