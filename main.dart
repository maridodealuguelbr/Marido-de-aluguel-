
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const navy = Color(0xFF142B36);
const gold = Color(0xFFE5A94B);
const muted = Color(0xFF718087);
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || anonKey.isEmpty) {
    runApp(const SetupRequiredApp());
    return;
  }
  await Supabase.initialize(url: url, anonKey: anonKey);
  runApp(const MaridoApp());
}

class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: const Scaffold(
      backgroundColor: navy,
      body: SafeArea(child: Center(child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.home_repair_service, color: gold, size: 72),
          SizedBox(height: 18),
          Text('MARIDO DE ALUGUEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 23)),
          SizedBox(height: 18),
          Text('Para ativar o aplicativo, configure SUPABASE_URL e SUPABASE_ANON_KEY conforme o README.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        ]),
      ))),
    ),
  );
}

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
  scaffoldBackgroundColor: const Color(0xFFF4F6F6),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF4F6F6), foregroundColor: navy, elevation: 0),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
  ),
);

class MaridoApp extends StatelessWidget {
  const MaridoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Marido de Aluguel', debugShowCheckedModeBanner: false, theme: appTheme,
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: supabase.auth.onAuthStateChange,
    builder: (context, snapshot) {
      final user = supabase.auth.currentUser;
      if (user == null) return const WelcomePage();
      return FutureBuilder<Map<String, dynamic>?>(
        future: supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
        builder: (context, profile) {
          if (profile.connectionState == ConnectionState.waiting) return const LoadingPage();
          final data = profile.data;
          if (data == null) return const CompleteProfilePage();
          return MainShell(isPro: data['role'] == 'professional', profile: data);
        },
      );
    },
  );
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => Column(children: const [
    Icon(Icons.home_repair_service_rounded, color: gold, size: 68),
    SizedBox(height: 12),
    Text('MARIDO DE ALUGUEL', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
    SizedBox(height: 5),
    Text('Seu profissional, a um clique.', style: TextStyle(color: gold, fontWeight: FontWeight.w600)),
  ]);
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(26), child: Column(
      children: [
        const Spacer(), const Brand(), const Spacer(),
        const Text('Encontre ajuda para sua casa ou receba novos serviços.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: navy, minimumSize: const Size.fromHeight(52)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage(role: 'customer'))),
          child: const Text('Quero contratar um serviço'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), minimumSize: const Size.fromHeight(52)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage(role: 'professional'))),
          child: const Text('Sou profissional'),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
          child: const Text('Já tenho conta • Entrar', style: TextStyle(color: Colors.white70))),
        const SizedBox(height: 16),
      ],
    ))),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      await supabase.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) { setState(() => error = e.message); }
    catch (e) { setState(() => error = 'Não foi possível entrar. Verifique sua conexão e tente novamente.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Entrar')),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      const SizedBox(height: 15), const Icon(Icons.home_repair_service, color: gold, size: 64),
      const Text('Acesse sua conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 25),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
      const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 20), FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Entrando...' : 'Entrar')),
    ]),
  );
}

class SignUpPage extends StatefulWidget {
  final String role;
  const SignUpPage({super.key, required this.role});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}
class _SignUpPageState extends State<SignUpPage> {
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(),
      city = TextEditingController(), state = TextEditingController(), password = TextEditingController();
  final bio = TextEditingController();
  String specialty = 'Elétrica';
  bool busy = false;
  String? error;
  final options = const ['Elétrica','Hidráulica','Pintura','Marmoraria','Marcenaria','Montagem de móveis','Pedreiro','Limpeza','Jardinagem','Ar-condicionado','Outro'];
  @override
  void dispose() { name.dispose(); phone.dispose(); email.dispose(); city.dispose(); state.dispose(); password.dispose(); bio.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'Informe nome, e-mail e senha com pelo menos 6 caracteres.'); return;
    }
    setState(() { busy = true; error = null; });
    try {
      final response = await supabase.auth.signUp(email: email.text.trim(), password: password.text);
      final user = response.user;
      if (user == null) throw Exception('Não foi possível criar o usuário.');
      if (response.session == null) {
        setState(() => error = 'Confira seu e-mail para confirmar a conta. Depois entre para concluir o perfil.');
      } else {
        await supabase.from('profiles').upsert({
          'id': user.id, 'role': widget.role, 'full_name': name.text.trim(),
          'phone': phone.text.trim(), 'email': email.text.trim(),
          'city': city.text.trim(), 'state': state.text.trim().toUpperCase(),
        });
        if (widget.role == 'professional') {
          await supabase.from('professional_profiles').upsert({
            'user_id': user.id, 'bio': bio.text.trim(), 'service_radius_km': 20,
          });
          final specialtyId = await supabase.from('specialties').select('id').eq('name', specialty).maybeSingle();
          if (specialtyId != null) {
            await supabase.from('professional_specialties').upsert({
              'professional_id': user.id, 'specialty_id': specialtyId['id'],
            });
          }
        }
        if (mounted) Navigator.pop(context);
      }
    } on AuthException catch (e) { setState(() => error = e.message); }
    catch (e) { setState(() => error = 'Falha no cadastro. Confira a configuração do banco e tente novamente.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar conta')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.role == 'professional' ? 'Cadastro profissional' : 'Cadastro de cliente',
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 16),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo')),
      const SizedBox(height: 10), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp')),
      const SizedBox(height: 10), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
      const SizedBox(height: 10), Row(children: [
        Expanded(child: TextField(controller: city, decoration: const InputDecoration(labelText: 'Cidade'))),
        const SizedBox(width: 10), SizedBox(width: 82, child: TextField(controller: state, maxLength: 2, decoration: const InputDecoration(labelText: 'UF', counterText: ''))),
      ]),
      if (widget.role == 'professional') ...[
        const SizedBox(height: 10), DropdownButtonFormField<String>(value: specialty, decoration: const InputDecoration(labelText: 'Especialidade principal'),
          items: options.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => specialty = v ?? specialty)),
        const SizedBox(height: 10), TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Apresente seus serviços e região atendida')),
      ],
      const SizedBox(height: 10), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha (mínimo 6 caracteres)')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 20), FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Criando conta...' : 'Criar conta')),
    ]),
  );
}

class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_add_alt_1, size: 56, color: navy),
      const SizedBox(height: 12), const Text('Finalize seu cadastro', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('Sua conta foi autenticada. Saia e faça o cadastro novamente ou complete o perfil pelo painel administrativo do Supabase.'),
      const SizedBox(height: 18), FilledButton(onPressed: () => supabase.auth.signOut(), child: const Text('Sair')),
    ]))),
  );
}

const categories = [
  ('Elétrica', Icons.electrical_services), ('Hidráulica', Icons.plumbing),
  ('Pintura', Icons.format_paint), ('Marmoraria', Icons.view_quilt),
  ('Marcenaria', Icons.carpenter), ('Montagem de móveis', Icons.chair),
  ('Pedreiro', Icons.foundation), ('Limpeza', Icons.cleaning_services),
  ('Jardinagem', Icons.yard), ('Ar-condicionado', Icons.ac_unit),
];

class MainShell extends StatefulWidget {
  final bool isPro;
  final Map<String, dynamic> profile;
  const MainShell({super.key, required this.isPro, required this.profile});
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      widget.isPro ? ProHomePage(profile: widget.profile) : CustomerHomePage(profile: widget.profile),
      OrdersPage(isPro: widget.isPro),
      ProfilePage(profile: widget.profile),
    ];
    return Scaffold(
      appBar: AppBar(title: Row(children: const [
        Icon(Icons.home_repair_service, color: gold, size: 30), SizedBox(width: 8),
        Text('Marido de Aluguel', style: TextStyle(fontWeight: FontWeight.bold)),
      ])),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ]),
    );
  }
}

class CustomerHomePage extends StatelessWidget {
  final Map<String, dynamic> profile;
  const CustomerHomePage({super.key, required this.profile});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(20)),
      child: Text('Olá, ${profile['full_name'] ?? 'cliente'}!\nEncontre profissionais na sua região.',
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
    const SizedBox(height: 20), const Text('Qual serviço você precisa?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (_, i) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewRequestPage(category: categories[i].$1))),
        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [Icon(categories[i].$2, color: gold), const SizedBox(width: 8), Expanded(child: Text(categories[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)))])))),
  ]);
}

class ProHomePage extends StatelessWidget {
  final Map<String, dynamic> profile;
  const ProHomePage({super.key, required this.profile});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(20)),
      child: Text('Olá, ${profile['full_name'] ?? 'profissional'}!\nVeja oportunidades de serviço na sua região.',
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
    const SizedBox(height: 18), const Text('Pedidos disponíveis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10), const OpenRequestsList(),
  ]);
}

class OpenRequestsList extends StatelessWidget {
  const OpenRequestsList({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: supabase.from('service_requests').select('id, description, address_area, urgency, created_at, specialties(name)').eq('status', 'open').order('created_at', ascending: false).limit(30),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return const Text('Não foi possível carregar pedidos. Confira as políticas do banco.');
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Text('Ainda não há pedidos abertos.');
      return Column(children: rows.map((r) => Card(color: Colors.white, child: ListTile(
        title: Text((r['specialties']?['name'] ?? 'Serviço').toString()),
        subtitle: Text('${r['description']}\n${r['address_area'] ?? 'Região não informada'}'),
        isThreeLine: true,
      ))).toList());
    },
  );
}

class NewRequestPage extends StatefulWidget {
  final String category;
  const NewRequestPage({super.key, required this.category});
  @override
  State<NewRequestPage> createState() => _NewRequestPageState();
}
class _NewRequestPageState extends State<NewRequestPage> {
  final description = TextEditingController(), area = TextEditingController();
  String urgency = 'Sem urgência';
  bool busy = false;
  String? error;
  @override
  void dispose() { description.dispose(); area.dispose(); super.dispose(); }
  Future<void> send() async {
    if (description.text.trim().isEmpty) { setState(() => error = 'Descreva o serviço que precisa.'); return; }
    setState(() { busy = true; error = null; });
    try {
      final specialty = await supabase.from('specialties').select('id').eq('name', widget.category).maybeSingle();
      await supabase.from('service_requests').insert({
        'customer_id': supabase.auth.currentUser!.id,
        'specialty_id': specialty?['id'],
        'description': description.text.trim(),
        'address_area': area.text.trim(),
        'urgency': urgency,
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido enviado!'))); Navigator.pop(context); }
    } catch (e) { setState(() => error = 'Não foi possível enviar. Verifique sua conexão e as permissões do banco.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Solicitar orçamento')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.category, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 14), TextField(controller: description, maxLines: 5, decoration: const InputDecoration(labelText: 'Descreva o serviço')),
      const SizedBox(height: 12), TextField(controller: area, decoration: const InputDecoration(labelText: 'Bairro, cidade e UF')),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: urgency, decoration: const InputDecoration(labelText: 'Prazo'),
        items: ['Sem urgência','O quanto antes','Data combinada'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => urgency = v ?? urgency)),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 20), FilledButton(onPressed: busy ? null : send, child: Text(busy ? 'Enviando...' : 'Enviar pedido')),
    ]),
  );
}

class OrdersPage extends StatelessWidget {
  final bool isPro;
  const OrdersPage({super.key, required this.isPro});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: isPro
      ? supabase.from('service_requests').select('id, description, status, address_area, created_at').eq('status', 'open').order('created_at', ascending: false).limit(50)
      : supabase.from('service_requests').select('id, description, status, address_area, created_at').eq('customer_id', supabase.auth.currentUser!.id).order('created_at', ascending: false),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return const Center(child: Text('Erro ao carregar pedidos. Verifique a configuração do banco.'));
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('Nenhum pedido por enquanto.'));
      return ListView(padding: const EdgeInsets.all(14), children: rows.map((r) => Card(color: Colors.white, child: ListTile(
        title: Text(r['description'] ?? 'Solicitação'),
        subtitle: Text('${r['address_area'] ?? ''} • ${r['status'] ?? 'open'}'),
      ))).toList());
    },
  );
}

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> profile;
  const ProfilePage({super.key, required this.profile});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Card(color: Colors.white, child: ListTile(
      leading: const CircleAvatar(backgroundColor: navy, child: Icon(Icons.person, color: gold)),
      title: Text(profile['full_name'] ?? 'Usuário'), subtitle: Text('${profile['city'] ?? ''} / ${profile['state'] ?? ''}'),
    )),
    const SizedBox(height: 12), Card(color: Colors.white, child: ListTile(title: const Text('E-mail'), subtitle: Text(profile['email'] ?? ''))),
    Card(color: Colors.white, child: ListTile(title: const Text('WhatsApp'), subtitle: Text(profile['phone'] ?? 'Não informado'))),
    const SizedBox(height: 20), OutlinedButton.icon(
      onPressed: () async => supabase.auth.signOut(),
      icon: const Icon(Icons.logout), label: const Text('Sair da conta'),
    ),
  ]);
}
