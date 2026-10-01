/// Sistema de diseño de Verbum ("Libro de horas").
///
/// Capas:
/// * tokens: paleta, tipografía, radios y espaciado (sin widgets).
/// * theme: `ThemeData` construido desde los tokens + acceso por `context`.
/// * icons: catálogo de iconos SVG Phosphor.
/// * components: widgets de presentación reutilizables, sin lógica de negocio.
library;

export 'components/v_action_bar.dart';
export 'components/v_action_tile.dart';
export 'components/v_button.dart';
export 'components/v_candle.dart';
export 'components/v_category_tile.dart';
export 'components/v_choice_tile.dart';
export 'components/v_drop_cap_text.dart';
export 'components/v_empty_state.dart';
export 'components/v_feature_card.dart';
export 'components/v_icon.dart';
export 'components/v_icon_button.dart';
export 'components/v_list_group.dart';
export 'components/v_meta_chip.dart';
export 'components/v_notice.dart';
export 'components/v_progress_bar.dart';
export 'components/v_radio_card.dart';
export 'components/v_rubric_label.dart';
export 'components/v_section_header.dart';
export 'components/v_segmented_control.dart';
export 'components/v_stat_tile.dart';
export 'components/v_step_tile.dart';
export 'components/v_surface_card.dart';
export 'components/v_tile_grid.dart';
export 'icons/verbum_icons.dart';
export 'theme/verbum_context.dart';
export 'theme/verbum_theme.dart';
export 'tokens/verbum_palette.dart';
export 'tokens/verbum_radius.dart';
export 'tokens/verbum_typography.dart';
