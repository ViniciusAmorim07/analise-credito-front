import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// URL centralizada do backend no Render
const String kBaseUrl = 'https://analise-credito-67vk.onrender.com';

void main() {
  runApp(const AnalisadorApp());
}

class AnalisadorApp extends StatefulWidget {
  const AnalisadorApp({super.key});

  @override
  State<AnalisadorApp> createState() => _AnalisadorAppState();
}

class _AnalisadorAppState extends State<AnalisadorApp> {
  String? _token;
  Map<String, dynamic>? _usuario;

  void _aoLogar(String token, Map<String, dynamic> usuario) {
    setState(() {
      _token = token;
      _usuario = usuario;
    });
  }

  void _aoSair() {
    setState(() {
      _token = null;
      _usuario = null;
    });
  }

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
      home: (_token == null || _usuario == null)
          ? LoginScreen(onLoginSuccess: _aoLogar)
          : TelaAnalisador(
              token: _token!,
              usuario: _usuario!,
              onLogout: _aoSair,
            ),
    );
  }
}

// ============================================================================
// 1. TELA DE LOGIN
// ============================================================================
class LoginScreen extends StatefulWidget {
  final Function(String token, Map<String, dynamic> usuario) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _ocultarSenha = true;
  String? _erro;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (_loginController.text.trim().isEmpty || _senhaController.text.trim().isEmpty) {
      setState(() => _erro = "Preencha login e senha.");
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final response = await http.post(
        Uri.parse("$kBaseUrl/login/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "login": _loginController.text.trim(),
          "senha": _senhaController.text.trim(),
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        widget.onLoginSuccess(data["token"], Map<String, dynamic>.from(data["usuario"]));
      } else {
        setState(() {
          _erro = data["detail"] ?? "Falha ao autenticar.";
        });
      }
    } catch (e) {
      setState(() {
        _erro = "Erro de conexão com o servidor. Aguarde alguns segundos e tente novamente.";
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14110F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1916),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, size: 54, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  "Acesso Restrito — LocaSIM",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Identifique-se para realizar consultas de crédito",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _loginController,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Login do Vendedor",
                    labelStyle: const TextStyle(color: Colors.amber),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.amber),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: _ocultarSenha,
                  onSubmitted: (_) => _fazerLogin(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Senha",
                    labelStyle: const TextStyle(color: Colors.amber),
                    prefixIcon: const Icon(Icons.key_outlined, color: Colors.amber),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text("Entrar no Sistema", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. TELA PRINCIPAL DE CONSULTA DE CPF
// ============================================================================
class TelaAnalisador extends StatefulWidget {
  final String token;
  final Map<String, dynamic> usuario;
  final VoidCallback onLogout;

  const TelaAnalisador({
    super.key,
    required this.token,
    required this.usuario,
    required this.onLogout,
  });

  @override
  State<TelaAnalisador> createState() => _TelaAnalisadorState();
}

class _TelaAnalisadorState extends State<TelaAnalisador> {
  final TextEditingController _cpfController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _resultado;
  String? _erro;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _consultarCPF() async {
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
      var uri = Uri.parse('$kBaseUrl/analisar-cpf/');
      var response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({"cpf": cpf}),
      );

      if (response.statusCode == 401) {
        widget.onLogout();
        return;
      }

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

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
        final erroBody = utf8.decode(response.bodyBytes);
        setState(() {
          _erro = 'Erro no servidor (${response.statusCode}): $erroBody';
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
    final bool ehAdmin = widget.usuario['perfil'] == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 45),
        backgroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: 180,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Icon(Icons.person_pin, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.usuario['nome'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (ehAdmin)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PainelAdminLogs(token: widget.token),
                  ),
                );
              },
              icon: Icon(Icons.receipt_long, color: Colors.orange.shade900, size: 20),
              label: Text(
                "Custos & Logs",
                style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(
            tooltip: "Sair do sistema",
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, color: Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
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

                // Campo de Digitação de CPF
                SizedBox(
                  width: 350,
                  child: TextField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'CPF do Cliente (Apenas números)',
                      prefixIcon: const Icon(Icons.badge, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      counterText: "",
                    ),
                    onSubmitted: (_) => _consultarCPF(),
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
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _erro!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade400, fontSize: 16),
                    ),
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
  // PAINEL DE RESULTADOS + AVISO DE BLOQUEIO 60 DIAS
  // ============================================================================
  Widget _construirPainelConsolidado() {
    String statusGeral = _resultado!['status_geral'] ?? 'N/A';
    bool aprovado = statusGeral == 'APROVADO';
    Color corStatus = aprovado ? Colors.green.shade700 : Colors.red.shade700;

    var resSerasa = _resultado!['serasa'];
    var resDetetive = _resultado!['detetive'];
    var bloqueio60d = _resultado!['bloqueio_60_dias'];

    return Column(
      children: [
        // Aviso quando o CPF já foi consultado nos últimos 60 dias (custo R$ 0,00)
        if (bloqueio60d != null && bloqueio60d['ativo'] == true)
          Container(
            width: 550,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_toggle_off, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bloqueio60d['mensagem'] ?? 'Consulta reaproveitada do histórico (60 dias).',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

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
            const Text(
              'ANÁLISE FINANCEIRA (CRÉDITO)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const Divider(height: 25),
            _linhaDetalhe('Status Financeiro', serasa['status'] ?? 'N/A'),
            _linhaDetalhe('Pontuação Calculada', '${serasa['pontuacao_total'] ?? 0} pts'),
            _linhaDetalhe('Score do Cliente', detalhes['score']?.toString() ?? 'N/A'),
            _linhaDetalhe('Atraso de Aluguel',
              financeiro['atraso_aluguel'] ?? 'Não',
              valorCor: (financeiro['atraso_aluguel'] ?? 'Não') != 'Não'
                  ? ((financeiro['atraso_aluguel'] ?? '').toString().contains('|')
                      ? Colors.red.shade400
                      : Colors.amber)
                  : null,
           ),
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
    String textoCriminal = detalhes['tem_processo_criminal']?.toString() ?? 'Não';
    bool temReprovacaoCriminal = textoCriminal.contains('Reprovado');
    bool temApontamentoCriminal = textoCriminal.contains('Apontamento');

    Color corCriminal = Colors.green.shade400;
    if (temReprovacaoCriminal) {
      corCriminal = Colors.red.shade400;
    } else if (temApontamentoCriminal) {
      corCriminal = Colors.amber;
    }

    var tiposList = detalhes['tipos_processos'];
    String tiposListados = (tiposList is List) ? tiposList.join(', ') : tiposList.toString();
    List apontamentos = (detalhes['apontamentos_judiciais'] as List?) ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'ANTECEDENTES & JUDICIAL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const Divider(height: 25),
            _linhaDetalhe('1. Quantos Processos?', detalhes['qtd_processos']?.toString() ?? '0'),
            _linhaDetalhe('2. Tipos de Processos', tiposListados.isNotEmpty ? tiposListados : 'Nenhum'),
            _linhaDetalhe('3. Ativo ou Passivo?', detalhes['polaridade_processual'] ?? 'N/A'),
            _linhaDetalhe(
              '4. Alienação Fiduciária',
              detalhes['alienacao_fiduciaria'] ?? 'Não',
              valorCor: (detalhes['alienacao_fiduciaria'] ?? '').toString().startsWith('Sim')
                  ? Colors.amber
                  : null,
            ),
            _linhaDetalhe('5. Débitos de Aluguel', detalhes['debitos_aluguel'] ?? 'Não'),
            _linhaDetalhe(
              '6. Processo Criminal?',
              textoCriminal,
              valorCor: corCriminal,
            ),
            _linhaDetalhe('7. Tempo Processo Criminal', detalhes['tempo_processo_criminal'] ?? 'N/A'),
            if (apontamentos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Apontamentos Judiciais (Sem reprovação automática):",
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    ...apontamentos.map(
                      (a) => Text(
                        "• $a",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

// ============================================================================
// 3. PAINEL ADMINISTRATIVO DE LOGS E CUSTOS (APENAS PERFIL ADMIN)
// ============================================================================
class PainelAdminLogs extends StatefulWidget {
  final String token;

  const PainelAdminLogs({super.key, required this.token});

  @override
  State<PainelAdminLogs> createState() => _PainelAdminLogsState();
}

class _PainelAdminLogsState extends State<PainelAdminLogs> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _dados;

  @override
  void initState() {
    super.initState();
    _carregarLogs();
  }

  Future<void> _carregarLogs() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resp = await http.get(
        Uri.parse("$kBaseUrl/logs/"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (resp.statusCode == 200) {
        setState(() {
          _dados = jsonDecode(utf8.decode(resp.bodyBytes));
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = "Não foi possível carregar os logs (${resp.statusCode}).";
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = "Erro de conexão ao buscar logs.";
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14110F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1916),
        title: const Text("Auditoria de Consultas e Custos", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.amber),
        actions: [
          IconButton(
            tooltip: "Atualizar",
            onPressed: _carregarLogs,
            icon: const Icon(Icons.refresh, color: Colors.amber),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.redAccent)))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _cardResumo("Gasto Relinq", "R\$ ${_dados?['custo_total_brl'] ?? 0}", Colors.redAccent),
                          const SizedBox(width: 12),
                          _cardResumo("Economia (60d)", "R\$ ${_dados?['economia_total_brl'] ?? 0}", Colors.greenAccent),
                          const SizedBox(width: 12),
                          _cardResumo("Consultas Pagas", "${_dados?['total_consultas_pagas'] ?? 0}", Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: (_dados?['logs'] as List? ?? []).length,
                          itemBuilder: (context, index) {
                            final item = _dados!['logs'][index];
                            final ehCache = item['origem'] == 'BLOQUEIO_60D_CACHE';
                            final dataStr = (item['consultado_em'] ?? '').toString();
                            final dataFormatada = dataStr.length >= 16
                                ? dataStr.substring(0, 16).replaceAll('T', ' ')
                                : dataStr;

                            return Card(
                              color: const Color(0xFF1E1916),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  ehCache ? Icons.shield_outlined : Icons.paid_outlined,
                                  color: ehCache ? Colors.greenAccent : Colors.amber,
                                ),
                                title: Text(
                                  "CPF: ${item['cpf_consultado']}  •  ${item['status_geral']}",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Vendedor: ${item['usuario_nome']} (${item['usuario_login']})  •  $dataFormatada",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                trailing: Text(
                                  ehCache ? "R\$ 0,00 (Cache 60d)" : "R\$ 10,49",
                                  style: TextStyle(
                                    color: ehCache ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _cardResumo(String titulo, String valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1916),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(valor, style: TextStyle(color: cor, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}