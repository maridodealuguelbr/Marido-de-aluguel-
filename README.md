# Marido de Aluguel — versão inicial

Aplicativo Flutter com identidade visual azul-marinho, dourado e branco.

## O que está incluído
- Tela inicial com escolha entre cliente e profissional.
- Telas de login e cadastro demonstrativas.
- Início do cliente com categorias e formulário de solicitação.
- Início do profissional, pedidos e perfil.
- Esquema SQL inicial para Supabase.

## Executar
1. Instale o Flutter SDK e configure Android Studio ou Xcode.
2. Na pasta do projeto, execute `flutter pub get`.
3. Execute `flutter run`.

## Estado do projeto
Esta entrega é um **protótipo funcional de navegação**, não uma plataforma pronta para operar com clientes reais. Login/cadastro, envio de pedidos, fotos, localização, chat, pagamentos, comissão, avaliações e painel administrativo ainda precisam ser conectados e testados. O esquema SQL é inicial; configure autenticação, RLS, armazenamento e políticas de privacidade antes de usar dados reais.

## Próximas etapas técnicas
1. Criar projeto Supabase e configurar variáveis/segredos fora do código.
2. Implementar autenticação e perfis com permissões RLS.
3. Implementar upload de fotos e busca geográfica por área de atendimento.
4. Implementar propostas, contratação, chat e notificações.
5. Integrar gateway de pagamento com split/comissão e validar regras comerciais.
6. Criar painel administrativo, testes, termos, política LGPD e publicação nas lojas.
