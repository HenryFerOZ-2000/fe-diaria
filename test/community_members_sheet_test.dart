import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/theme/app_theme.dart';
import 'package:verbum/widgets/community_members_sheet.dart';

void main() {
  const owner = CommunityMemberViewData(
    uid: 'uid-owner-private',
    displayName: 'María Elena',
    username: 'mariaelena',
    isOwner: true,
    isAdmin: true,
  );
  const admin = CommunityMemberViewData(
    uid: 'uid-admin-private',
    displayName: 'Luis Andrade',
    isAdmin: true,
    isCurrentUser: true,
  );
  const member = CommunityMemberViewData(
    uid: 'uid-member-private',
    displayName: 'Ana Torres',
    username: 'anatorres',
  );

  Widget buildPanel({
    List<CommunityMemberViewData> members = const [owner, admin, member],
    bool canManage = true,
    bool isLoading = false,
    String? errorMessage,
    ValueChanged<CommunityMemberActionSelection>? onActionSelected,
  }) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: CommunityMembersPanel(
          members: members,
          canManage: canManage,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onClose: () {},
          onActionSelected: onActionSelected,
          onOpenAdvancedManagement: canManage ? () {} : null,
        ),
      ),
    );
  }

  testWidgets('presenta la jerarquía sin exponer identificadores privados', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    expect(find.text('Personas de la comunidad'), findsOneWidget);
    expect(find.text('3 personas'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('Tú'), findsOneWidget);
    expect(find.text('@mariaelena'), findsOneWidget);
    expect(find.text('Miembro de la comunidad'), findsOneWidget);
    expect(find.text('uid-owner-private'), findsNothing);
    expect(find.text('uid-admin-private'), findsNothing);
    expect(find.text('uid-member-private'), findsNothing);
  });

  testWidgets('el propietario puede promover un miembro desde su menú', (
    tester,
  ) async {
    CommunityMemberActionSelection? selected;
    await tester.pumpWidget(
      buildPanel(onActionSelected: (value) => selected = value),
    );

    await tester.tap(
      find.byKey(const ValueKey('member-actions-uid-member-private')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hacer administrador'), findsOneWidget);

    await tester.tap(find.text('Hacer administrador'));
    await tester.pumpAndSettle();

    expect(selected?.action, CommunityMemberAction.promote);
    expect(selected?.member.uid, 'uid-member-private');
  });

  testWidgets('un miembro normal no recibe controles administrativos', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel(canManage: false));

    expect(
      find.byKey(const ValueKey('member-actions-uid-member-private')),
      findsNothing,
    );
    expect(find.text('Administración avanzada'), findsNothing);
  });

  testWidgets('representa estados de carga error y vacío con contexto', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel(isLoading: true, members: const []));
    expect(find.bySemanticsLabel('Cargando miembros'), findsOneWidget);

    await tester.pumpWidget(
      buildPanel(
        members: const [],
        errorMessage: 'No se pudieron cargar los miembros.',
      ),
    );
    await tester.pump();
    expect(find.text('No pudimos reunir a la comunidad'), findsOneWidget);

    await tester.pumpWidget(buildPanel(members: const []));
    await tester.pump();
    expect(find.text('Aún no hay miembros'), findsOneWidget);
  });

  testWidgets('se adapta a 320 px con texto al 200 por ciento', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: buildPanel(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personas de la comunidad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
