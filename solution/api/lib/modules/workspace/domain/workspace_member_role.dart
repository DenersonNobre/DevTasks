/// Papel do usuário dentro do workspace (D-02 / SPEC §7 / Apêndice A).
///
/// Três papéis válidos:
/// - `owner`: controle total e gestão de membros;
/// - `developer`: gestão de projetos e tarefas;
/// - `viewer`: somente leitura.
enum WorkspaceMemberRole {
  owner('owner'),
  developer('developer'),
  viewer('viewer');

  const WorkspaceMemberRole(this.wireValue);

  final String wireValue;
}
