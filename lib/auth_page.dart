import 'package:flutter/material.dart';

import 'api.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      lastName = TextEditingController(),
      phone = TextEditingController(),
      registerNumber = TextEditingController(),
      confirmPassword = TextEditingController();
  String? position;
  static const positions = [
    'Шүдний эмч',
    'Сувилагч',
    'Шүдний техникч',
    'Эмнэлгийн удирдлага',
    'Оюутан',
    'Бусад',
  ];
  bool register = false, busy = false, hide = true;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    lastName.dispose();
    phone.dispose();
    registerNumber.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await OyudentApi.instance.authenticate(
        email.text.trim(),
        password.text,
        name: register ? name.text.trim() : null,
        registration: register
            ? {
                'phone': phone.text.trim(),
                'registerNumber': registerNumber.text.trim().toUpperCase(),
                'lastName': lastName.text.trim(),
                'position': position!,
                'confirmPassword': confirmPassword.text,
              }
            : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Oyudent бүртгэл')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 60,
                  color: Color(0xFF5351EE),
                ),
                const SizedBox(height: 20),
                Text(
                  register ? 'Бүртгэл үүсгэх' : 'Тавтай морил',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Орон нутгийн туршилтын сервер. Бодит үйлчилгээний нууц үгээ бүү ашиглаарай.',
                ),
                const SizedBox(height: 24),
                if (register) ...[
                  TextFormField(
                    controller: phone,
                    enabled: !busy,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Утасны дугаар',
                    ),
                    validator: (v) =>
                        RegExp(r'^(\+976)?[0-9]{8}$').hasMatch((v ?? '').trim())
                        ? null
                        : '8 оронтой утасны дугаар оруулна уу',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: registerNumber,
                    enabled: !busy,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Регистрийн дугаар',
                    ),
                    validator: (v) =>
                        RegExp(r'^[А-ЯӨҮа-яөү]{2}[0-9]{8}$')
                            .hasMatch((v ?? '').trim())
                        ? null
                        : '2 кирилл үсэг, 8 цифр оруулна уу',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: lastName,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Овог'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty || v.trim().length > 80
                        ? 'Овгоо оруулна уу (80 хүртэл тэмдэгт)'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Нэр'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty || v.trim().length > 80
                        ? 'Нэрээ оруулна уу'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Имэйл'),
                  validator: (v) =>
                      v == null ||
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v.trim())
                      ? 'Зөв имэйл оруулна уу'
                      : null,
                ),
                const SizedBox(height: 16),
                if (register) ...[
                  DropdownButtonFormField<String>(
                    initialValue: position,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Албан тушаал',
                    ),
                    items: positions
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: busy
                        ? null
                        : (v) => setState(() => position = v),
                    validator: (v) =>
                        v == null ? 'Албан тушаалаа сонгоно уу' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: password,
                  enabled: !busy,
                  obscureText: hide,
                  decoration: InputDecoration(
                    labelText: 'Нууц үг',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => hide = !hide),
                      icon: Icon(
                        hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 8 || v.length > 128
                      ? '8–128 тэмдэгт оруулна уу'
                      : null,
                  onFieldSubmitted: (_) {
                    if (!busy) submit();
                  },
                ),
                if (register) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPassword,
                    enabled: !busy,
                    obscureText: hide,
                    decoration: const InputDecoration(
                      labelText: 'Нууц үг давтах',
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Нууц үгээ давтан оруулна уу'
                        : v != password.text
                        ? 'Нууц үг таарахгүй байна'
                        : null,
                    onFieldSubmitted: (_) {
                      if (!busy) submit();
                    },
                  ),
                ],
                const SizedBox(height: 20),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(
                    busy
                        ? 'Түр хүлээнэ үү…'
                        : register
                        ? 'Бүртгүүлэх'
                        : 'Нэвтрэх',
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          register = !register;
                          error = null;
                        }),
                  child: Text(
                    register
                        ? 'Бүртгэлтэй юу? Нэвтрэх'
                        : 'Шинэ хэрэглэгч үү? Бүртгүүлэх',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
