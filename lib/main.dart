import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const AnalisadorApp());
}

class AnalisadorApp extends StatelessWidget {
  const AnalisadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analisador de Crédito - Loca SIM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
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
  final TextEditingController _cpfController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _resultado;
  String? _erro;

  Future<void> _consultarCPF() async {
    // 1. Pega apenas os números digitados
    String cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cpf.length != 11) {
      setState(() {
        _erro = 'Por favor, digite um CPF válido com apenas 11 números.';
        _resultado = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
      _resultado = null;
    });

    try {
      // 2. Dispara o CPF para o seu backend em Python (Ajustaremos a URL amanhã)
      var uri = Uri.parse('https://analise-credito-67vk.onrender.com/analisar-cpf/');
      var response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"cpf": cpf}),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse.containsKey('erro')) {
          setState(() {
            _erro = jsonResponse['erro'];
            _resultado = null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _resultado = jsonResponse;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _erro = 'Erro no servidor: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro de conexão: Verifique se a API está online.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 50),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_search_outlined, size: 80, color: Colors.orangeAccent),
                const SizedBox(height: 20),
                const Text(
                  'Consulta Automática de Cliente',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Análise de Crédito e Antecedentes Judiciais integrados.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 40),
                
                // Novo Campo de Digitação de CPF
                SizedBox(
                  width: 350,
                  child: TextField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    maxLength: 11, // Trava em 11 digitos
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Só aceita números
                    decoration: InputDecoration(
                      labelText: 'CPF do Cliente (Apenas números)',
                      prefixIcon: const Icon(Icons.badge, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      counterText: "", // Esconde o contador "0/11" para ficar mais limpo
                    ),
                    onSubmitted: (_) => _consultarCPF(), // Permite dar "Enter" no teclado para buscar
                  ),
                ),
                const SizedBox(height: 25),

                // Botão de Consultar
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _consultarCPF,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: Text(_isLoading ? 'Buscando dados...' : 'Consultar Cliente'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                
                if (_erro != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_erro!, style: TextStyle(color: Colors.red.shade400, fontSize: 16)),
                  ),
                  
                if (_resultado != null) ...[
                  _construirPainelConsolidado(),
                  const SizedBox(height: 25),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _cpfController.clear();
                        _resultado = null;
                        _erro = null;
                      });
                    },
                    icon: const Icon(Icons.refresh, color: Colors.orange),
                    label: const Text('Fazer Nova Consulta', style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // OS CARDS ABAIXO CONTINUAM EXATAMENTE IGUAIS (pois a API devolverá o mesmo formato)
  // ============================================================================

  Widget _construirPainelConsolidado() {
    String statusGeral = _resultado!['status_geral'] ?? 'N/A';
    bool aprovado = statusGeral == 'APROVADO';
    Color corStatus = aprovado ? Colors.green.shade700 : Colors.red.shade700;

    var resSerasa = _resultado!['serasa'];
    var resDetetive = _resultado!['detetive'];

    return Column(
      children: [
        Container(
          width: 550,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: corStatus.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: corStatus, width: 2),
          ),
          child: Column(
            children: [
              const Text('PARECER FINAL DO CLIENTE', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 5),
              Text(
                statusGeral,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: corStatus),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            if (resSerasa != null) _construirCardSerasa(resSerasa),
            if (resDetetive != null) _construirCardDetetive(resDetetive),
          ],
        ),
      ],
    );
  }

  Widget _construirCardSerasa(Map<String, dynamic> serasa) {
    var detalhes = serasa['detalhes'] ?? {};
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('ANÁLISE FINANCEIRA (CRÉDITO)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            const Divider(height: 25),
            _linhaDetalhe('Status Financeiro', serasa['status'] ?? 'N/A'),
            _linhaDetalhe('Pontuação Calculada', '${serasa['pontuacao_total'] ?? 0} pts'),
            _linhaDetalhe('Score do Cliente', detalhes['score']?.toString() ?? 'N/A'),
            _linhaDetalhe('Atraso de Aluguel', (detalhes['teve_atraso_aluguel'] ?? false) ? 'SIM (Risco)' : 'Não'),
            _linhaDetalhe('Dívida Nu Financeira', 'R\$ ${detalhes['divida_nu_financeira'] ?? 0}'),
            _linhaDetalhe('Qtd. Protestos', detalhes['qtd_protestos']?.toString() ?? '0'),
            _linhaDetalhe('Total Pendências', 'R\$ ${detalhes['total_pendencias'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _construirCardDetetive(Map<String, dynamic> detetive) {
    var detalhes = detetive['detalhes'] ?? {};
    bool temCriminal = detalhes['tem_processo_criminal'].toString().contains('SIM');
    var tiposList = detalhes['tipos_processos'];
    String tiposListados = (tiposList is List) ? tiposList.join(', ') : tiposList.toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('ANTECEDENTES & JUDICIAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            const Divider(height: 25),
            _linhaDetalhe('1. Quantos Processos?', detalhes['qtd_processos']?.toString() ?? '0'),
            _linhaDetalhe('2. Tipos de Processos', tiposListados.isNotEmpty ? tiposListados : 'Nenhum'),
            _linhaDetalhe('3. Ativo ou Passivo?', detalhes['polaridade_processual'] ?? 'N/A'),
            _linhaDetalhe('4. Alienação Fiduciária', detalhes['alienacao_fiduciaria'] ?? 'Não'),
            _linhaDetalhe('5. Débitos de Aluguel', detalhes['debitos_aluguel'] ?? 'Não'),
            _linhaDetalhe(
              '6. Processo Criminal?', 
              detalhes['tem_processo_criminal'] ?? 'Não',
              valorCor: temCriminal ? Colors.red.shade400 : Colors.green.shade400,
            ),
            _linhaDetalhe('7. Tempo Processo Criminal', detalhes['tempo_processo_criminal'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _linhaDetalhe(String label, String valor, {Color? valorCor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
          Expanded(
            flex: 3,
            child: Text(
              valor, 
              style: TextStyle(fontWeight: FontWeight.bold, color: valorCor ?? Colors.white, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}