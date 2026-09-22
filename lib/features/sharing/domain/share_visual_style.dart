import 'share_content.dart';

enum ShareVisualStyle { sereneLight, contemplativeNight, livingTradition }

abstract final class ShareStyleResolver {
  static ShareVisualStyle resolve(ShareContent content) {
    if (content.mood == ShareContentMood.night) {
      return ShareVisualStyle.contemplativeNight;
    }
    if (content.mood == ShareContentMood.liturgical ||
        content.liturgicalColor != null ||
        content.kind == ShareContentKind.prayer ||
        content.kind == ShareContentKind.psalm) {
      return ShareVisualStyle.livingTradition;
    }
    return ShareVisualStyle.sereneLight;
  }
}
